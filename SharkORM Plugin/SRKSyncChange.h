//
//  SRKSyncChange.h
//

#import "SharkORM.h"
#import "SharkSync.h"

@interface SharkSyncChange : SRKObject

@property NSString*                     pk;
@property NSDate*                       t;
@property NSString*                     g;
@property SharkSyncOperation            op;
@property NSString*                     ob;
@property NSString*                     p;
@property NSString*                     d;

@end
