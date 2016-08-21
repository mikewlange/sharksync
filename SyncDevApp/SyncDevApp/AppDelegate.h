//
//  AppDelegate.h
//  SyncDevApp
//
//  Created by Adrian Herridge on 20/08/2016.
//  Copyright © 2016 SharkSync. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SharkORM.h"
#import "SharkSync.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, SharkSyncDelegate, SRKDelegate>

@property (strong, nonatomic) UIWindow *window;

@end

