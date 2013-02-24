//
//  AppDelegate.h
//  CLiAdManager
//
//  Created by William Patterson on 2/22/13.
//  Copyright (c) 2013 7th Codex Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CLiAdManager.h"


@interface AppDelegate : UIResponder <UIApplicationDelegate>

// Convenience method for rest of app to get a reference to this object already cast to
// exact type so properties are directly accessible.
+ (AppDelegate*)instance;


@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) CLiAdManager* adManager;

@end
