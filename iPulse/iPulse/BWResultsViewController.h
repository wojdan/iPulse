//
//  BWResultsViewController.h
//  iPulse
//
//  Created by Wojdan on 10.12.2014.
//  Copyright (c) 2014 wojdan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BWResultsViewController : UIViewController

@property (nonatomic) NSUInteger pulse;

+ (BWResultsViewController*)controllerWithPulse:(NSUInteger)pulse;

@end
