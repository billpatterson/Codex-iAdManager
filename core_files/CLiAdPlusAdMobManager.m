//
//  CLiAdPlusAdMobManager.m
//  CLiAdManager
//
//  Created by William Patterson on 2/22/13.
//  Copyright (c) 2013 7th Codex Software. All rights reserved.
//

#import "CLiAdPlusAdMobManager.h"
#import "GADBannerView.h"


// Extension of superclass that adds simultaneous connection to AdMob for ads.
// One network or the other (iAd or AdMob) is designated as "primary" and the
// other is "fallback." Ads are displayed from the primary network whenever
// available, and from the fallback network otherwise.
//
// Designation of primary/secondary network is done with the property:
//   iAdPrimaryAdMobIsFallback  : YES = iAd primary,  NO = AdMob primary.


// Additions to linking n your project:
//   https://developers.google.com/mobile-ads-sdk/docs/#incorporating
//   Critical info: tells you about frameworks you must add, project settings to change, etc.


// Set to YES to enable trace logging of iAd events
#define LOG_AD_EVENTS YES

// Set to YES to see when we are informed about new ViewControllers being presented
#define LOG_VIEWCONTROLLERS YES

// Set to YES to see extensive logic/flow trace logging
// You'll likely want to have LOG_AD_EVENTS on to help understand causes for actions.
#define LOG_TRACE YES



@interface CLiAdPlusAdMobManager()
{
    BOOL _debugAdMobTurnedOff;
}

// Remember/hold the one instance of iAd view:
@property (nonatomic, strong) GADBannerView *adMobBannerView;

// AdMob doesn't have a way to interrogate GADBannerView for validity. Track manually.
// TODO: check current version of admob library - still true?
@property BOOL currentAdIsValid;


@end




@implementation CLiAdPlusAdMobManager



- (id) initWithAdUnitId:(NSString*)adUnitID
     rootViewController:(UIViewController*)rootViewController
{
    self = [super init];
    if (self) {
        self.iAdPrimaryAdMobIsFallback = YES;
        self.currentAdIsValid = NO;
        [self createAdMobBannerViewWithRootAdUnitId:adUnitID rootViewController:rootViewController];
    }
    return self;
}




#pragma mark ADBannerView setup


// Instantiate the reusable iAdBannerView and set this object as its delegate
- (void) createAdMobBannerViewWithRootAdUnitId:(NSString*)adUnitID
                            rootViewController:(UIViewController*)rootViewController;
{
    if (LOG_AD_EVENTS) NSLog(@"CLiAdPlusAdMobManager - AdMob initializing, creating GADBannerView");

    self.adMobBannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
    self.adMobBannerView.adUnitID = adUnitID;
    self.adMobBannerView.rootViewController = rootViewController;
    
    if (LOG_AD_EVENTS) NSLog(@"CLiAdPlusAdMobManager - created iAd AdBannderView: %@", self.adMobBannerView);
    
    // Don't issue request until after setting self as delegate
    self.adMobBannerView.delegate = self;
    [self.adMobBannerView loadRequest:[GADRequest request]];
}



#pragma mark GADBannerViewDelegate methods


- (void)adViewDidReceiveAd:(GADBannerView *)view
{
    if (LOG_AD_EVENTS) NSLog(@"<AdMob Event> :  adViewDidReceiveAd: %@", view);
    
    if (self._debug_simulateNonfunctional_AdMob) {
        if (LOG_AD_EVENTS) NSLog(@"CLiAdPlusAdMobManager - AdMob turned off, simulating error instead");
        [self adView:view didFailToReceiveAdWithError:[NSError errorWithDomain:@"Simulate Fail" code:1 userInfo:nil]];
        return;
    }

    self.currentAdIsValid = YES;
    [self respondToAdReadyEvent];
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error
{
    if (LOG_AD_EVENTS) NSLog(@"<AdMob Event> :  didFailToReceiveAdWithError: %@", [error localizedFailureReason]);
    self.currentAdIsValid = NO;
    [self respondToAdErrorEventFor:view];
}



#pragma mark - Superclass overrides


// Override of superclass implementation.
- (UIView*) getCurrentValidAd
{
    if (self._debug_simulateNonfunctional_AdMob) {
        if (LOG_AD_EVENTS) NSLog(@"CLiAdPlusAdMobManager - simulating no valid AdMob");
        return [super getCurrentValidAd];
    }
    
    if (self.iAdPrimaryAdMobIsFallback) {
        // prioritize iAd in superclass
        UIView* iAd = [super getCurrentValidAd];
        if (iAd) {
            if (LOG_TRACE) NSLog(@"CLiAdPlusAdMobManager - iAd is valid and prioritized, using it");
            return iAd;
        }
        else {
            // Fallback to our AdMob object
            if (LOG_TRACE) NSLog(@"CLiAdPlusAdMobManager - iAd is invalid, falling back to AdMob");
            if (self.currentAdIsValid) {
                if (LOG_TRACE) NSLog(@"CLiAdPlusAdMobManager - AdMob ad is valid, using it");
                return self.adMobBannerView;
            }
            else {
                if (LOG_TRACE) NSLog(@"CLiAdPlusAdMobManager - AdMob ad is not valid, no valid ad found");
                return nil;
            }
        }
    }
    else {
        // prioritize our AdMob object
        if (self.currentAdIsValid) {
            if (LOG_TRACE) NSLog(@"CLiAdPlusAdMobManager - AdMob ad is valid and prioritized, using it");
            return self.adMobBannerView;
        }
        else {
            // Fallback to iAd in superclass
            if (LOG_TRACE) NSLog(@"CLiAdPlusAdMobManager - AdMob ad not valid, falling back to iAd");
            return [super getCurrentValidAd];
        }
    }
}


- (void) shutdown
{
    self.adMobBannerView = nil;
    [super shutdown];
}



#pragma mark - DEBUG Utils


// property getter
- (BOOL) _debug_simulateNonfunctional_AdMob
{
    return _debugAdMobTurnedOff;
}

// property setter
- (void) set_debug_simulateNonfunctional_AdMob:(BOOL)turnOff
{
    // Turn off and trigger immediate response
    if (LOG_AD_EVENTS) NSLog(@"<AdMob Event> :  AdMob disable: %@", turnOff?@"YES":@"NO");
    _debugAdMobTurnedOff = turnOff;
    
    if (turnOff) {
        // Simulate a just-received-fail message
        [self respondToAdErrorEventFor:self.adMobBannerView];
    }
    else {
        if (self.adMobBannerView && self.currentAdIsValid) {
            [self respondToAdReadyEvent];
        }
        // else: no ready AdMob ad to display so just resume waiting and processing events
    }
}




@end
