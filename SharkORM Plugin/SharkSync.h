//    MIT License
//
//    Copyright (c) 2016 SharkSync
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.



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
+ (void)startServiceWithApplicationId:(NSString*)application_key apiKey:(NSString*)account_key;
+ (void)queueObject:(SRKObject *)object withChanges:(NSMutableDictionary*)changes withOperation:(SharkSyncOperation)operation inHashedGroup:(NSString*)group;

// group management
+ (void)addVisibilityGroup:(NSString*)visibilityGroup;
+ (void)removeVisibilityGroup:(NSString*)visibilityGroup;

@end

typedef NSData*(^SharkSyncEncryptionBlock)(NSData* dataToEncrypt);
typedef NSData*(^SharkSyncDecryptionBlock)(NSData* dataToDecrypt);

@interface SharkSyncSettings : NSObject

@property (copy) SharkSyncEncryptionBlock encryptBlock;
@property (copy) SharkSyncDecryptionBlock decryptBlock;
@property (strong) NSString* aes256EncryptionKey;

@end

