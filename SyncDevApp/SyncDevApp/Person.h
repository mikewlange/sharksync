//
//  Person.h
//  SyncDevApp
//
//  Created by Adrian Herridge on 20/08/2016.
//  Copyright © 2016 SharkSync. All rights reserved.
//

#import "SRKPublicObject.h"

@interface Person : SRKPublicObject

@property (strong) NSString*    name;
@property int                   age;
@property (strong) NSArray*     address;

@end
