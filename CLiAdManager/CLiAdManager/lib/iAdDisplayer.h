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
#import <iAd/iAd.h>


@protocol iAdDisplayer <NSObject>


- (void) showAd:(ADBannerView*)adBannerView;

// Implementation note:
// Hiding an ad that is not currently displayed should be allowed and not cause a crash!
- (void) hideAd:(ADBannerView*)adBannerView;

@end
