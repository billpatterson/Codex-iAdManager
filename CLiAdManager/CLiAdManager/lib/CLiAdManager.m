//
//  CLiAdManager.m
//  CodexLib iAdManager
//
//  Created by 7thCodex Software (William Patterson) on 1/15/13.
//  Copyright: open source, freely usable for any purpose provided you retain this header
//             and distribute license file with source.
//  GitHub: https://github.com/billpatterson/Codex-iAdManager
//
//
//  Useage: Access (and implicitly create) an instance by calling [CLiAdManager sharedManager]
//
//          Add any Container view controllers you wish the manager to monitor (automatically
//            sending ads to any content controllers the container controller manages):
//            [[CLiAdManager sharedManager] monitorNavigationController:navCtrl]
//            [[CLiAdManager sharedManager] monitorTabBarController:tabCtrl]
//
//          To remove any container controller from monitoring, tell the manger to remove it:
//            [[CLiAdManager sharedManager] stopMonitoringNavigationController:navCtrl]
//            [[CLiAdManager sharedManager] stopMonitoringTabBarController:tabCtrl]
//
//          To completely turn off the Ad Manager and stop sending of all ads:
//            [[CLiAdManager sharedManager] shutdown]
//            NOTE: there is no way to "restart" the AdManager, so only call this if you
//                  want to permanently disable action (such as in a free app that has
//                  detected ads should be removed due to an in-app purchase, for instance).
//
//          To temporarily suspend display of any ads, then turn it back on agin, call:
//            [[CLiAdManager sharedManager] suspend:YES]
//            [[CLiAdManager sharedManager] suspend:NO]
//
//          You must (of course) have the iAd framework linked into your project!
//


#import "CLiAdManager.h"


// Set to YES to enable trace logging of iAd events
#define LOG YES




@interface CLiAdManager()
{
    // We manage the "ad delivery is suspended" property using custom getters/setters, so
    // have to declare our own instance var for storage:
    BOOL _adDeliveryIsSuspended;
    
    BOOL _debugiAdTurnedOff;
}


// Remember/hold the one instance of iAd view:
@property (nonatomic, strong) ADBannerView *iAdBannerView;

// Track the currently-up controller, so we can tell it to remove iAd when
// it goes off screen (and so we can tell it when iAd state changes to unavailable)
// Use a weak reference so that we aren't holding it in memory if it goes away.
@property (nonatomic, weak) UIViewController* lastShownViewController;

@property (nonatomic, strong) NSMutableArray* containerControllersBeingMonitored;

@property (nonatomic, weak) id<iAdDisplayer> temporaryOverrideTarget;


// With subclassing, we cannot assume that the ad we sent to a target was the iAd we manage.
// Subclass may have provided some other Ad UIView, and we would have sent that.
// Thus, need a separate var to store the ad object we sent (so we can later reference it
// as part of removal).
@property (nonatomic, strong) UIView* mostRecentlySentAdObject;

@end




@implementation CLiAdManager


- (id) init
{
    self = [super init];
    if (self) {
        [self createiAdBannerView];
        self.containerControllersBeingMonitored = [NSMutableArray array];
    }
    return self;
}


- (void) shutdown
{
    for (id c in self.containerControllersBeingMonitored) {
        [c setDelegate:nil];
    }
    [self.containerControllersBeingMonitored removeAllObjects];
    self.containerControllersBeingMonitored = nil;
    self.lastShownViewController = nil;
    self.temporaryOverrideTarget = nil;
    self.mostRecentlySentAdObject = nil;
    self.iAdBannerView = nil;
}


- (void) dealloc
{
    [self shutdown];
}


- (void) setAdDeliveryIsSuspended:(BOOL)toSuspended
{
    if (toSuspended && !_adDeliveryIsSuspended) {
        // Suspend: remove any shown ad
        [self hideAdInCurrentViewController];
        _adDeliveryIsSuspended = toSuspended;
    }
    if (!toSuspended && _adDeliveryIsSuspended) {
        // Resume: show add in current controller
        _adDeliveryIsSuspended = toSuspended;
        if ([self getCurrentValidAd] != nil) {
            // Fake an ad just becoming ready to force display
            [self respondToAdReadyEvent];
        }
    }
}

- (BOOL) adDeliveryIsSuspended
{
    return _adDeliveryIsSuspended;
}


#pragma mark - Container controller monitoring


