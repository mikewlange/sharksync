//    MIT License
//
//    Copyright (c) 2016 SharkSync
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.



#import "SRKPrivateObject.h"
#import "SharkSync.h"
#import "SRKSyncOptions.h"
#import "SharkORM+Private.h"
#import "SharkSync+Private.h"
#import "SRKObject+Private.h"

@interface SRKPrivateObject ()

@property NSString*         recordVisibilityGroup;

@end

@implementation SRKPrivateObject

@dynamic recordVisibilityGroup;

- (BOOL)commit {
    
    /* because this is going to happen now, we need to generate a primary key now */
    if (!self.Id) {
        [self setId:[[NSUUID UUID] UUIDString]];
    }
    
    SRKSyncOptions* options = [[[[SRKSyncOptions query] limit:1] fetch] firstObject];
    return [self commitInGroup:options.device_id];
    
}

- (BOOL)commitInGroup:(NSString*)group {
    
    // hash this group
    group = [SharkSync MD5FromString:group];
    
    // have shark commit the object as normal
    NSMutableDictionary* changes = [NSMutableDictionary dictionaryWithDictionary:self.changedValues.copy];
    if (self.recordVisibilityGroup && ![self.recordVisibilityGroup isEqualToString:group]) {
        
        // group has changed, queue a delete for the old record before the commit goes through for the new
        [SharkSync queueObject:self withChanges:nil withOperation:SharkSyncOperationDelete inHashedGroup:self.recordVisibilityGroup];
        
        // create a new uuid for this record, as it has to appear to the server to be new
        [self setId:[[NSUUID UUID] UUIDString]];
        
        // now ensure that all values are written for this new record
        changes = [NSMutableDictionary dictionaryWithDictionary:self.fieldData];
        
    }
    self.recordVisibilityGroup = group;
    BOOL exists = self.exists;
    
    [SharkSync setEffectiveRecorGroup:group];
    
    if([super commit]) {
        
        [SharkSync queueObject:self withChanges:changes withOperation:exists ? SharkSyncOperationSet : SharkSyncOperationCreate inHashedGroup:group];
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
    
    // have shark commit the object as normal
    NSMutableDictionary* changes = [NSMutableDictionary dictionaryWithDictionary:self.changedValues.copy];
    if (self.recordVisibilityGroup && ![self.recordVisibilityGroup isEqualToString:group]) {
        
        // group has changed, queue a delete for the old record before the commit goes through for the new
        [SharkSync queueObject:self withChanges:nil withOperation:SharkSyncOperationDelete inHashedGroup:self.recordVisibilityGroup];
        
        // create a new uuid for this record, as it has to appear to the server to be new
        [self setId:[[NSUUID UUID] UUIDString]];
        
        // now ensure that all values are written for this new record
        changes = [NSMutableDictionary dictionaryWithDictionary:self.fieldData];
        
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
