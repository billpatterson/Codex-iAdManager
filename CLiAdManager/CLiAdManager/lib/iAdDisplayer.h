//
//  iAdDisplayer.h
//  DayTimer
//
//  Created by William Patterson on 2/19/13.
//  Copyright (c) 2013 com.7thcodex. All rights reserved.
//
//  ViewControllers that want to receive iAds from the ad manager should
//  adopt this protocol and implement both methods.

#import <Foundation/Foundation.h>


@protocol iAdDisplayer <NSObject>


// This ad is ready for display, and should be added to a superview.
- (void) showAd:(UIView*)adBannerView;

// Notification that ad was removed from superview (most likely because
// another ViewController was presented and ad was added to another view there).
// This notification gives you an opportunity to adjust your UI accordingly.
- (void) adWasRemoved;

@end
