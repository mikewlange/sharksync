//
//  SRKSyncChange.h
//

#import "SharkORM.h"
#import "SharkSync.h"

@interface SharkSyncChange : SRKObject

@property NSString*                     path;
@property NSNumber*                     timestamp;
@property NSString*                     value;
@property SharkSyncOperation            action;
@property NSString*                     recordGroup;
@property NSString*                     sync_op;

@end
