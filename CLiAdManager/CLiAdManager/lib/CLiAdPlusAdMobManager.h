//
//  CLiAdPlusAdMobManager.h
//  CLiAdManager
//
//  Created by William Patterson on 2/22/13.
//  Copyright (c) 2013 7th Codex Software. All rights reserved.
//

#import "CLiAdManager.h"
#import "GADBannerView.h"


@interface CLiAdPlusAdMobManager : CLiAdManager <GADBannerViewDelegate>

- (id) initWithAdUnitId:(NSString*)adUnitID
     rootViewController:(UIViewController*)rootViewController;

// Normal operation is YES for this.
// Make AdMob primary and iAd the fallback by setting to NO.
@property BOOL iAdPrimaryAdMobIsFallback;

@property BOOL _debug_simulateNonfunctional_AdMob;

@end
