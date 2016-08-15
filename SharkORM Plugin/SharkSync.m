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



#import "SharkSync.h"
#import "SharkORM+Private.h"
#import "SRKObject+Private.h"
#import "SRKPublicObject.h"
#import "SRKPrivateObject.h"
#import "SRKSyncChange.h"
#import "SRKDefunctObject.h"
#import "SRKSyncGroup.h"
#import "SRKSyncOptions.h"
#import <CommonCrypto/CommonDigest.h>
#import "SRKAES256Extension.h"

#ifdef TARGET_OS_IPHONE
#import <UIKit/UIImage.h>
typedef UIImage XXImage;
#else
#import <AppKit/NSImage.h>
typedef NSImage XXImage;
#endif

@interface SharkSync ()

@property (strong) NSMutableDictionary* concurrentRecordGroups;

@end

@implementation SharkSync

+ (void)startServiceWithApplicationKey:(NSString*)application_key accountKey:(NSString*)account_key {
    
    /* get the options object */
    SRKSyncOptions* options = [[[[SRKSyncOptions query] limit:1] fetch] firstObject];
    if (!options) {
        options = [SRKSyncOptions new];
        options.device_id = [[NSUUID UUID] UUIDString];
        [options commit];
    }
    
    SharkSync* sync = [SharkSync sharedObject];
    sync.applicationKey = application_key;
    sync.accountKeyKey = account_key;
    sync.deviceId = options.device_id;
    
    sync.settings = [SharkSyncSettings new];
    
    // now go and ask the delegate for the new settings to overwrite the default ones
    
}

+ (instancetype)sharedObject {
    static id this = nil;
    if (!this) {
        this = [SharkSync new];
        ((SharkSync*)this).concurrentRecordGroups = [NSMutableDictionary new];
    }
    return this;
}

+ (NSString *)MD5FromString:(NSString *)inVar {
    
    const char * pointer = [inVar UTF8String];
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(pointer, (CC_LONG)strlen(pointer), md5Buffer);
    
    NSMutableString *string = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [string appendFormat:@"%02x",md5Buffer[i]];
    
    return string;
    
}

+ (void)addVisibilityGroup:(NSString *)visibilityGroup {
    
    // adds a visibility group to the table, to be sent with all sync requests.
    // AH originally wanted the groups to be set per class, but i think it's better that a visibility group be across all classes, much good idea for the dev
    
    if (![[[[SRKSyncGroup query] whereWithFormat:@"groupName = %@", visibilityGroup] limit:1] count]) {
        SRKSyncGroup* newGroup = [SRKSyncGroup new];
        newGroup.groupName = visibilityGroup;
        newGroup.tidemark_uuid = nil;
        [newGroup commit];
    }
    
}

+ (void)removeVisibilityGroup:(NSString *)visibilityGroup {
    [[[[[SRKSyncGroup query] whereWithFormat:@"groupName = %@", visibilityGroup] limit:1] fetch] removeAll];
}

+ (NSString*)getEffectiveRecordGroup {
    @synchronized ([SharkSync sharedObject].concurrentRecordGroups) {
        return [[SharkSync sharedObject].concurrentRecordGroups objectForKey:[NSString stringWithFormat:@"%@", [NSThread currentThread]]];
    }
}

+ (void)setEffectiveRecorGroup:(NSString*)group {
    [[SharkSync sharedObject].concurrentRecordGroups setObject:group forKey:[NSString stringWithFormat:@"%@", [NSThread currentThread]]];
}

+ (void)clearEffectiveRecordGroup {
    [[SharkSync sharedObject].concurrentRecordGroups removeObjectForKey:[NSString stringWithFormat:@"%@", [NSThread currentThread]]];
}

