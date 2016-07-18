//
//  SRKSyncChange.m
//

#import "SRKSyncChange.h"

@implementation SharkSyncChange

@dynamic d,g,ob,p,op,t,pk;

+ (SRKIndexDefinition *)indexDefinitionForEntity {
    SRKIndexDefinition* idx = [SRKIndexDefinition new];
    [idx addIndexForProperty:@"pk" propertyOrder:SRKIndexSortOrderAscending];
    [idx addIndexForProperty:@"t" propertyOrder:SRKIndexSortOrderAscending];
    return idx;
}

- (BOOL)entityWillInsert {
    self.t = [NSDate date];
    return YES;
}

@end
