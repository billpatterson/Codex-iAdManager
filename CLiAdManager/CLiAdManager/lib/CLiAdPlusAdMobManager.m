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

}

// Remember/hold the one instance of iAd view:
@property (nonatomic, strong) GADBannerView *adMobBannerView;

// AdMob doesn't have a way to interrogate GADBannerView for validity. Track manually.
// TODO: check current version of admob library - still true?
@property BOOL currentAdIsValid;


@end




@implementation CLiAdPlusAdMobManager



// FIXME: need to get rid of SharedInstance stuff since this has to have a root view controller.

- (id) initWithAdUnitId:(NSString*)adUnitID
     rootViewController:(UIViewController*)rootViewController
{
    self = [super init];
    if (self) {
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


- (UIView*) getCurrentAd
{
    if (self.currentAdIsValid) {
        if (LOG) NSLog(@"CLiAdPlusAdMobManager - current ad not valid, punting to iAd");
        return self.adMobBannerView;
    }
    else {
        if (LOG) NSLog(@"CLiAdPlusAdMobManager - current ad is valid, using it");
        return [super getCurrentAd];
    }
}



#pragma mark GADBannerViewDelegate methods


- (void)adViewDidReceiveAd:(GADBannerView *)view
{
    if (LOG) NSLog(@"CLiAdPlusAdMobManager - received AdMob ad");
    self.currentAdIsValid = YES;
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error
{
    NSLog(@"CLiAdPlusAdMobManager - Failed to receive AdMob with error: %@", [error localizedFailureReason]);
    self.currentAdIsValid = NO;
}


/* #DEBUG ONLY
- (void)adViewWillPresentScreen:(GADBannerView *)bannerView
{
     NSLog(@"will Present");
}
*/



// FIXME: override of superclass method that's just dropped here with little planning.
//        Need to figure out how to handle this. 
- (void) sendAdToCurrentViewControllerIfAdIsValid
{
    if (self.currentAdIsValid) {
        if (LOG) NSLog(@"CLiAdPlusAdMobManager - sending valid AdMob ad");
        [self sendAdToCurrentViewController];
    }
    else {
        if (LOG) NSLog(@"CLiAdPlusAdMobManager - current AdMob ad not valid, punting to iAd in superclass");
        [super sendAdToCurrentViewController];
    }
    
}


@end