+ (void)queueObject:(SRKObject *)object withChanges:(NSMutableDictionary*)changes withOperation:(SharkSyncOperation)operation inHashedGroup:(NSString*)group {
    
    if (operation == SharkSyncOperationCreate || operation == SharkSyncOperationSet) {
        
        /* we have an object so look at the modified fields and queue the properties that have been set */
        for (NSString* property in changes.allKeys) {
            
            // exclude the group and ID keys
            if (![property isEqualToString:@"Id"] && ![property isEqualToString:@"recordVisibilityGroup"]) {
                
                /* because all values are encrypted by the client before being sent to the server, we need to convert them into NSData,
                 to be encrypted however the developer wants, using any method */
                
                id value = [changes objectForKey:property];
                NSString* type = nil;
                
                if (value) {
                    if ([value isKindOfClass:[NSString class]]) {
                        
                        type = @"text";
                        
                        NSData* dValue = [((NSString*)value) dataUsingEncoding: NSUnicodeStringEncoding];
                       
                        // call the block in the sync settings to encrypt the data
                        SharkSync* sync = [SharkSync sharedObject];
                        SharkSyncSettings* settings = sync.settings;
                        
                        dValue = settings.encryptBlock(dValue);
                        
                        SharkSyncChange* change = [SharkSyncChange new];
                        change.path = [NSString stringWithFormat:@"%@/%@/%@", object.Id, [[object class] description], property];
                        change.action = operation;
                        change.recordGroup = group;
                        change.timestamp = @([[NSDate date] timeIntervalSince1970]);
                        NSString* b64Value = [dValue base64EncodedStringWithOptions:0];
                        change.value = [NSString stringWithFormat:@"%@/%@",type,b64Value];
                        [change commit];
                        
                    } else if ([value isKindOfClass:[NSNumber class]]) {
                        
                        type = @"number";
                        
//                        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
//                        f.numberStyle = NSNumberFormatterDecimalStyle;
//                        NSNumber *myNumber = [f numberFromString:@"242442"];
                        
                        NSData* dValue = [[NSString stringWithFormat:@"%@", value] dataUsingEncoding: NSUnicodeStringEncoding];
                        
                        // call the block in the sync settings to encrypt the data
                        SharkSync* sync = [SharkSync sharedObject];
                        SharkSyncSettings* settings = sync.settings;
                        
                        dValue = settings.encryptBlock(dValue);
                        
                        SharkSyncChange* change = [SharkSyncChange new];
                        change.path = [NSString stringWithFormat:@"%@/%@/%@", object.Id, [[object class] description], property];
                        change.action = operation;
                        change.recordGroup = group;
                        change.timestamp = @([[NSDate date] timeIntervalSince1970]);
                        NSString* b64Value = [dValue base64EncodedStringWithOptions:0];
                        change.value = [NSString stringWithFormat:@"%@/%@",type,b64Value];
                        [change commit];
                        
                    } else if ([value isKindOfClass:[NSDate class]]) {
                        
                        type = @"date";
                        
                        NSData* dValue = [[NSString stringWithFormat:@"%@", @(((NSDate*)value).timeIntervalSince1970)] dataUsingEncoding: NSUnicodeStringEncoding];
                        
                        // call the block in the sync settings to encrypt the data
                        SharkSync* sync = [SharkSync sharedObject];
                        SharkSyncSettings* settings = sync.settings;
                        
                        dValue = settings.encryptBlock(dValue);
                        
                        SharkSyncChange* change = [SharkSyncChange new];
                        change.path = [NSString stringWithFormat:@"%@/%@/%@", object.Id, [[object class] description], property];
                        change.action = operation;
                        change.recordGroup = group;
                        change.timestamp = @([[NSDate date] timeIntervalSince1970]);
                        NSString* b64Value = [dValue base64EncodedStringWithOptions:0];
                        change.value = [NSString stringWithFormat:@"%@/%@",type,b64Value];
                        [change commit];
                        
                    } else if ([value isKindOfClass:[NSData class]]) {
                        
                        type = @"bytes";
                        
                        NSData* dValue = (NSData*)value;
                        
                        // call the block in the sync settings to encrypt the data
                        SharkSync* sync = [SharkSync sharedObject];
                        SharkSyncSettings* settings = sync.settings;
                        
                        dValue = settings.encryptBlock(dValue);
                        
                        SharkSyncChange* change = [SharkSyncChange new];
                        change.path = [NSString stringWithFormat:@"%@/%@/%@", object.Id, [[object class] description], property];
                        change.action = operation;
                        change.recordGroup = group;
                        change.timestamp = @([[NSDate date] timeIntervalSince1970]);
                        NSString* b64Value = [dValue base64EncodedStringWithOptions:0];
                        change.value = [NSString stringWithFormat:@"%@/%@",type,b64Value];
                        [change commit];
                        
                    } else if ([value isKindOfClass:[XXImage class]]) {
                        
                        type = @"image";
                        
                        NSData* dValue = UIImageJPEGRepresentation(((XXImage*)value), 0.6);
                        
                        // call the block in the sync settings to encrypt the data
                        SharkSync* sync = [SharkSync sharedObject];
                        SharkSyncSettings* settings = sync.settings;
                        
                        dValue = settings.encryptBlock(dValue);
                        
                        SharkSyncChange* change = [SharkSyncChange new];
                        change.path = [NSString stringWithFormat:@"%@/%@/%@", object.Id, [[object class] description], property];
                        change.action = operation;
                        change.recordGroup = group;
                        change.timestamp = @([[NSDate date] timeIntervalSince1970]);
                        NSString* b64Value = [dValue base64EncodedStringWithOptions:0];
                        change.value = [NSString stringWithFormat:@"%@/%@",type,b64Value];
                        [change commit];
                        
                    } else if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSMutableArray class]] || [value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSMutableDictionary class]]) {
                        
                        if ([value isKindOfClass:[NSMutableDictionary class]]) {
                            type = @"mdictionary";
                        } else if ([value isKindOfClass:[NSMutableArray class]]) {
                            type = @"marray";
                        } else if ([value isKindOfClass:[NSDictionary class]]) {
                            type = @"dictionary";
                        } else if ([value isKindOfClass:[NSArray class]]) {
                            type = @"array";
                        }
                        
                        NSError* error;
                        NSData* dValue = [NSJSONSerialization dataWithJSONObject:value options:NSJSONWritingPrettyPrinted error:&error];

                        // call the block in the sync settings to encrypt the data
                        SharkSync* sync = [SharkSync sharedObject];
                        SharkSyncSettings* settings = sync.settings;
                        
                        dValue = settings.encryptBlock(dValue);
                        
                        SharkSyncChange* change = [SharkSyncChange new];
                        change.path = [NSString stringWithFormat:@"%@/%@/%@", object.Id, [[object class] description], property];
                        change.action = operation;
                        change.recordGroup = group;
                        change.timestamp = @([[NSDate date] timeIntervalSince1970]);
                        NSString* b64Value = [dValue base64EncodedStringWithOptions:0];
                        change.value = [NSString stringWithFormat:@"%@/%@",type,b64Value];
                        [change commit];
                        
                    } else if ([value isKindOfClass:[SRKObject class]]) {
                        
                        type = @"entity";
                        
                        NSData* dValue = [[NSString stringWithFormat:@"%@", ((SRKObject*)value).Id] dataUsingEncoding: NSUnicodeStringEncoding];
                        
                        // call the block in the sync settings to encrypt the data
                        SharkSync* sync = [SharkSync sharedObject];
                        SharkSyncSettings* settings = sync.settings;
                        
                        dValue = settings.encryptBlock(dValue);
                        
                        SharkSyncChange* change = [SharkSyncChange new];
                        change.path = [NSString stringWithFormat:@"%@/%@/%@", object.Id, [[object class] description], property];
                        change.action = operation;
                        change.recordGroup = group;
                        change.timestamp = @([[NSDate date] timeIntervalSince1970]);
                        NSString* b64Value = [dValue base64EncodedStringWithOptions:0];
                        change.value = [NSString stringWithFormat:@"%@/%@",type,b64Value];
                        [change commit];
                        
                    } else if ([value isKindOfClass:[NSNull class]]) {
                        
                        SharkSyncChange* change = [SharkSyncChange new];
                        change.path = [NSString stringWithFormat:@"%@/%@/%@", object.Id, [[object class] description], property];
                        change.action = operation;
                        change.recordGroup = group;
                        change.timestamp = @([[NSDate date] timeIntervalSince1970]);
                        change.value = nil;
                        [change commit];
                        
                    }
                
                }
                
            }
            
        }
    } else if (operation == SharkSyncOperationDelete) {
        
        SharkSyncChange* change = [SharkSyncChange new];
        change.path = [NSString stringWithFormat:@"%@/%@/%@", object.Id, [[object class] description], @"__delete__"];
        change.action = operation;
        change.recordGroup = group;
        change.timestamp = @([[NSDate date] timeIntervalSince1970]);
        [change commit];
        
    }
    
}

@end

@implementation SharkSyncSettings

- (instancetype)init {
    self = [super init];
    if (self) {
        
        // these are just defaults to ensure all data is encrypted, it is reccommended that you develop your own or at least set your own aes256EncryptionKey value.
        
        self.aes256EncryptionKey = [SharkSync sharedObject].applicationKey;
        self.encryptBlock = ^NSData*(NSData* dataToEncrypt) {
           
            SharkSync* sync = [SharkSync sharedObject];
            SharkSyncSettings* settings = sync.settings;
            
            return [dataToEncrypt SRKAES256EncryptWithKey:settings.aes256EncryptionKey];
            
        };
        self.decryptBlock = ^NSData*(NSData* dataToDecrypt) {
            
            SharkSync* sync = [SharkSync sharedObject];
            SharkSyncSettings* settings = sync.settings;
            
            return [dataToDecrypt SRKAES256DecryptWithKey:settings.aes256EncryptionKey];
            
        };
    }
    return self;
}

@end
