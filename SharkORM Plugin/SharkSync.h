//
//  SRKSync.h
//

#import <Foundation/Foundation.h>
#import "SharkORM.h"
#import "SRKPrivateObject.h"
#import "SRKPublicObject.h"

#define SHARKSYNC_DEFAULT_GROUP @"__default__"

typedef enum : NSUInteger {
    SharkSyncOperationCreate,     // a new object has been created
    SharkSyncOperationSet,        // a value(s) have been set
    SharkSyncOperationDelete,     // object has been removed from the store
    SharkSyncOperationIncrement,  // value has been incremented - future implementation
    SharkSyncOperationDecrement,  // value has been decremented - future implementation
} SharkSyncOperation;

@protocol SharkSyncDelegate <NSObject>

@required

@end

@class SharkSyncSettings;

@interface SharkSync : NSObject

@property (strong) SharkSyncSettings* settings;
@property (strong) NSString* applicationKey;
@property (strong) NSString* accountKeyKey;
@property (strong) NSString* deviceId;

+ (instancetype)sharedObject;
+ (void)queueObject:(SRKObject *)object withChanges:(NSMutableDictionary*)changes withOperation:(SharkSyncOperation)operation inHashedGroup:(NSString*)group;
+ (void)startServiceWithApplicationKey:(NSString*)application_key accountKey:(NSString*)account_key;
+ (void)addVisibilityGroup:(NSString*)visibilityGroup;
+ (void)removeVisibilityGroup:(NSString*)visibilityGroup;
+ (NSString*)MD5FromString:(NSString*)inVar;
+ (NSString*)getEffectiveRecordGroup;
+ (void)setEffectiveRecorGroup:(NSString*)group;
+ (void)clearEffectiveRecordGroup;

@end

typedef NSData*(^SharkSyncEncryptionBlock)(NSData* dataToEncrypt);
typedef NSData*(^SharkSyncDecryptionBlock)(NSData* dataToDecrypt);

@interface SharkSyncSettings : NSObject

@property (copy) SharkSyncEncryptionBlock encryptBlock;
@property (copy) SharkSyncDecryptionBlock decryptBlock;
@property (strong) NSString* aes256EncryptionKey;

@end

