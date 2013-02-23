//
//  CLiAdManager.h
//  CodexLib iAdManager
//
//  Created by 7thCodex Software (William Patterson) on 1/15/13.
//  Copyright: open source, freely usable for any purpose provided you retain this header
//             and distribute license file with source.
//  GitHub: https://github.com/billpatterson/Codex-iAdManager
//

#import <Foundation/Foundation.h>
#import "iAdDisplayer.h"  // Protocol definition
#import <iAd/iAd.h>



@interface CLiAdManager : NSObject
<
    ADBannerViewDelegate,
    UINavigationControllerDelegate,
    UITabBarControllerDelegate
>


+ (CLiAdManager*) sharedManager;


// Use this toggle to temporarily suspend display of ads without shutting
// down completely (suspend = can be resumed without complications or other code)
@property BOOL adDeliveryIsSuspended;

- (void) monitorNavigationController:(UINavigationController*) controller;
- (void) monitorTabBarController:(UITabBarController*) controller;

- (void) stopMonitoringNavigationController:(UINavigationController*) controller;
- (void) stopMonitoringTabBarController:(UITabBarController*) controller;


// Make a view controller the temporary target of ads, something outside the
// normal content view controllers being monitored already.
- (void) setOverrideTargetForAds:(id<iAdDisplayer>)viewController;

// Go back to sending ads to the view controllers being monitored
- (void) removeOverrideTargetForAds;


- (void) shutdown;


@end