- (void) monitorNavigationController:(UINavigationController*) controller
{
    if (![self.containerControllersBeingMonitored containsObject:controller]) {
        
        [self.containerControllersBeingMonitored addObject:controller];
        [controller setDelegate: self];
        
        //self.lastShownViewController = controller.topViewController;
    }
}
- (void) stopMonitoringNavigationController:(UINavigationController*) controller
{
    if ([self.containerControllersBeingMonitored containsObject:controller]) {
        controller.delegate = nil;
        [self.containerControllersBeingMonitored removeObject:controller];
    }
}


- (void) monitorTabBarController:(UITabBarController*) controller
{
    if (![self.containerControllersBeingMonitored containsObject:controller]) {
        
        [self.containerControllersBeingMonitored addObject:controller];
        [controller setDelegate: self];
        
        //self.lastShownViewController = controller.topViewController;
    }
}
- (void) stopMonitoringTabBarController:(UITabBarController*) controller
{
    if ([self.containerControllersBeingMonitored containsObject:controller]) {
        controller.delegate = nil;
        [self.containerControllersBeingMonitored removeObject:controller];
    }
}



#pragma mark - Container controller delegate calls


/*
 Use this --OR-- the didShow version, not both.
 Just a question of where in lifecycle you want messages sent to ViewControllers
 
- (void) navigationController:(UINavigationController *)navigationController
       willShowViewController:(UIViewController *)viewController
                     animated:(BOOL)animated
{
    if (LOG) NSLog(@"CLiAdManager - notified: will show controller: %@", viewController);
    
    [self hideAdInCurrentViewController];
    self.lastShownViewController = viewController;
    [self sendAdToCurrentViewController];
}
*/


- (void) navigationController:(UINavigationController *)navigationController
        didShowViewController:(UIViewController *)viewController
                     animated:(BOOL)animated
{
    if (LOG) NSLog(@"CLiAdManager - notified: did show controller: %@", viewController);
    
    // Notify existing contrller that ad being removed
    [self hideAdInCurrentViewController];

    // Put into new controller
    self.lastShownViewController = viewController;
    [self sendAdToCurrentViewController];
}



// FIXME: known bug: if app switches to a different tab programmatically, this method is not called.
- (void) tabBarController:(UITabBarController *)tabBarController
  didSelectViewController:(UIViewController *)viewController
{
    if (LOG) NSLog(@"CLiAdManager - notified: tab bar showing controller: %@", viewController);
    
    // Notify existing contrller that ad being removed
    [self hideAdInCurrentViewController];
    
    // Put into new controller
    self.lastShownViewController = viewController;
    [self sendAdToCurrentViewController];
}



#pragma mark - "Notifications" from Modal ViewControllers


- (void) setOverrideTargetForAds:(id<iAdDisplayer>)viewController
{
    if (LOG) NSLog(@"CLiAdManager - establishing target override: %@", viewController);
    
    // Notify existing contrller that ad being removed
    [self hideAdInCurrentViewController];
    
    // Ad into new one
    self.temporaryOverrideTarget = viewController;
    [self sendAdToCurrentViewController];
}

- (void) removeOverrideTargetForAds
{
    if (LOG) NSLog(@"CLiAdManager - removing target override: %@", self.temporaryOverrideTarget);

    // Notify existing contrller that ad being removed
    [self hideAdInCurrentViewController];
    self.temporaryOverrideTarget = nil;

    // Put into old non-override target (if any)
    [self sendAdToCurrentViewController];
}




#pragma mark - Ads to/from controllers


- (void) respondToAdReadyEvent
{
    /*
    // get *best* ad to display (which may come from a subclass or be different than
    // what just became ready)
    UIView* validAd = [self getCurrentValidAd];
    if (!validAd) {
        // Shouldn't happen... *something* should be valid if we're here...
        // Respond by ignoring.
        return;
    }
    if (validAd == self.mostRecentlySentAdObject) {
        // Nothing to do. This is just another new content ready message from same ad view.
        return;
    }
     */
    NSLog(@"CLiAdManager - respondToAdReadyEvent");
    [self sendAdToCurrentViewController];
}

