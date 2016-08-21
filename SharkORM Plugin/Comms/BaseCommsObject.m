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

#import "BaseCommsObject.h"
#import "SharkSync.h"

@interface BaseCommsObject ()

@property int failCount;
@property (strong) NSString* method;
@property (strong) NSString* apiVersion;
@property (strong) SRKSyncNodesList* nodes;

@end

@implementation BaseCommsObject

- (void)makeRequestToMethod:(NSString *)method apiVersion:(NSString *)apiVersion toNodes:(SRKSyncNodesList *)nodes {
    
    // store the values for a retry
    self.method = method;
    self.apiVersion = apiVersion;
    self.nodes = nodes;
    
    [self generateRequest];
    
}

- (void)generateRequest {
    
    NSDictionary* requestData = [self requestObject];
    if (requestData) {
        
        STHTTPRequest *r = [STHTTPRequest requestWithURLString:[NSString stringWithFormat:@"%@/%@", self.nodes.pickNode, self.method]];
        
        NSError* error = nil;
        NSData* json = [NSJSONSerialization dataWithJSONObject:requestData options:NSJSONWritingPrettyPrinted error:&error];
        [r setRawPOSTData:json];
        [r setHTTPMethod:@"POST"];
        [r setPOSTDataEncoding:NSUTF8StringEncoding];
        [r setRequestHeaders:[NSMutableDictionary dictionaryWithDictionary:@{@"Content-Type":@"application/json"}]];
        __weak BaseCommsObject* weakSelf = self;
        
        r.completionBlock = ^(NSDictionary *headers, NSString *body) {
            
            NSError* error;
            NSDictionary* responseObject = [NSJSONSerialization JSONObjectWithData:[body dataUsingEncoding:NSASCIIStringEncoding] options:NSJSONReadingMutableContainers error:&error];
            
            if (!error) {
                [weakSelf requestResponded:responseObject];
            } else {
                // deal with this, by requesting again?  but incremement the fail count.
                _failCount++;
                [weakSelf generateRequest];
            }
            
        };
        
        r.errorBlock = ^(NSError *error) {
            
            // work out which kind of error it was, and act appropriately.  Trying again is possible.
            _failCount++;
            
            if (_failCount == 5) {
                [weakSelf requestDidError:error];
            }
            
        };
        
        [r startAsynchronous];
        
    } else {
        
        // object returned from 'requestObjectAsJSONString' was invalid
        
    }

    
}

- (void)execute {
    // overriden in implementation
}

- (void)requestResponded:(NSDictionary *)response {
    // overriden in implementation
}

- (void)requestDidError:(NSError *)NSError {
    // overriden in implementation
}

- (NSDictionary*)requestObject {
    
    // also overridden in implementaion, taking this value and merging it in
    
    self.app_id = [[SharkSync sharedObject] applicationKey];
    self.device_id = [[SharkSync sharedObject] deviceId];
    self.app_api_access_key = [[SharkSync sharedObject] accountKeyKey];
    
    return [NSMutableDictionary dictionaryWithDictionary:@{@"app_id" : self.app_id ? self.app_id : [NSNull null],
             @"app_api_access_key" : self.app_api_access_key ? self.app_api_access_key : [NSNull null],
             @"device_id" : self.device_id ? self.device_id : [NSNull null]}];
    
}

@end
