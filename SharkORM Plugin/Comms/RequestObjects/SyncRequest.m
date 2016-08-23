//
//  SyncRequest.m
//  dynamic-test
//
//  Created by Adrian Herridge on 15/08/2016.
//  Copyright © 2016 Adrian Herridge. All rights reserved.
//

#import "SyncRequest.h"
#import "SRKSyncChange.h"
#import "SRKSyncGroup.h"
#import "SRKSyncOptions.h"
#import "SRKObject+Private.h"
#import "SharkORM+Private.h"
#import "SRKDefunctObject.h"
#import "SharkSync+Private.h"
#import "SRKDeferredChange.h"

@interface SRKPublicObject ()

-(BOOL)__removeRawNoSync;
-(BOOL)__commitRawWithObjectChainNoSync:(SRKObjectChain *)chain;

@end

@implementation SyncRequest

- (void)execute {
    
    self.inProgress = YES;
    
    SRKSyncNodesList* nodes = [SRKSyncNodesList new];
    [nodes addNodeWithAddress:@"http://api.sharksync.com:80" priority:1];
    
    [self makeRequestToMethod:@"sync" apiVersion:@"" toNodes:nodes];
    
    while (self.inProgress) {
        [NSThread sleepForTimeInterval:0.1];
    }
    
}

- (NSMutableDictionary *)requestObject {
    
    // get the default data from the super class
    NSMutableDictionary* requestData = [super requestObject];
    
    // now add in the changes, and the tidemarks
    NSMutableDictionary* registeredGroups = [NSMutableDictionary new];
    for (NSString* grp in [[[SRKSyncGroup query]  limit:50] distinct:@"groupName"]) {
        [registeredGroups setObject:@(1) forKey:grp];
    }
    for (NSString* grp in [[[[SharkSyncChange query] limit:50] orderBy:@"timestamp"] distinct:@"recordGroup"]) {
        [registeredGroups setObject:@(1) forKey:grp];
    }
    
    if (registeredGroups.allKeys.count > 0) {
        
        self.groupChanges = [[[[SharkSyncChange query] limit:50] orderBy:@"timestamp"] groupBy:@"recordGroup"];
        
        NSMutableArray* allGroups = [NSMutableArray new];
        
        for (NSString* groupName in registeredGroups.allKeys) {
            
            NSMutableDictionary* groupData = [NSMutableDictionary new];
            
            [groupData setObject:groupName forKey:@"group"];
            SRKSyncGroup* grp = [[[SRKSyncGroup query] whereWithFormat:@"groupName=%@", groupName] fetch].firstObject;
            
            if (grp) {
                [groupData setObject: grp.tidemark_uuid ? grp.tidemark_uuid : [NSNull null] forKey:@"tidemark"];
            }
            
            NSArray* records = [self.groupChanges objectForKey:groupName];
            NSMutableArray* changeData = [NSMutableArray new];
            if (records) {
                for (SharkSyncChange* change in records) {
                    [changeData addObject: [self dictionaryForChangeItem:change] ];
                }
            }
            
            [groupData setObject:changeData forKey:@"changes"];
            
            [allGroups addObject:groupData];
            
        }
        
        [requestData setObject:allGroups forKey:@"groups"];
        
    }
    
    return requestData;
    
}


