//
//  CLiAdManager.h
//  CodexLib iAdManager
//
//  Created by 7thCodex Software (William Patterson) on 1/15/13.
//  Copyright: open source, freely usable for any purpose provided you retain this header
//             and distribute license file with source.
//  GitHub: https://github.com/billpatterson/Codex-iAdManager
//

#import <Foundation/Foundation.h>
#import "iAdDisplayer.h"  // Protocol definition
#import <iAd/iAd.h>

/*
 
 IMPORTANT:
 
 This class functions by making itself the delegate of the provided UINavigationController.
 If you need to provide your own functions as delegate, DO NOT USE this class!

 */



@interface CLiAdManager : NSObject
<
    ADBannerViewDelegate,
    UINavigationControllerDelegate
>


+ (CLiAdManager*) sharedManager;


- (void) monitorNavigationController:(UINavigationController*) controller;


// Make a view controller the temporary target of ads, something outside the
// normal content view controllers being monitored already.
- (void) establishTemporaryIndependentTarget:(id<iAdDisplayer>)viewController;

// Go back to sending ads to the view controllers being monitored
- (void) removeTemporaryIndependentTarget;



- (void) shutdown;


@end
