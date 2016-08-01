//
//  SRKSyncChange.m
//

#import "SRKSyncChange.h"

@implementation SharkSyncChange

@dynamic timestamp,path,value,action,sync_op,recordGroup;

+ (SRKIndexDefinition *)indexDefinitionForEntity {
    SRKIndexDefinition* idx = [SRKIndexDefinition new];
    [idx addIndexForProperty:@"path" propertyOrder:SRKIndexSortOrderAscending];
    [idx addIndexForProperty:@"timestamp" propertyOrder:SRKIndexSortOrderAscending];
    return idx;
}

- (BOOL)entityWillInsert {
    self.timestamp = @([NSDate date].timeIntervalSince1970);
    return YES;
}

@end
