//
//  CLAdManagerAdDisplayer.h
//
//  CodexLib iAdManager
//
//  Created by 7thCodex Software (William Patterson) on 1/15/13.
//  Copyright: open source, freely usable for any purpose provided you retain this header
//             and distribute license file with source.
//  GitHub: https://github.com/billpatterson/Codex-iAdManager
//
//  ViewControllers that want to receive iAds from the ad manager should
//  adopt this protocol and implement all methods.

#import <Foundation/Foundation.h>


@protocol CLAdManagerAdDisplayer <NSObject>


// This ad is ready for display, and should be added to a superview.
- (void) showAd:(UIView*)adBannerView;

// Notification that ad was removed from superview (most likely because
// another ViewController was presented and ad was added to another view there).
// This notification gives you an opportunity to adjust your UI accordingly.
- (void) adWasRemoved;

- (void) replaceAdWith:(UIView*)adBannerView;

@end
