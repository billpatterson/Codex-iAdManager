//
//  ViewController.m
//  CLiAdManager
//
//  Created by William Patterson on 2/22/13.
//  Copyright (c) 2013 7th Codex Software. All rights reserved.
//

#import "ViewController.h"
#import "CLiAdManager.h"
#import "AppDelegate.h"


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


- (void) showAd:(UIView *)adBannerView
{
    NSLog(@" **  Altering UI to create space for ad");
    
    // Note: ad manager will take care of having removed this ad from
    // anywhere else it was formerly displayed (including here), so we
    // don't have to worry about "replacing" an ad that's already displayed.
    
    [self _displayThisAd:adBannerView];
}


- (void) adWasRemoved
{
    NSLog(@" **  Altering UI to remove space for ad");
    // Here is where you would adjust self.view to remove blank space.
}

- (void) replaceAdWith:(UIView *)adBannerView
{
    NSLog(@" **  Reusing existing space for ad");
    
    // Like showAd, but letting us know this is a replacement for ad we've
    // already shown, not a new one, so no need to alter UI.
    [self _displayThisAd:adBannerView];
}


- (void) _displayThisAd:(UIView*)adView
{
    // Position at bottom of view
    CGRect frame = adView.frame;
    frame.origin.y = self.view.bounds.size.height - frame.size.height;
    frame.origin.x = 0;
    adView.frame = frame;
    
    // Show it
    [self.view addSubview:adView];
}


#pragma mark - Suspend/Resume

// Example to demonstrate effect of suspending CLiAdManger

- (IBAction)actionSuspendAdManager:(id)sender
{
    [[AppDelegate instance].adManager setAdDeliveryIsSuspended:YES];
}
- (IBAction)actionResumeAdManager:(id)sender
{
    [[AppDelegate instance].adManager setAdDeliveryIsSuspended:NO];
}


- (IBAction)failiAdSwitch:(UISwitch *)sender
{
    [AppDelegate instance].adManager._debug_simulateNonfunctional_iAd = sender.on;
}

@end
