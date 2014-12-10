//
//  BWResultsViewController.m
//  iPulse
//
//  Created by Wojdan on 10.12.2014.
//  Copyright (c) 2014 wojdan. All rights reserved.
//

#import "BWResultsViewController.h"

@interface BWResultsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *pulseLabel;

@end

@implementation BWResultsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
    backgroundView.image = [UIImage imageNamed:@"bg"];
    [self.view addSubview:backgroundView];
    [self.view sendSubviewToBack:backgroundView];

    self.pulseLabel.text = [@(self.pulse) stringValue];

}

- (IBAction)backButtonClicked:(id)sender {

    [self.navigationController popToRootViewControllerAnimated:YES];
    
}

#pragma mark - Class methods

+ (BWResultsViewController*)controllerWithPulse:(NSUInteger)pulse {

    BWResultsViewController *controller = [[UIStoryboard storyboardWithName:@"ResultsViewController" bundle:nil] instantiateInitialViewController];
    controller.pulse = pulse;
    return controller;
    
}
@end
