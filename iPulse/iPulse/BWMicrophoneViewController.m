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

#import "BWMicrophoneViewController.h"
#import "BWResultsViewController.h"
#import "Novocaine/Novocaine.h"
#import "HearBeatChart.h"

@interface BWMicrophoneViewController ()

@property (weak, nonatomic) IBOutlet UILabel *pulseLabel;
@property (weak, nonatomic) IBOutlet UILabel *bpmLabel;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UIImageView *heartIcon;

@property (strong, nonatomic) NSTimer *examinationFinishTimer;
@property (strong, nonatomic) NSMutableArray *pulses;

@end

@implementation BWMicrophoneViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
    backgroundView.image = [UIImage imageNamed:@"bg"];
    [self.view addSubview:backgroundView];
    [self.view sendSubviewToBack:backgroundView];

    self.chart.delegate = self;

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.fromValue = @(1.0f);
    animation.toValue = @(0.1f);
    animation.repeatCount = INFINITY;
    animation.duration = 0.5;
    animation.autoreverses = YES;

    [self.heartIcon.layer addAnimation:animation forKey:@"opacityAnimation"];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(launchSession) name:UIApplicationDidBecomeActiveNotification object:nil];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self launchSession];

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.examinationFinishTimer invalidate];
    self.examinationFinishTimer = nil;

    [self.audioManager pause];
    self.audioManager = nil;
}

-(void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.examinationFinishTimer invalidate];
    self.examinationFinishTimer = nil;

}

- (void)launchSession {

    [self.pulses removeAllObjects];
    self.pulses = [NSMutableArray new];
    self.audioManager = nil;
    self.audioManager = [Novocaine audioManager];

    __block float magnitude = 0.0;
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {
         vDSP_rmsqv(data, 1, &magnitude, numFrames*numChannels);
     }];

    __weak BWMicrophoneViewController * wself = self;

    __block float frequency = 100.0;
    __block float phase = 0.0;
    __weak HearBeatChart *weakChart = self.chart;
    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {

         dispatch_async(dispatch_get_main_queue(), ^{
             [weakChart addPoint:@(-magnitude*30)];
         });

         float samplingRate = wself.audioManager.samplingRate;
         for (int i=0; i < numFrames; ++i)
         {
             for (int iChannel = 0; iChannel < numChannels; ++iChannel)
             {
                 float theta = phase * M_PI * 2;
                 data[i*numChannels + iChannel] = magnitude*sin(theta);
             }
             phase += 1.0 / (samplingRate / (frequency));
             if (phase > 1.0) phase = -1;
         }
     }];

    [self.audioManager play];

}


-(void)foundHeartRate:(NSNumber *)rate {

    self.infoLabel.hidden = YES;
    self.pulseLabel.text = [rate stringValue];
    self.pulseLabel.hidden = NO;
    self.bpmLabel.hidden = NO;

    [self.pulses addObject:rate];

    [self.examinationFinishTimer invalidate];
    self.examinationFinishTimer = nil;

    if ([self.pulses count] == 4) {

        [self finishExamination];
        return;
    }

    self.examinationFinishTimer = [NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(finishExamination) userInfo:nil repeats:NO];

}

- (void)finishExamination {

    float mean = 0;
    for(NSNumber* pulse in self.pulses) {
        mean += [pulse floatValue];
    }
    mean /= self.pulses.count;

    [self.navigationController pushViewController:[BWResultsViewController controllerWithPulse:((int)round(mean))] animated:YES];
}

- (void)updateInfoLabel:(NSString *)info {

    self.infoLabel.hidden = NO;
    self.infoLabel.text = info;
    self.pulseLabel.hidden = YES;
    self.bpmLabel.hidden = YES;

}

#pragma mark - IBActions

- (IBAction)backButtonClicked:(id)sender {

    [self.navigationController popViewControllerAnimated:YES];

}

#pragma mark - Class methods

+ (BWMicrophoneViewController*)controller {
    
    return [[UIStoryboard storyboardWithName:@"MicrophoneMonitorViewController" bundle:nil] instantiateInitialViewController];
    
}

@end
