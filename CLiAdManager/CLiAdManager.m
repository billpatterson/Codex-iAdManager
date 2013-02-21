//
//  CLiAdManager.m
//  CodexLib iAdManager
//
//  Created by 7thCodex Software (William Patterson) on 1/15/13.
//  Copyright: open source, freely usable for any purpose.
//  GitHub: FIXME
//


#import "CLiAdManager.h"


@interface CLiAdManager()

// Remember/hold the one instance of iAd view:
@property (nonatomic, strong) ADBannerView *adBannerView;

// Track the currently-up controller, so we can tell it to remove iAd when
// it goes off screen (and so we can tell it when iAd state changes to unavailable)
// Use a weak reference so that we aren't holding it in memory if it goes away.
@property (nonatomic, weak) UIViewController* lastShownViewController;

@property (nonatomic, weak) UINavigationController* controllerShowingViewsNeedingAds;

@end



@implementation CLiAdManager


- (id) initWithNavigationController:(UINavigationController*) controller
{
    self = [super init];
    if (self) {
        self.controllerShowingViewsNeedingAds = controller;
        [controller setDelegate: self];
        [self createAdBannerView];
    }
    return self;
}

- (void) shutdown
{
    self.adBannerView = nil;
    self.controllerShowingViewsNeedingAds.delegate = nil;
    self.controllerShowingViewsNeedingAds = nil;
}


#pragma mark iAd Notes

/*
 To use this, code assumes this class is the Navigation Delegate so we get informed when new
 view controllers are coming on-screen.
 
 We also assume we are the iAd banner object delegate, so we get notices about ad availabiliity.
 
 This class combines the two, by sending ad show/remove notices to the currently visible view
 controller as iAd status updates are received.
 
 Requires that the iAd framework is linked into project!
 */



#pragma mark ADBannerView setup


// Instantiate the reusable iAdBannerView and set this object as its delegate
- (void) createAdBannerView
{
    LogTrace(@"%@", @"AppDelegate: creating AdBannderView");
    // On iOS 6 ADBannerView introduces a new initializer, use it when available.
    if ([ADBannerView instancesRespondToSelector:@selector(initWithAdType:)]) {
        self.adBannerView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
    }
    else {
        self.adBannerView = [[ADBannerView alloc] init];
    }
    
    // Note: as of iOS 6, doing anything specify size of ads is deprecated, handled internally by iAd.
    //       thus, we have no configuration to do on our ad objct.
    
    self.adBannerView.delegate = self;
}



#pragma mark ADBannerView delegate calls


- (void) bannerViewWillLoadAd:(ADBannerView *)banner
{
    //LogTrace(@"%@", @"bannerViewWillLoadAd: %@", banner);
    // Do nothing. Ad has not yet loaded, is not ready for display.
    // Placeholder in case code needs to be added here in the future for some purpose.
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    //LogTrace(@"bannerViewDidLoadAd: %@", banner);
    // Ignore banner parameter. We have only one iAd object, so it has to be that one.
    
    [self _sendAdToCurrentViewController];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    // Error, or just no ad content currently available
    
    //LogTrace(@"%@", @"AppDelegate notified: AD EVENT banner error: %@", error);
    [self _sendAdToCurrentViewController];  // Will detect that ad banner not loaded and hide it
}



#pragma mark - NavigationController delegate calls


- (void) navigationController:(UINavigationController *)navigationController
        didShowViewController:(UIViewController *)viewController
                     animated:(BOOL)animated
{
    //LogTrace(@"%@", @"AppDelegate notified: did show controller: %@", viewController);
    [self _sendAdToCurrentViewController];
}

- (void) navigationController:(UINavigationController *)navigationController
       willShowViewController:(UIViewController *)viewController
                     animated:(BOOL)animated
{
    //LogTrace(@"%@", @"AppDelegate notified: will show controller: %@", viewController);
    
    // Remove adBannerView from existing presentation before trying to show it in a new one
    if (self.lastShownViewController && self.lastShownViewController != viewController) {
        [self _hideAdInViewController:self.lastShownViewController];
    }
    self.lastShownViewController = viewController;
}



#pragma mark - Send iAd To Controllers


- (void) _sendAdToCurrentViewController
{
    // Send ad to controller if valid, otherwise if current ad not valid tell controller to hide it.
    
    //LogTrace(@"%@", @"AppDelegate: _sendAdToCurrentViewController");
    if (self.lastShownViewController) {
        
        if ([self.lastShownViewController conformsToProtocol:@protocol(iAdDisplayer)]) {
            
            id<iAdDisplayer> displayController = (id<iAdDisplayer>)self.lastShownViewController;
            
            if (self.adBannerView.bannerLoaded) {
                [displayController showAd:self.adBannerView];
            }
            else {
                [displayController hideAd:self.adBannerView];
            }
        }
    }
}


- (void) _hideAdInViewController:(UIViewController*)viewController
{
    // Tell controler to hide ad (regardless of ad state)
    
    //LogTrace(@"%@", @"AppDelegate: _hideAdInViewController: %@", viewController);
    if ([viewController conformsToProtocol:@protocol(iAdDisplayer)]) {
        id<iAdDisplayer> displayController = (id<iAdDisplayer>)viewController;
        [displayController hideAd:self.adBannerView];
    }
}


@end