- (void)requestResponded:(NSDictionary *)response {
    
    /* clear down the transmitted data, as we know it arrived okay */
    for (NSString* key in self.groupChanges.allKeys) {
        NSArray* records = [self.groupChanges objectForKey:key];
        for (SharkSyncChange* change in records) {
            [change remove];
        }
    }
    
    /* now work through the response */
    NSDictionary* data = [response objectForKey:@"data"];
    if (data) {
        if ([data objectForKey:@"sync_id"]) {
            SRKSyncOptions* options = [[[SRKSyncOptions query] limit:1] fetch].firstObject;
            if (!options.sync_id) {
                options.sync_id = [data objectForKey:@"sync_id"];
                [options commit];
            } else {
                if (![options.sync_id isEqualToString:[data objectForKey:@"sync_id"]]) {
                    // the sync id has changed, so we essentially, have to destroy the local data and re-sync with the server as the state is unknown.  E.g. Server data restored, corruption fixed, etc.  Not a common thing, only used in extreme scenarios.
                    
                    // clear the outbound
                    [[[SharkSyncChange query] fetchLightweight] removeAll];
                    
                    // clear all the registered classes that have ever had any data
                    
                    options.device_id = [[NSUUID UUID] UUIDString];
                    [options commit];

                    return;
                }
            }
            
        }
        
        NSArray* groups = [data objectForKey:@"groups"];
        for (NSDictionary* group in groups) {
            
            NSString* group_id = [group objectForKey:@"group"];
            NSString* timestamp = [group objectForKey:@"tidemark"];
            
            NSArray* changes = [group objectForKey:@"changes"];
            
            for (NSDictionary* change in changes) {
                
                NSString* path = [change objectForKey:@"path"];
                NSString* value = [change objectForKey:@"value"];
                NSNumber* operation = [change objectForKey:@"operation"];
                
                NSArray* components = [path componentsSeparatedByString:@"/"];
                NSString* key = [components objectAtIndex:0];
                key = [key uppercaseString];
                NSString* class = [components objectAtIndex:1];
                
                if (operation.integerValue == SharkSyncOperationDelete) {
                    
                    /* just delete the record and add an entry into the destroyed table to prevent late arrivals from breaking things */
                    
                    Class objClass = NSClassFromString(class);
                    if (objClass) {
                        SRKPublicObject* deadObject = [objClass objectWithPrimaryKeyValue:key];
                        if (deadObject) {
                            [deadObject __removeRawNoSync];
                        }
                        SRKDefunctObject* defObj = [SRKDefunctObject new];
                        defObj.defunctId = key;
                        [defObj commit];
                    }
                    
                } else {
                    
                    NSString* prop = [components objectAtIndex:2];
                    
                    Class objClass = NSClassFromString(class);
                    if (objClass) {
                        SRKPublicObject* targetObject = [objClass objectWithPrimaryKeyValue:key];
                        if (targetObject) {
                            // existing object, uopdate the value
                            id decryptedValue = [SharkSync decryptValue:value];
                            
                            // check to see if this property is actually in the class, if not, store it for a future schema
                            
                            for (NSString* fieldName in targetObject.fieldNames) {
                                if ([fieldName isEqualToString:prop]) {
                                    [targetObject setField:prop value:decryptedValue];
                                    if([targetObject __commitRawWithObjectChainNoSync:nil]) {
                                        decryptedValue = nil;
                                    }
                                }
                            }
                            
                            if (decryptedValue) {
                                
                                // cache this object for a future instance of the schema, when this field exists
                                SRKDeferredChange* deferredChange = [SRKDeferredChange new];
                                deferredChange.key = key;
                                deferredChange.className = class;
                                deferredChange.value = value;
                                deferredChange.property = prop;
                                [deferredChange commit];
                                
                            }
                            
                            
                        } else {
                            
                            if ([[[SRKDefunctObject query] whereWithFormat:@"defunctId = %@", key] count]) {
                                // defunct object, do nothing
                            } else {
                                
                                // not previously defunct, but new key found, so create an object and set the value
                                
                                SRKPublicObject* targetObject = [objClass new];
                                [targetObject setId:key];
                                
                                if (targetObject) {
                                    // existing object, uopdate the value
                                    id decryptedValue = [SharkSync decryptValue:value];
                                    
                                    // check to see if this property is actually in the class, if not, store it for a future schema
                                    
                                    for (NSString* fieldName in targetObject.fieldNames) {
                                        if ([fieldName isEqualToString:prop]) {
                                            [targetObject setField:prop value:decryptedValue];
                                            if([targetObject __commitRawWithObjectChainNoSync:nil]) {
                                                decryptedValue = nil;
                                            }
                                        }
                                    }
                                    
                                    if (decryptedValue) {
                                        
                                        // cache this object for a future instance of the schema, when this field exists
                                        SRKDeferredChange* deferredChange = [SRKDeferredChange new];
                                        deferredChange.key = key;
                                        deferredChange.className = class;
                                        deferredChange.value = value;
                                        deferredChange.property = prop;
                                        [deferredChange commit];
                                        
                                    }
                                    
                                    
                                }
                                
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
            // now update the group tidemark so as to not receive this data again
            SRKSyncGroup* grp = [SRKSyncGroup groupWithEncodedName:group_id];
            if (grp) {
                grp.tidemark_uuid = timestamp;
                [grp commit];
            }
            
        }
        
    }
    
}

- (NSDictionary*)dictionaryForChangeItem:(SharkSyncChange*)change {
    return @{
             @"path" : change.path,
             @"value" : change.value ? change.value : @" ",
             @"secondsAgo" : @([NSDate date].timeIntervalSince1970 - change.timestamp.doubleValue),
             @"operation" : @(change.action)
             };
}

@end
