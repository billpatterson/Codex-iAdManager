//
//  CLiAdManager.h
//  CodexLib iAdManager
//
//  Created by 7thCodex Software (William Patterson) on 1/15/13.
//  Copyright: open source, freely usable for any purpose provided you retain this header
//             and distribute license file with source.
//  GitHub: https://github.com/billpatterson/Codex-iAdManager
//

#import "CLAdManagerAdDisplayer.h"  // Protocol definition adopted by ad targets
#import <iAd/iAd.h>


@interface CLiAdManager : NSObject
<
    ADBannerViewDelegate,
    UINavigationControllerDelegate,
    UITabBarControllerDelegate
>


// Use normal [... init] to initialize.


// Use this toggle to temporarily suspend display of ads without shutting
// down completely (suspend = can be resumed without complications or other code)
@property BOOL adDeliveryIsSuspended;

@property BOOL _debug_simulateNonfunctional_iAd;


- (void) monitorNavigationController:(UINavigationController*) controller;
- (void) monitorTabBarController:(UITabBarController*) controller;

- (void) stopMonitoringNavigationController:(UINavigationController*) controller;
- (void) stopMonitoringTabBarController:(UITabBarController*) controller;


// Make a view controller the temporary target of ads, something outside the
// normal content view controllers being monitored already.
- (void) setOverrideTargetForAds:(id<CLAdManagerAdDisplayer>)viewController;

// Go back to sending ads to the view controllers being monitored
- (void) removeOverrideTargetForAds;


// Subclasses should extend this method with additions and call [super shutdown]:
- (void) shutdown;



// Subclasses should *replace* this method with their own implementation
// (subclasses can call [super getCurrentAd] to get current iAd)
- (UIView*) getCurrentValidAd;

// Subclasses can call these to trigger responses to events for their ad types.
- (void) respondToAdReadyEvent;
- (void) respondToAdErrorEventFor:(UIView*)failedAdView;

@end
