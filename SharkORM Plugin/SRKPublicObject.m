//
//  SRKPublicObject.m
//

#import "SRKPublicObject.h"
#import "SharkSync.h"

@implementation SRKPublicObject

@dynamic recordVisibilityGroup;

- (BOOL)commit {
    return [self commitInGroup:SHARKSYNC_DEFAULT_GROUP];
}

- (BOOL)commitInGroup:(NSString*)group {
    return [super commit];
}

- (BOOL)remove {
    return [super remove];
}

@end
