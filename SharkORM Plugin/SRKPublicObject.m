//
//  SRKPublicObject.m
//

#import "SRKPublicObject.h"
#import "SharkSync.h"
#import "SRKSyncOptions.h"
#import "SharkORM+Private.h"
#import "SRKObject+Private.h"
#import "SRKObjectChain.h"

@interface SRKPublicObject ()

@property NSString* recordVisibilityGroup;

@end

@implementation SRKPublicObject

@dynamic recordVisibilityGroup;

- (BOOL)commit {
    
    /* because this is going to happen now, we need to generate a primary key now */
    if (!self.Id) {
        [self setId:[[NSUUID UUID] UUIDString]];
    }
    
    return [self commitInGroup:SHARKSYNC_DEFAULT_GROUP];
    
}

- (BOOL)commitInGroup:(NSString*)group {
    
    // hash this group
    group = [SharkSync MD5FromString:group];
    [SharkSync setEffectiveRecorGroup:group];
    
    if([super commit]) {
        
        [SharkSync clearEffectiveRecordGroup];
        return YES;
        
    }
    [SharkSync clearEffectiveRecordGroup];
    return NO;
    
}

- (BOOL)remove {
    
    [SharkSync setEffectiveRecorGroup:self.recordVisibilityGroup];
    if ([super remove]) {
        [SharkSync queueObject:self withChanges:nil withOperation:SharkSyncOperationDelete inHashedGroup:self.recordVisibilityGroup];
        [SharkSync clearEffectiveRecordGroup];
        return YES;
    }
    [SharkSync clearEffectiveRecordGroup];
    return NO;
    
}

- (BOOL)__commitRawWithObjectChain:(SRKObjectChain *)chain {
    
    // hash this group
    NSString* group = [SharkSync getEffectiveRecordGroup];
    
    // pull out all the change sthat have been made, by the dirtyField flags
    NSMutableDictionary* changes = [NSMutableDictionary new];
    NSMutableDictionary* combinedChanges = self.entityContentsAsObjects;
    for (NSString* dirtyField in [self dirtyFields]) {
        [changes setObject:[combinedChanges objectForKey:dirtyField] forKey:dirtyField];
    }
        
    if (self.recordVisibilityGroup && ![self.recordVisibilityGroup isEqualToString:group]) {
        
        // group has changed, queue a delete for the old record before the commit goes through for the new
        [SharkSync queueObject:self withChanges:nil withOperation:SharkSyncOperationDelete inHashedGroup:self.recordVisibilityGroup];
        
        // generate the new UUID
        NSString* newUUID = [[NSUUID UUID] UUIDString];
        
        // create a new uuid for this record, as it has to appear to the server to be new
        [[SharkORM new] replaceUUIDPrimaryKey:self withNewUUIDKey:newUUID];
        
        // if there are any embedded objects, then they will have their record group potentially changed too & and a new UUID
        
        NSMutableArray* updatedEmbeddedObjects = [NSMutableArray new];
        
        for (SRKPublicObject* o in self.embeddedEntities.allValues) {
            if ([o isKindOfClass:[SRKPublicObject class]]) {
                // check to see if this object has already appeard in this chain.
                if (![chain doesObjectExistInChain:o]) {
                    // now check to see if this is a different record group, if so replace it and regen the UDID
                    if (o.recordVisibilityGroup && ![o.recordVisibilityGroup isEqualToString:group]) {
                        // group has changed, queue a delete for the old record before the commit goes through for the new
                        [SharkSync queueObject:o withChanges:nil withOperation:SharkSyncOperationDelete inHashedGroup:o.recordVisibilityGroup];
                        // generate the new UUID
                        NSString* newUUID = [[NSUUID UUID] UUIDString];
                        // create a new uuid for this record, as it has to appear to the server to be new
                        [[SharkORM new] replaceUUIDPrimaryKey:o withNewUUIDKey:newUUID];
                        o.recordVisibilityGroup = group;
                        
                        // now we have to flag all fields as dirty, because they need to have their values written to the upstream table
                        for (NSString* field in o.fieldNames) {
                            [o.dirtyFields setObject:@(1) forKey:field];
                        }
                        
                        // add object to the list of changes
                        [updatedEmbeddedObjects addObject:o];
                        [o __commitRawWithObjectChain:chain];
                    }
                }
            }
        }
        
        for (SRKRelationship* r in [SharkORM entityRelationships]) {
            if ([[r.sourceClass description] isEqualToString:[self.class description]] && r.relationshipType == SRK_RELATE_ONETOONE) {
                
                /* this is a link field that needs to be updated */
                
                SRKPublicObject* e = [self.embeddedEntities objectForKey:r.entityPropertyName];
                if(e && [e isKindOfClass:[SRKPublicObject class]]) {
                    if ([updatedEmbeddedObjects containsObject:e]) {
                        [self setField:[NSString stringWithFormat:@"%@",r.entityPropertyName] value:((SRKPublicObject*)e).Id];
                    }
                }
                
            }
        }
        
        // now ensure that all values are written for this new record
        NSMutableDictionary* entityValues = [NSMutableDictionary new];
        for (NSString* field in self.fieldNames) {
            id value = [self getField:field];
            [entityValues setObject:value ? value : [NSNull null] forKey:field];
        }
        
        changes = self.entityContentsAsObjects;
        
    }
    
    self.recordVisibilityGroup = group;
    BOOL exists = self.exists;
    if([super __commitRawWithObjectChain:chain]) {
        
        [SharkSync queueObject:self withChanges:changes withOperation:exists ? SharkSyncOperationSet : SharkSyncOperationCreate inHashedGroup:group];
        return YES;
        
    }
    
    return NO;
    
}

- (BOOL)__removeRaw {
    
    if ([super __removeRaw]) {
        [SharkSync queueObject:self withChanges:nil withOperation:SharkSyncOperationDelete inHashedGroup:[SharkSync getEffectiveRecordGroup]];
        return YES;
    }
    
    return NO;
    
}

@end
