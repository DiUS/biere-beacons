//
//  AppDelegate.m
//  BiereBeacons
//
//  Created by Brenton Crowley on 24/06/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import "AppDelegate.h"
#import "BadgeViewController.h"
#import "RegionDefaults.h"
#import "IneligibleDeviceViewController.h"
#import "UIColor+AppColors.h"
#import "UserActionDetailViewController.h"
#import "BeaconManager.h"
#import "GameViewController.h"
#import "BeaconManager.h"

@interface AppDelegate() <CLLocationManagerDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSDictionary *appDefaults = [NSDictionary
                         dictionaryWithObject:[NSNumber numberWithBool:YES]
                                 forKey:kFirstRun];
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    
#if DEBUG
    if (getenv("runningTests"))
        return YES;
#endif
    
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    UIViewController *rootVC = [[GameViewController alloc] init];
    
    if (![RegionDefaults isBeaconReady])
    {
        rootVC = [[IneligibleDeviceViewController alloc] init];
    }
    
    UINavigationController *navCtrl = [[UINavigationController alloc]
                                       initWithRootViewController:rootVC];
    
    [navCtrl.navigationBar setTitleTextAttributes:@{
                    NSForegroundColorAttributeName : [UIColor appPaleYellow]
                    }];
    
//    [navCtrl.navigationBar setBarTintColor: [UIColor appPaleBrown]];
//    [navCtrl.topViewController.view setBackgroundColor: [UIColor appPaleYellow]];
    self.window.rootViewController = navCtrl;
    
    // Styles
    [[UINavigationBar appearance] setBarTintColor:[UIColor appPaleBrown]];
    [[UISegmentedControl appearance] setTintColor:[UIColor appPaleBrown]];
//    [[UIBarButtonItem appearance] setTintColor:[UIColor appPaleYellow]];
    self.window.tintColor = [UIColor appPaleYellow];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 0];
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application
            didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSNotification *n = [NSNotification
                         notificationWithName:notification.alertBody
                         object:[UIApplication sharedApplication]
                         ];
    [[NSNotificationCenter defaultCenter] postNotification:n];
}

@end
