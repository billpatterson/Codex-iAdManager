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
    BOOL _adDeliveryIsSuspended;
}

// Remember/hold the one instance of iAd view:
@property (nonatomic, strong) ADBannerView *iAdBannerView;


// Track the currently-up controller, so we can tell it to remove iAd when
// it goes off screen (and so we can tell it when iAd state changes to unavailable)
// Use a weak reference so that we aren't holding it in memory if it goes away.
@property (nonatomic, weak) UIViewController* lastShownViewController;


@property (nonatomic, strong) NSMutableArray* containerControllersBeingMonitored;

@property (nonatomic, weak) id<iAdDisplayer> temporaryOverrideTarget;

@end



/*
 To use this, code assumes this class is the Navigation Delegate so we get informed when new
 view controllers are coming on-screen.
 
 We also assume we are the iAd banner object delegate, so we get notices about ad availabiliity.
 
 This class combines the two, by sending ad show/remove notices to the currently visible view
 controller as iAd status updates are received.
 
 Requires that the iAd framework is linked into project!
 */


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
    self.iAdBannerView = nil;
}


- (void) dealloc
{
    [self shutdown];
}


- (void) setAdDeliveryIsSuspended:(BOOL)toSuspended
{
    if (toSuspended && !_adDeliveryIsSuspended) {
        // Suspend: remove any shown ads
        [self hideAdInCurrentViewController];
        _adDeliveryIsSuspended = toSuspended;
    }
    if (!toSuspended && _adDeliveryIsSuspended) {
        // Resume: show add in current controller
        _adDeliveryIsSuspended = toSuspended;
        [self sendAdToCurrentViewController];
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


- (void) navigationController:(UINavigationController *)navigationController
       willShowViewController:(UIViewController *)viewController
                     animated:(BOOL)animated
{
    if (LOG) NSLog(@"CLiAdManager - notified: will show controller: %@", viewController);
    
    // Remove adBannerView from existing presentation before trying to show it in a new one
    [self hideAdInCurrentViewController];
}


- (void) navigationController:(UINavigationController *)navigationController
        didShowViewController:(UIViewController *)viewController
                     animated:(BOOL)animated
{
    if (LOG) NSLog(@"CLiAdManager - notified: did show controller: %@", viewController);
    
    self.lastShownViewController = viewController;
    [self sendAdToCurrentViewControllerIfAdIsValid];
}



// FIXME: known bug: if app switches to a different tab programmatically, this method is not called.
- (void)tabBarController:(UITabBarController *)tabBarController
 didSelectViewController:(UIViewController *)viewController
{
    if (LOG) NSLog(@"CLiAdManager - notified: tab bar showing controller: %@", viewController);
    
    // Remove adBannerView from existing presentation before trying to show it in a new one
    [self hideAdInCurrentViewController];
    self.lastShownViewController = viewController;
    [self sendAdToCurrentViewControllerIfAdIsValid];
}



#pragma mark - "Notifications" from Modal ViewControllers


- (void) setOverrideTargetForAds:(id<iAdDisplayer>)viewController
{
    if (LOG) NSLog(@"CLiAdManager - establishing target override: %@", viewController);
    self.temporaryOverrideTarget = viewController;
    [self sendAdToCurrentViewControllerIfAdIsValid];
}

- (void) removeOverrideTargetForAds
{
    if (LOG) NSLog(@"CLiAdManager - removing target override: %@", self.temporaryOverrideTarget);
    self.temporaryOverrideTarget = nil;
    [self sendAdToCurrentViewControllerIfAdIsValid];
}



#pragma mark ADBannerView setup


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



- (UIView*) getCurrentValidAd
{
    // In this class, we know only about iAd so return that:
    if (self.iAdBannerView && self.iAdBannerView.bannerLoaded) {
        return self.iAdBannerView;
    }
    return nil;
    
    // Subclasses may add additional networks, etc, so will have to make their own decisions
    // about what counts as "the current ad"
}



#pragma mark ADBannerView methods


- (void) bannerViewWillLoadAd:(ADBannerView *)banner
{
    if (LOG) NSLog(@"CLiAdManager - bannerViewWillLoadAd: %@", banner);
    // Do nothing. Ad has not yet loaded, is not ready for display.
    // Placeholder in case code needs to be added here in the future for some purpose.
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    // A valid ad has been loaded.
    // Ignore parameter. We have only one iAd object, so it has to be that one.
    if (LOG) NSLog(@"CLiAdManager - bannerViewDidLoadAd: %@", banner);
    [self sendAdToCurrentViewController];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    // Error, or just no ad content currently available
    if (LOG) NSLog(@"CLiAdManager - iAd didFailToReceiveAdWithError: %@", error);
    [self hideAdInCurrentViewController];
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




#pragma mark - Send iAd To Controllers 


// If we have a valid iAdDisplayer target, send it an ad (if valid)
- (void) sendAdToCurrentViewController
{
    if (self.adDeliveryIsSuspended)
        return;

    // Abort if we don't have a valid ad:
    UIView* validAd = [self getCurrentAd];
    if (validAd ==  nil)
        return;
        
    // Abort if no valid target
    id<iAdDisplayer> target = [self _currentValidAdTarget];
    if (!target) {
        if (LOG) NSLog(@"CLiAdManager - no valid target, not sending show ad message");
        return;
    }
    
    NSString* adType = NSStringFromClass([validAd class]);

    if (LOG) NSLog(@"CLiAdManager - _sendAdToCurrentViewController: Ad-type=%@, target=%@", adType, target);
    
    id<iAdDisplayer> displayController = (id<iAdDisplayer>)target;
    [displayController showAd:validAd];
}


- (void) hideAdInCurrentViewController
{
    if (self.adDeliveryIsSuspended)
        return;
    
    // Tell controler to hide ad (regardless of ad state)
    
    // Abort if no valid target
    id<iAdDisplayer> target = [self _currentValidAdTarget];
    if (!target) {
        if (LOG) NSLog(@"CLiAdManager - no valid target, not sending hide ad message");
        return;
    }

    UIView* ad = [self getCurrentAd];
    
    NSString* adType = NSStringFromClass([ad class]);
    
    if (LOG) NSLog(@"CLiAdManager - _hideAdInViewController: Ad-type=%@, target=%@", adType, target);
    
    id<iAdDisplayer> displayController = (id<iAdDisplayer>)target;
    [displayController hideAd:ad];

    // FIXME: with admob in the mix, do we know that [self getCurrentAd is going to return the thing that was shown? No.
    //        Going to need to create a "last presented ad" memory.
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

@end
