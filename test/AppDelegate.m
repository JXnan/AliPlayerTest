//
//  AppDelegate.m
//  test
//
//  Created by edz on 2019/8/2.
//  Copyright © 2019 edz. All rights reserved.
//

#import "AppDelegate.h"
#import "AlivcShortVideo/AlivcShortVideoFile/VideoSolution/Control/AlivcShortVideoPlayViewController.h"
#import "Config/AlivcBaseNavigationController.h"
#import "Categories/UIImage+AlivcHelper.h"
#import <AliyunPlayer/AliyunPlayer.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [[AlivcShortVideoPlayViewController alloc] init];
    
    [AlivcImage setImageBundleName:@"AlivcShortVideoImage"];
//    UIViewController *vc_root = [[NSClassFromString(@"AlivcShortVideoQuHomeTabBarController") alloc]init];
//    AlivcBaseNavigationController *nav_root = [[AlivcBaseNavigationController alloc]initWithRootViewController:vc_root];
    NSLog(@"%@",[AliPlayer getSDKVersion]);
    
    
    //导航栏设置
//    [self setBaseNavigationBar:nav_root];
//    self.window.rootViewController = nav_root;
    [self.window makeKeyAndVisible];
    return YES;
}


/**
 导航栏设置，全局有效
 */
- (void)setBaseNavigationBar:(UINavigationController *)nav{
    //
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    [nav.navigationBar setBackgroundImage:[UIImage avc_imageWithColor:[AlivcUIConfig shared].kAVCBackgroundColor] forBarMetrics:UIBarMetricsDefault];
    [nav.navigationBar setShadowImage:[UIImage new]];
    nav.navigationBar.tintColor = [UIColor whiteColor];
    [nav.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
