//
//  AppDelegate.m
//  CLiAdManager
//
//  Created by William Patterson on 2/22/13.
//  Copyright (c) 2013 7th Codex Software. All rights reserved.
//

#import "AppDelegate.h"
#import "CLiAdManager.h"
#import "CLiAdPlusAdMobManager.h"


@interface AppDelegate()

@end


@implementation AppDelegate



// Convenience method for rest of app to get a reference to this object already cast to
// exact type so properties are directly accessible. 
+ (AppDelegate*)instance
{
    return (AppDelegate*) [UIApplication sharedApplication].delegate;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Ad Manager initialization:
    // Create and connect to navigation controller so it can monitor presenting and hiding of
    // content view controllers (the targets of "show ad" and "hide ad" messages manager will send).
    UINavigationController* rootNavController = (UINavigationController*) self.window.rootViewController;

//    // iAd verison:
//    self.adManager = [[CLiAdManager alloc] init];
    
    // iAd plus AdMob version
    self.adManager = [[CLiAdPlusAdMobManager alloc] initWithAdUnitId:@"a15077862002f3d"
                                                  rootViewController:rootNavController];
    
    [self.adManager monitorNavigationController:rootNavController];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // If you like, you can pause the CLiAdManager here, but it's not necessary.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // If you paused the CLiAdManager, resume here.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Right now, this call isn't necessary. But do it anyway in case later versions
    // of the ad manager library need to release resources on shutdown.
    [self.adManager shutdown];
}


@end
