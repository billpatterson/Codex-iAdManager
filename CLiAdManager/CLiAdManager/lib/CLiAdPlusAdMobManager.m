//
//  CLiAdPlusAdMobManager.m
//  CLiAdManager
//
//  Created by William Patterson on 2/22/13.
//  Copyright (c) 2013 7th Codex Software. All rights reserved.
//

#import "CLiAdPlusAdMobManager.h"
#import "GADBannerView.h"


// Extension of superclass that supports Ad Mob

// Additions to linking n your project:
//   https://developers.google.com/mobile-ads-sdk/docs/#incorporating
//   Critical info: tells you about frameworks you must add, plus the following:
//     add "-ObjC" to linker flags





#define LOG YES



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


- (void) shutdown
{
    self.adMobBannerView = nil;
    [super shutdown];
}




#pragma mark ADBannerView setup


// Instantiate the reusable iAdBannerView and set this object as its delegate
- (void) createAdMobBannerViewWithRootAdUnitId:(NSString*)adUnitID
                            rootViewController:(UIViewController*)rootViewController;
{
    if (LOG) NSLog(@"CLiAdPlusAdMobManager - AdMob initializing, creating GADBannerView");

    self.adMobBannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
    self.adMobBannerView.adUnitID = adUnitID;
    self.adMobBannerView.rootViewController = rootViewController;
    
    if (LOG) NSLog(@"CLiAdPlusAdMobManager - created iAd AdBannderView: %@", self.adMobBannerView);
    
    // Don't issue request until after setting self as delegate
    self.adMobBannerView.delegate = self;
    [self.adMobBannerView loadRequest:[GADRequest request]];
}


// Override of superclass implementation.
- (UIView*) getCurrentValidAd
{
    if (self._debug_simulateNonfunctional_AdMob) {
        if (LOG) NSLog(@"CLiAdPlusAdMobManager - simulating no valid AdMob");
        return [super getCurrentValidAd];
    }
    
    if (self.iAdPrimaryAdMobIsFallback) {
        // prioritize iAd in superclass
        UIView* iAd = [super getCurrentValidAd];
        if (iAd) {
            if (LOG) NSLog(@"CLiAdPlusAdMobManager - iAd is valid and prioritized, using it");
            return iAd;
        }
        else {
            // Fallback to our AdMob object
            if (LOG) NSLog(@"CLiAdPlusAdMobManager - iAd is invalid, falling back to AdMob");
            if (self.currentAdIsValid) {
                if (LOG) NSLog(@"CLiAdPlusAdMobManager - AdMob ad is valid, using it");
                return self.adMobBannerView;
            }
            else {
                if (LOG) NSLog(@"CLiAdPlusAdMobManager - AdMob ad is not valid, no valid ad found");
                return nil;
            }
        }
    }
    else {
        // prioritize our AdMob object
        if (self.currentAdIsValid) {
            if (LOG) NSLog(@"CLiAdPlusAdMobManager - AdMob ad is valid and prioritized, using it");
            return self.adMobBannerView;
        }
        else {
            // Fallback to iAd in superclass
            if (LOG) NSLog(@"CLiAdPlusAdMobManager - AdMob ad not valid, falling back to iAd");
            return [super getCurrentValidAd];
        }
    }
}


#pragma mark GADBannerViewDelegate methods


- (void)adViewDidReceiveAd:(GADBannerView *)view
{
    if (LOG) NSLog(@"<AdMob Event> :  adViewDidReceiveAd: %@", view);
    
    if (self._debug_simulateNonfunctional_AdMob) {
        if (LOG) NSLog(@"CLiAdPlusAdMobManager - AdMob turned off, simulating error instead");
        [self adView:view didFailToReceiveAdWithError:[NSError errorWithDomain:@"Simulate Fail" code:1 userInfo:nil]];
        return;
    }

    self.currentAdIsValid = YES;
    [self respondToAdReadyEvent];
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error
{
    NSLog(@"<AdMob Event> :  didFailToReceiveAdWithError: %@", [error localizedFailureReason]);
    self.currentAdIsValid = NO;
    [self respondToAdErrorEventFor:view];
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
    if (LOG) NSLog(@"<AdMob Event> :  AdMob disable: %@", turnOff?@"YES":@"NO");
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
