//
//  AppDelegate.m
//  REST EAZE
//
//  Created by Amitanshu Jha on 12/30/14.
//  Copyright (c) 2014 Amitanshu Jha. All rights reserved.
//

#import "AppDelegate.h"
#import "FirstViewController.h"
#import "FourthViewController.h"


#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
@interface AppDelegate ()

@end


@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    // Setup Push Notifications APNs
//    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
//     (UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    //-- Set Notification
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes: (UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound) categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings]; }
    else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
         (UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    }
    
    NSDictionary *payload = [launchOptions valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (payload) {
        [self application:application didReceiveRemoteNotification:payload];
    }
    // Add the tab bar controller's current view as a subview of the window
    //self.tabBarController.view.frame = CGRectMake(0, 62, 320, 320);
//    self.window.rootViewController = self.tabBarController;
//    
//    [self.window makeKeyAndVisible];
//    
//    // setting up the header view
//    self.headerView = [[HeaderView alloc] initWithFrame:CGRectMake(0, 20, 320, 42)];
//    [self.window addSubview:self.headerView];
//    
//    // setting up facebook stuff
//    AgentSingleton *agentSingleton = [AgentSingleton sharedSingleton];
//    agentSingleton.facebook = [[Facebook alloc] initWithAppId:APP_ID];
    return YES;
}



- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    //register to receive notifications
    [application registerForRemoteNotifications];
}




- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.

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


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString* devicetoken = [[[[deviceToken description]
                               stringByReplacingOccurrencesOfString: @"<" withString: @""]
                              stringByReplacingOccurrencesOfString: @">" withString: @""]
                             stringByReplacingOccurrencesOfString: @" " withString: @""] ;
//    NSLog(@"Device_Token     -----> %@\n",deviceToken);
    [[NSUserDefaults standardUserDefaults] setObject:devicetoken forKey:@"deviceToken"];
    NSLog(@"My token is: %@", devicetoken);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"Did receive remote notification called");
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    NSLog(@"Failed to get token, error: %@", error);
}
@end
