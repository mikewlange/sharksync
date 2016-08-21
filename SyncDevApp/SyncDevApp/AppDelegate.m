//
//  AppDelegate.m
//  SyncDevApp
//
//  Created by Adrian Herridge on 20/08/2016.
//  Copyright © 2016 SharkSync. All rights reserved.
//

#import "AppDelegate.h"
#import "Person.h"
#import "SyncRequest.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [SharkORM setDelegate:self];
    [SharkORM openDatabaseNamed:@"test"];
    [SharkSync startServiceWithApplicationId:@"4532bd8a-7c8d-4e37-8e36-95548f29b7eb" apiKey:@"681b8350-7f07-4953-a027-bba47e6a9d96"];
    
//    [SharkSync addVisibilityGroup:@"group_a"];
//    
//    Person* p = [Person new];
//    p.name = @"Adrian Herridge";
//    p.age = 37;
//    p.address = @[@"20 Sherwood Close", @"Liss Forest", @"Liss", @"Hampshire", @"GU33 7BT"];
//    
//    [p commitInGroup:@"group_a"];
//    
//    p.age = 38;
//    [p commitInGroup:@"group_a"];
    
    SyncRequest* re = [SyncRequest new];
    [re execute];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
