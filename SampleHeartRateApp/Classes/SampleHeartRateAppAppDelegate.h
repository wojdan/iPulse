//
//  SampleHeartRateAppAppDelegate.h
//  SampleHeartRateApp
//
//  Created by Chris Greening on 25/11/2010.
//  Copyright 2010 CMG Research. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SampleHeartRateAppViewController;

@interface SampleHeartRateAppAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    SampleHeartRateAppViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet SampleHeartRateAppViewController *viewController;

@end

