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

#import "BWCameraMonitorViewController.h"
#import "BWResultsViewController.h"

@interface BWCameraMonitorViewController ()

@property (weak, nonatomic) IBOutlet UILabel *pulseLabel;
@property (weak, nonatomic) IBOutlet UILabel *bpmLabel;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UIImageView *heartIcon;

@property (strong, nonatomic) NSTimer *examinationFinishTimer;
@property (strong, nonatomic) NSMutableArray *pulses;

@end

@implementation BWCameraMonitorViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
    backgroundView.image = [UIImage imageNamed:@"bg"];
    [self.view addSubview:backgroundView];
    [self.view sendSubviewToBack:backgroundView];

    self.chart.delegate = self;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(launchSession) name:UIApplicationDidBecomeActiveNotification object:nil];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self launchSession];

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [session stopRunning];
    session = nil;

    [self.examinationFinishTimer invalidate];
    self.examinationFinishTimer = nil;

}

-(void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.examinationFinishTimer invalidate];
    self.examinationFinishTimer = nil;
    
}

- (void)launchSession {
    if (session && session.isRunning) {
        [session stopRunning];
        session = nil;
        [self.pulses removeAllObjects];
    }
    session = [[AVCaptureSession alloc] init];
    self.pulses = [NSMutableArray new];

    AVCaptureDevice* camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if([camera isTorchModeSupported:AVCaptureTorchModeOn]) {
        [camera lockForConfiguration:nil];
        camera.torchMode=AVCaptureTorchModeOn;
        camera.activeVideoMinFrameDuration = CMTimeMake(1,15);
        camera.activeVideoMaxFrameDuration = CMTimeMake(1,15);
        [camera unlockForConfiguration];
    }


    NSError *error=nil;
    AVCaptureInput* cameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:camera error:&error];
    if (cameraInput == nil) {
        NSLog(@"Error to create camera capture:%@",error);
    }

    AVCaptureVideoDataOutput* videoOutput = [[AVCaptureVideoDataOutput alloc] init];

    dispatch_queue_t captureQueue=dispatch_queue_create("catpureQueue", NULL);

    [videoOutput setSampleBufferDelegate:self queue:captureQueue];

    videoOutput.videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey,
                                 nil];
    videoOutput.minFrameDuration=CMTimeMake(1, 15);
    [session setSessionPreset:AVCaptureSessionPresetLow];

    [session addInput:cameraInput];
    [session addOutput:videoOutput];
    
    [session startRunning];
}

void RGBtoHSV( float r, float g, float b, float *h, float *s, float *v ) {
    float min, max, delta;
    min = MIN( r, MIN(g, b ));
    max = MAX( r, MAX(g, b ));
    *v = max;
    delta = max - min;
    if( max != 0 )
        *s = delta / max;
    else {
        // r = g = b = 0
        *s = 0;
        *h = -1;
        return;
    }
    if( r == max )
        *h = ( g - b ) / delta;
    else if( g == max )
        *h=2+(b-r)/delta;
    else
        *h=4+(r-g)/delta;
    *h *= 60;
    if( *h < 0 )
        *h += 360;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    static int count=0;
    count++;
    CVImageBufferRef cvimgRef = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(cvimgRef,0);
    int width=CVPixelBufferGetWidth(cvimgRef);
    int height=CVPixelBufferGetHeight(cvimgRef);
    uint8_t *buf=(uint8_t *) CVPixelBufferGetBaseAddress(cvimgRef);
    size_t bprow=CVPixelBufferGetBytesPerRow(cvimgRef);
    float r=0,g=0,b=0;
    for(int y=0; y<height; y++) {
        for(int x=0; x<width*4; x+=4) {
            b+=buf[x];
            g+=buf[x+1];
            r+=buf[x+2];
        }
        buf+=bprow;
    }
    r/=255*(float) (width*height);
    g/=255*(float) (width*height);
    b/=255*(float) (width*height);

    float h,s,v;

    RGBtoHSV(r, g, b, &h, &s, &v);

    static float lastH=0;
    float highPassValue=h-lastH;
    lastH=h;
    float lastHighPassValue=0;
    float lowPassValue=(lastHighPassValue+highPassValue)/2;
    lastHighPassValue=highPassValue;
    
    dispatch_async(dispatch_get_main_queue(), ^{
    [self.chart performSelectorOnMainThread:@selector(addPoint:) withObject:[NSNumber numberWithFloat:lowPassValue] waitUntilDone:NO];
    });
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

    [session stopRunning];
    session = nil;

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

+ (BWCameraMonitorViewController*)controller {

    return [[UIStoryboard storyboardWithName:@"CameraMonitorViewController" bundle:nil] instantiateInitialViewController];

}

@end
