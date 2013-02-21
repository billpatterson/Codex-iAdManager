//
//  CLiAdManager.h
//  CodexLib iAdManager
//
//  Created by 7thCodex Software (William Patterson) on 1/15/13.
//  Copyright: open source, freely usable for any purpose.
//  GitHub: FIXME
//

#import <Foundation/Foundation.h>
#import "iAdDisplayer.h"  // Protocol definition
#import <iAd/iAd.h>

/*
 
 IMPORTANT:
 
 This class functions by making itself the delegate of the provided container controller. 
 If you need to provide your own functions as delegate, DO NOT USE this class!

 */



@interface CLiAdManager : NSObject
<
    ADBannerViewDelegate,
    UINavigationControllerDelegate
>

- (id) initWithNavigationController:(UINavigationController*)controller;

- (void) shutdown;

@end
