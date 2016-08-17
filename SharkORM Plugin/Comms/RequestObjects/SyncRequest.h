//
//  SyncRequest.h
//  dynamic-test
//
//  Created by Adrian Herridge on 15/08/2016.
//  Copyright © 2016 Adrian Herridge. All rights reserved.
//

#import "BaseCommsObject.h"
#import "SharkOrm.h"

@interface SyncRequest : BaseCommsObject

@property (strong) NSDictionary* groupChanges;

@end
