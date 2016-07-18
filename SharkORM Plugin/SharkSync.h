//
//  SRKSync.h
//

#import <Foundation/Foundation.h>
#import "SharkORM.h"

#define SHARKSYNC_DEFAULT_GROUP @"*"

typedef enum : NSUInteger {
    CREATE,     // a new object has been created
    SET,        // a value(s) have been set
    DELETE,     // object has been removed from the store
    INC,        // value has been incremented
    DEC,        // value has been decremented
} SharkSyncOperation;

@interface SharkSync : NSObject

+ (void)queueChangesFromObject:(SRKObject*)object withOperation:(SharkSyncOperation)operation;

@end


