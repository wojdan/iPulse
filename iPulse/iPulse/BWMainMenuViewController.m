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
#import "BWMainMenuViewController.h"
#import "BWInstructionsViewController.h"

@interface BWMainMenuViewController ()

@end

@implementation BWMainMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
    backgroundView.image = [UIImage imageNamed:@"bg"];
    [self.view addSubview:backgroundView];
    [self.view sendSubviewToBack:backgroundView];

}


#pragma mark - IBActions
- (IBAction)cameraModeSelected:(id)sender {

    BWInstructionsViewController *instructionsViewController = [BWInstructionsViewController controllerWithMode:BWExaminationMode_Camera];
    [self.navigationController pushViewController:instructionsViewController animated:YES];

}

- (IBAction)microphoneModeSelected:(id)sender {

    BWInstructionsViewController *instructionsViewController = [BWInstructionsViewController controllerWithMode:BWExaminationMode_Microphone];
    [self.navigationController pushViewController:instructionsViewController animated:YES];

}

- (IBAction)manualModeSelected:(id)sender {

    BWInstructionsViewController *instructionsViewController = [BWInstructionsViewController controllerWithMode:BWExaminationMode_Manual];
    [self.navigationController pushViewController:instructionsViewController animated:YES];

}

- (IBAction)learnMoreButtonClicked:(id)sender {

    NSURL *url = [NSURL URLWithString:@"https://github.com/Wojdan/iPulse"];
    [[UIApplication sharedApplication] openURL:url];

}
@end
