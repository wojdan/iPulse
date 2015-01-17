//
//  SampleHeartRateAppViewController.h
//  SampleHeartRateApp
//
//  Created by Chris Greening on 25/11/2010.
//  Copyright 2010 CMG Research. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "SimpleChart.h"

@class SimpleChart;

@interface SampleHeartRateAppViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate, SampleChartDelegate> {
	AVCaptureSession *session;
	SimpleChart *simpleChart;
}

@property (nonatomic, retain) IBOutlet SimpleChart *simpleChart;
@property (retain, nonatomic) IBOutlet UILabel *infoLabel;

@end

