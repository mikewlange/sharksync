//
//  SRKPublicObject.h
//

#import "SharkORM.h"

@interface SRKPublicObject : SRKObject

@property NSString* Id;

- (BOOL)commitInGroup:(NSString*)group;

@end
