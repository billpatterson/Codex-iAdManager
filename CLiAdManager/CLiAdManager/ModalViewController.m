//
//  ModalViewController.m
//  CLiAdManager
//
//  Created by William Patterson on 2/22/13.
//  Copyright (c) 2013 7th Codex Software. All rights reserved.
//

#import "ModalViewController.h"
#import "CLiAdManager.h"
#import "AppDelegate.h"



@interface ModalViewController ()

@end

@implementation ModalViewController


// Navigation. Nothing to do with ads at all.
- (IBAction)dismissButton:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}



/*
    This view controller is shown with a modal segue.
 
    For a modal view, ad manager isn't (by definition) monitoring a root Container
    veiw that will let it know that we're appearing/disappearing.
    Thus, we need to give it the information directly.
*/

- (void) viewWillAppear:(BOOL)animated
{
    [[AppDelegate instance].adManager setOverrideTargetForAds:self];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [[AppDelegate instance].adManager removeOverrideTargetForAds];
}





/* Implement the two delegate methods */

/*
    This code is identical to the code in ViewController.m, and
    in a real project you'd put in a superclass or a category.
 
    Repeating it here for this demo makes things clearer by avoiding superclasses, etc.
*/


- (void) showAd:(UIView *)adBannerView
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


- (void) hideAd:(UIView *)adBannerView
{
    if (adBannerView.superview == self.view) {
        [adBannerView removeFromSuperview];
    }
}

@end
