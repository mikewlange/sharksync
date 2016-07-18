//
//  SRKPublicObject.m
//

#import "SRKPublicObject.h"

@implementation SRKPublicObject

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
