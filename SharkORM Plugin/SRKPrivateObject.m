//
//  SRKPrivateObject.m
//

#import "SRKPrivateObject.h"
#import "SharkSync.h"

@implementation SRKPrivateObject

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
