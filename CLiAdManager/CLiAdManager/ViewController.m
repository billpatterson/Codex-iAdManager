//
//  ViewController.m
//  CLiAdManager
//
//  Created by William Patterson on 2/22/13.
//  Copyright (c) 2013 7th Codex Software. All rights reserved.
//

#import "ViewController.h"
#import "CLiAdManager.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // IMPORTANT: see creation of ad manager in AppDelegate.m
    // That code is an important part of this demonstration of how to use!
    
    // Also important: note that this view controller is embedded in
    // a UINavigationController. The ad manager works by using the
    // navigation controller to target ads at ViewControllers as they are
    // presented and removed.
    // The ad manager is connected to the UIViewController, and is
    // not connected to *this* view controller directly in any way!
    //
    // Turn on logging of iAd actions by settng #define LOG YES in
    // the CliAdManger.m file.
}




/* Implement the two delegate methods */

- (void) showAd:(ADBannerView *)adBannerView
{
    // Note: ad manager will take care of having sent us a "hide ad"
    // if appropriate, so we don't have to worry about "replacing" an
    // ad that's already displayed.
    
    // Position at bottom of view
    CGRect frame = adBannerView.frame;
    frame.origin.y = self.view.bounds.size.height - frame.size.height;
    frame.origin.x = 0;
    adBannerView.frame = frame;
    
    // Show it
    [self.view addSubview:adBannerView];
}


- (void) hideAd:(ADBannerView *)adBannerView
{
    if (adBannerView.superview == self.view) {
        [adBannerView removeFromSuperview];
    }
}



#pragma mark - Suspend/Resume

// Example to demonstrate effect of suspending CLiAdManger

- (IBAction)actionSuspendAdManager:(id)sender
{
    [[CLiAdManager sharedManager] setAdDeliveryIsSuspended:YES];
}
- (IBAction)actionResumeAdManager:(id)sender
{
    [[CLiAdManager sharedManager] setAdDeliveryIsSuspended:NO];
}



@end
