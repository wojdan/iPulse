/*
 Copyright (c) 2014, Bartłomiej Wojdan
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of the Bartłomiej Wojdan nor the
 names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL BARTŁOMIEJ WOJDAN BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 https://github.com/Wojdan/iPulse
 */

#import "BWManualMonitorViewController.h"
#import "BWResultsViewController.h"

@interface BWManualMonitorViewController ()

@property (weak, nonatomic) IBOutlet UILabel *beatCountLabel;
@property (weak, nonatomic) IBOutlet UIImageView *beatProgressImageView;

@property (nonatomic) NSUInteger beatsLeft;
@property (nonatomic, strong) NSMutableArray *beatTimes;
@property (nonatomic, strong) NSDate *previousBeatTime;

@end

@implementation BWManualMonitorViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
    backgroundView.image = [UIImage imageNamed:@"bg"];
    [self.view addSubview:backgroundView];
    [self.view sendSubviewToBack:backgroundView];

    [self clearButtonClicked:nil];

}

#pragma mark - IBActions

- (IBAction)backButtonClicked:(id)sender {

    [self.navigationController popViewControllerAnimated:YES];

}

- (IBAction)beatButtonClicked:(id)sender {

    if (self.beatsLeft == 0) {
        return;
    }

    self.beatsLeft--;
    self.beatProgressImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"manual_progress%d", self.beatsLeft]];
    self.beatCountLabel.text = [NSString stringWithFormat:@"%d", self.beatsLeft];

    if (self.beatsLeft == 0) {

        float mean = 0;
        for(NSNumber* pulse in self.beatTimes) {
            mean += [pulse floatValue];
        }
        mean /= self.beatTimes.count;

        [self.navigationController pushViewController:[BWResultsViewController controllerWithPulse:((NSUInteger)roundf(60/mean))] animated:YES];

        return;
    } else if (self.beatsLeft == 9){
        self.previousBeatTime = [NSDate new];
    } else {
        NSDate *now = [NSDate new];
        [self.beatTimes addObject:@([now timeIntervalSinceDate:self.previousBeatTime])];
        self.previousBeatTime = now;
    }
}

- (IBAction)clearButtonClicked:(id)sender {

    self.beatsLeft = 10;
    self.previousBeatTime = nil;
    self.beatTimes = [NSMutableArray new];
    self.beatProgressImageView.image = [UIImage imageNamed:@"manual_progress10"];

}

#pragma mark - Class methods

+ (BWManualMonitorViewController*)controller {

    return [[UIStoryboard storyboardWithName:@"ManualMonitorViewController" bundle:nil] instantiateInitialViewController];
    
}
@end
