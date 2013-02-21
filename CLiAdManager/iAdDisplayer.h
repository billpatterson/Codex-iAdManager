//
//  iAdDisplayer.h
//  DayTimer
//
//  Created by William Patterson on 2/19/13.
//  Copyright (c) 2013 com.7thcodex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <iAd/iAd.h>


@protocol iAdDisplayer <NSObject>

- (void) showAd:(ADBannerView*)adBannerView;
- (void) hideAd:(ADBannerView*)adBannerView;

@end
