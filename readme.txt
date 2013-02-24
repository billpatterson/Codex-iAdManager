
Description:

The CLiAdManager module provides a fully functional wrapper for sending iAd banners to your ViewControllers. It implements a single ADBannerView as recommended by Apple's guidelines, and sends hide/show messages to view controllers for display. 

The module works by connecting itself as the UINavigationControllerDelegate for your root navigation controller (thus receiving View Controller presented/removed messages), and sending showAd/hideAd messages to your content controllers as needed.


Example projects:

The example projects use storyboards and ARC. You will find the primary documentation in the ViewController.m file in each project.

CodexAdManager_iAd_example : example project showing the files and code needed to use *only* iAd. If you don't want both iAd and AdMob, this is the project to look at. 

CLiAdManager - The "full" version showing use of the ad manager subclass that extends to use AdMob as a fallback when iAd does not have an ad for your app. (Or vice versa - making AdMob primary, iAd the fallback.)  This project is nearly identical to the iAd example project, with some difference in instantiating the ad manager and some changes to the main view to let you experiment with AdMob "fail" states.


To Install In Your Project:

To use iAd only, copy these files in lib/ to your project:
  CLiAdManager.h  CLiAdManager.m  CLAdManagerAdDisplayer.h  LICENSE

To add the AdMob extender, add these files:
  CLiAdPlusAdMobManager.h
  CLiAdPlusAdMobManager.m


To Use in Code:

1. Create an instance of CLiAdManager (generally in AppDelegate) connected to the navigation controller that will present your content ViewControllers:

    UINavigationController* rootNavController =
         (UINavigationController*) self.window.rootViewController;
    self.adManager = [[CLiAdManager alloc]
                      initWithNavigationController: rootNavController];

Alternate: to use the "plus AdMob" version, create an instance of the AdManager subclass instead:

    UINavigationController* rootNavController = 
         (UINavigationController*) self.window.rootViewController;
    self.adManager = [[CLiAdPlusAdMobManager alloc] initWithAdUnitId:@"YOUR ID HERE"
                                                  rootViewController:rootNavController];


2. Have your content view controllers import "CLAdManagerAdDisplayer.h" and adopt the protocol:
@interface ViewController : UIViewController <CLAdManagerAdDisplayer>

3. Implement the protocol methods in your view controllers:

- (void) showAd:(UIView*)adBannerView
{
    // Make space in your view to show the ad
    // Ad the banner to your view
}

- (void) adWasRemoved
{
    // Remove space in your view allocated to the ad.
    // AdManager will have already removed ad from it's superview!
}

- (void) replaceAdWith:(UIView*)adBannerView
{
    // Ad this new ad to your view where the old one used to be
    // AdManager will have already removed the old ad from it's superview!
}


4. If you wish to permanently stop showing ads and stop the ad manager from using resources:

    [adManagerObject shutdown];