- (void) respondToAdErrorEventFor:(UIView*)failedAdView
{
    NSLog(@"CLiAdManager - respondToAdErrorEvent");
    
    // Something went offline. May have been us (iAd), may have been ads being
    //   downloaded by a subclass.
    // Thus, not certain whether we have a displayable ad or not, and if so whether
    //   it's an iAd or something from a subclass.

    // Do we have something valid as an alternative (possibly from subclass)?
    UIView* validAd = [self getCurrentValidAd];
    if (!validAd) {
        // No. Nothing to display.
        NSLog(@"CLiAdManager - no valid ad available");
        // Make sure to remove this now-failed item if it's being displayed:
        if (failedAdView == self.mostRecentlySentAdObject) {
            [self hideAdInCurrentViewController];
        }
        return;
    }
    else {
        // Even though something failed, still have something valid to display.
        // Trigger machinery to display valid ad (which will replace failed ad if needed)
        if (validAd != self.mostRecentlySentAdObject) {
            NSLog(@"CLiAdManager - displaying valid ad as replacement for failed ad");
            [self sendAdToCurrentViewController];
        }
        else {
            NSLog(@"CLiAdManager - already displaying valid ad, ignoring failed ad");
        }
    }
}


// If we have a valid iAdDisplayer target, send it an ad (if valid)
- (void) sendAdToCurrentViewController
{
    if (self.adDeliveryIsSuspended) {
        if (LOG) NSLog(@"CLiAdManager - ad delivery is suspended so aborting send");
        return;
    }

    // Abort if we don't have a valid ad:
    UIView* validAd = [self getCurrentValidAd];
    if (validAd ==  nil) {
        if (LOG) NSLog(@"CLiAdManager - no valid ad available so aborting send");
        return;
    }
    
    // Abort if no valid target
    id<iAdDisplayer> target = [self _currentValidAdTarget];
    if (!target) {
        if (LOG) NSLog(@"CLiAdManager - no valid target for ad so aborting send");
        return;
    }

    if (LOG) NSLog(@"CLiAdManager - _sendAdToCurrentViewController: Ad-type=%@, target=%@", NSStringFromClass([validAd class]), target);

    if (self.mostRecentlySentAdObject) {
        // There is already an ad displayed
        
        if (self.mostRecentlySentAdObject != validAd) {
            if (LOG) NSLog(@"CLiAdManager - telling target to replace old ad with new");
            [self.mostRecentlySentAdObject removeFromSuperview];
            [target replaceAdWith:validAd];
        }
        else {
            // We received another load event from currently displayed ad, so new content.
            // Same ad view object, though, so nothing to do.
            if (LOG) NSLog(@"CLiAdManager - ad to send is already displayed, ignoring");
        }
    }
    else {
        // No ad being shown. Add this one.
        if (LOG) NSLog(@"CLiAdManager - telling target to show ad");
        [target showAd:validAd];
    }
    
    self.mostRecentlySentAdObject = validAd;
}


- (void) hideAdInCurrentViewController
{
    if (self.adDeliveryIsSuspended)
        return;
    
    [self.mostRecentlySentAdObject removeFromSuperview];  // no effect if nil or not in a superview
    
    // Abort if no valid target
    id<iAdDisplayer> target = [self _currentValidAdTarget];
    if (!target) {
        if (LOG) NSLog(@"CLiAdManager - no valid target, not sending hide ad message");
        return;
    }

    [target adWasRemoved];
    self.mostRecentlySentAdObject = nil;
}



// Current valid override target
// ... or:
// currently presented view controller if that controller adopts iAdDisplayer protocol
// ... or:
//  nil
- (id<iAdDisplayer>) _currentValidAdTarget
{
    // Determine target:
    id target = self.temporaryOverrideTarget;
    if (!target) {
        target = self.lastShownViewController;
    }
    
    // If no target or target doesn't conform to protocol, nothing to do:
    if (!target || ![target conformsToProtocol:@protocol(iAdDisplayer)]) {
        return nil;
    }
    
    return target;
}



- (UIView*) getCurrentValidAd
{
    if (self._debug_simulateNonfunctional_iAd) {
        if (LOG) NSLog(@"CLiAdManager - simulating no valid iAd");
        return nil;
    }
    
    // In this class, we know only about iAd so return that:
    if (self.iAdBannerView && self.iAdBannerView.bannerLoaded) {
        if (LOG) NSLog(@"CLiAdManager - iAd ad is valid");
        return self.iAdBannerView;
    }
    if (LOG) NSLog(@"CLiAdManager - iAd ad is not valid");
    return nil;
    
    // Subclasses may add additional networks, etc, so will have to make their own decisions
    // about what counts as "the current ad"
}




#pragma mark - iAd Init, Delegate methods


