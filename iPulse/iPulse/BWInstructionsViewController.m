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
#import "BWInstructionsViewController.h"
#import "BWCameraMonitorViewController.h"

@interface BWInstructionsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *methodNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *methodIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *instructionsLabel;

@end

@implementation BWInstructionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSParameterAssert(self.mode);

    UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
    backgroundView.image = [UIImage imageNamed:@"bg"];
    [self.view addSubview:backgroundView];
    [self.view sendSubviewToBack:backgroundView];

    [self _setupOutlets];

}

- (void)_setupOutlets {

    switch (self.mode) {
        case BWExaminationMode_Camera: {

            self.methodNameLabel.text = @"Camera & Flashlight";
            self.methodIconImageView.image = [UIImage imageNamed:@"camera_mode"];
            self.instructionsLabel.text = @"Please place your index finger on the phone in the way that both, the camera and the flashlight, are tightly covered by the fingertip. Hold your finger still and do not press the camera to hard. During the examination you should not move with your finger or phone,otherwise the results might be currupted.";

            break;
        }
        case BWExaminationMode_Microphone: {

            self.methodNameLabel.text = @"Microphone";
            self.methodIconImageView.image = [UIImage imageNamed:@"microphone_mode"];
            self.instructionsLabel.text = @"Place the iPhone on your bare chest as close to the heart as possible. The sternum surroundings give the best results. Hold your phone still, in such a way that the microphone is in a direct contact with the skin. Perform the examination in a very quite room. Try to breath gently and do not talk until the test is finished. ";
            break;
        }
        case BWExaminationMode_Manual: {

            self.methodNameLabel.text = @"Manual mode";
            self.methodIconImageView.image = [UIImage imageNamed:@"manual_mode"];
            self.instructionsLabel.text = @"Please place two fingers of the first hand on the carotid artery and hold the iPhone in the second one. Every time, when you feel a distinctive beating (under the fingers placed on the neck) tap the Beat button. You will need to register around 10 heart beats to get the examination result.";
            break;
        }

        default:
            break;
    }

}

#pragma mark - IBActions

- (IBAction)startButtonClicked:(id)sender {

    switch (self.mode) {
        case BWExaminationMode_Camera:
            [self.navigationController pushViewController:[BWCameraMonitorViewController controller] animated:YES];
            break;

        default:
            break;
    }

}

- (IBAction)backButtonClicked:(id)sender {

    [self.navigationController popViewControllerAnimated:YES];

}

#pragma mark - Class methods

+ (BWInstructionsViewController*)controllerWithMode:(BWExaminationMode)mode {

   BWInstructionsViewController *controller = [[UIStoryboard storyboardWithName:@"InstructionsViewController" bundle:nil] instantiateInitialViewController];
    controller.mode = mode;
    return controller;
    
}

@end
