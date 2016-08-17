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

@implementation SyncRequest

- (void)execute {
    
    SRKSyncNodesList* nodes = [SRKSyncNodesList new];
    [nodes addNodeWithAddress:@"http://api.sharksync.com:80" priority:5];
    
    [self makeRequestToMethod:@"sync" apiVersion:@"" toNodes:nodes];
    
}

- (NSMutableDictionary *)requestObject {
    // get the default data from the super class
    NSMutableDictionary* requestData = [super requestObject];
    
    // now add in the changes, and the tidemarks
    NSArray* registeredGroups = [[SRKSyncGroup query] distinct:@"groupName"];
    registeredGroups = [registeredGroups arrayByAddingObjectsFromArray:[[[[SharkSyncChange query] limit:50] orderBy:@"timestamp"] distinct:@"recordGroup"]];
    
    if (registeredGroups) {
        
        self.groupChanges = [[[[SharkSyncChange query] limit:50] orderBy:@"timestamp"] groupBy:@"recordGroup"];
        
        NSMutableArray* allGroups = [NSMutableArray new];
        
        for (NSString* groupName in registeredGroups) {
            
            NSMutableDictionary* groupData = [NSMutableDictionary new];
            
            [groupData setObject:groupName forKey:@"group"];
            SRKSyncGroup* grp = [[[SRKSyncGroup query] whereWithFormat:@"groupName=%@", groupName] fetch].firstObject;
            
            if (grp) {
                [groupData setObject: grp.tidemark_uuid ? grp.tidemark_uuid : @"" forKey:@"tidemark"];
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
    
    /* clear down the transmitted data */
    for (NSString* key in self.groupChanges.allKeys) {
        NSArray* records = [self.groupChanges objectForKey:key];
        for (SharkSyncChange* change in records) {
            [change remove];
        }
    }
    
}

- (NSDictionary*)dictionaryForChangeItem:(SharkSyncChange*)change {
    return @{
             @"path" : change.path,
             @"value" : change.value ? change.value : @" ",
             @"secondsAgo" : @([NSDate date].timeIntervalSince1970 - change.timestamp.doubleValue)
             };
}

@end