// Instantiate the reusable iAdBannerView and set this object as its delegate
- (void) createiAdBannerView
{
    if (LOG) NSLog(@"CLiAdManager - icreateiAdBannerView: creating AdBannderView");
    // On iOS 6 ADBannerView introduces a new initializer, use it when available.
    if ([ADBannerView instancesRespondToSelector:@selector(initWithAdType:)]) {
        self.iAdBannerView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
    }
    else {
        self.iAdBannerView = [[ADBannerView alloc] init];
    }
    
    // Note: as of iOS 6, doing anything specify size of ads is deprecated, handled internally by iAd.
    //       thus, we have no configuration to do on our ad objct.
    
    if (LOG) NSLog(@"CLiAdManager - icreateiAdBannerView: result = %@", self.iAdBannerView);
    
    self.iAdBannerView.delegate = self;
}




- (void) bannerViewWillLoadAd:(ADBannerView *)banner
{
    if (LOG) NSLog(@"<iAd Event> :  bannerViewWillLoadAd: %@", banner);
    // Do nothing. Ad has not yet loaded, is not ready for display.
    // Placeholder in case code needs to be added here in the future for some purpose.
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    // A valid ad has been downloaded.
    // Ignore parameter. We have only one iAd object, so it has to be that one.
    if (LOG) NSLog(@"<iAd Event> :  bannerViewDidLoadAd: %@", banner);
    
    if (self._debug_simulateNonfunctional_iAd) {
        if (LOG) NSLog(@"CLiAdManager - iAd turned off, simulating error instead");
        [self bannerView:banner didFailToReceiveAdWithError:[NSError errorWithDomain:@"Simulate Fail" code:1 userInfo:nil]];
        return;
    }
    
    [self respondToAdReadyEvent];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    // Error, or just no ad content currently available
    if (LOG) NSLog(@"<iAd Event> :  didFailToReceiveAdWithError: %@", error);
    [self respondToAdErrorEventFor:banner];
}


/* For documentation purposes: it *is* possible to get "error" when nothing's actually wrong:
 
 2013-02-22 21:08:12.750 CLiAdManager[23193:c07] CLiAdManager - iAd didFailToReceiveAdWithError: Error Domain=ADErrorDomain Code=3 "The operation couldn’t be completed. Ad inventory unavailable" UserInfo=0x716b2a0 {ADInternalErrorCode=3, ADInternalErrorDomain=ADErrorDomain, NSLocalizedFailureReason=Ad inventory unavailable}
 "inventory unavailable" is a valid, connected response back from iAd Network indicating "nothing available to give you."
 The Xcode simulator is intentionally sent this message and other "unknown error" content messages in order to help developers
 test for these conditions in their code.
 
 Here, we respond by hiding the banner, then later get a valid ad, all without doing anything to the iAd object in our code:
 
 2013-02-22 21:08:12.751 CLiAdManager[23193:c07] CLiAdManager - _hideAdInViewController: <ViewController: 0x8176490>
 
 2013-02-22 21:08:42.929 CLiAdManager[23193:c07] CLiAdManager - bannerViewWillLoadAd: <ADBannerView: 0x716c620; frame = (0 0; 320 50); clipsToBounds = YES; gestureRecognizers = <NSArray: 0x817cae0>; layer = <CALayer: 0x716c390>>
 
 2013-02-22 21:08:44.348 CLiAdManager[23193:c07] CLiAdManager - bannerViewDidLoadAd: <ADBannerView: 0x716c620; frame = (0 0; 320 50); clipsToBounds = YES; gestureRecognizers = <NSArray: 0x817cae0>; layer = <CALayer: 0x716c390>>
 */




#pragma mark - DEBUG Utils


// property getter
- (BOOL) _debug_simulateNonfunctional_iAd
{
    return _debugiAdTurnedOff;
}

// property setter
- (void) set_debug_simulateNonfunctional_iAd:(BOOL)_debug_iAdTurnedOff
{
    // Turn off and trigger immediate response
    if (LOG) NSLog(@"<iAd Event> :  iAd disable: %@", _debug_iAdTurnedOff?@"YES":@"NO");
    _debugiAdTurnedOff = _debug_iAdTurnedOff;
    
    if (_debug_iAdTurnedOff) {
        // Simulate a just-received-fail message
        [self respondToAdErrorEventFor:self.iAdBannerView];
    }
    else {
        if (self.iAdBannerView && self.iAdBannerView.bannerLoaded) {
            [self respondToAdReadyEvent];
        }
        // else: no ready iAd to display so just resume waiting and processing events
    }
}



@end
