
Description:

The CLiAdManager module provides a fully functional wrapper for sending iAd banners to your ViewControllers. It implements a single ADBannerView as recommended by Apple's guidelines, and sends hide/show messages to view controllers for display. 

The module works by connecting itself as the UINavigationControllerDelegate for your root navigation controller (thus receiving View Controller presented/removed messages), and sending showAd/hideAd messages to your content controllers as needed.


Example project:

The example project uses storyboards and ARC. You will find the primary documentation in the ViewController.m file.


To Install In Your Project:

Copy the files in lib/ to your project:
  CLiAdManager.h  CLiAdManager.m  iAdDisplayer.h  LICENSE

To Use in Code:

1. Create an instance of CLiAdManager (generally in AppDelegate) connected to the navigation controller that will present your content ViewControllers:

    UINavigationController* rootNavController =
         (UINavigationController*) self.window.rootViewController;
    self.adManager = [[CLiAdManager alloc]
                      initWithNavigationController: rootNavController];


2. Have your content view controllers import "iAdDisplayer.h" and adopt the protocol:
@interface ViewController : UIViewController <iAdDisplayer>

3. Implement the protocol methods in your view controllers:

- (void) showAd:(ADBannerView *)adBannerView
{
    // Ad the banner to your view
}

- (void) hideAd:(ADBannerView *)adBannerView
{
    // Remove banner from your view
}

