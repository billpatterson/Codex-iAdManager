//
//  AppDelegate.m
//  CLiAdManager
//
//  Created by William Patterson on 2/22/13.
//  Copyright (c) 2013 7th Codex Software. All rights reserved.
//

#import "AppDelegate.h"
#import "CLiAdManager.h"


@interface AppDelegate()
@property (nonatomic, strong) CLiAdManager* adManager;
@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Ad Manager initialization:
    // Create and connect to navigation controller so it can monitor presenting and hiding of
    // content view controllers (the targets of "show ad" and "hide ad" messages manager will send).
    UINavigationController* rootNavController = (UINavigationController*) self.window.rootViewController;
    
    [[CLiAdManager sharedManager] monitorNavigationController:rootNavController];
    
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
