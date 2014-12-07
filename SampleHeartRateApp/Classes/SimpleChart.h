//
//  SimpleChart.h
//  SampleHeartRateApp
//
//  Created by Chris Greening on 25/11/2010.
//  Copyright 2010 CMG Research. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum CHART_MODE : NSInteger {

    CHART_MODE_ORIGINAL = 0,
    CHART_MODE_PROCESSED = 1

} CHART_MODE;

@protocol SampleChartDelegate <NSObject>

- (void)updateInfoLabel:(NSString*)info;

@end

@interface SimpleChart : UIView {
	NSMutableArray *points;
}

@property (nonatomic, assign) id<SampleChartDelegate> delegate;
@property (nonatomic, retain) NSMutableArray *points;
@property (nonatomic, retain) NSMutableArray *filteredPoints;
@property (nonatomic) int pointCount;
@property (nonatomic) CHART_MODE mode;


-(void) addPoint:(NSNumber *) newPoint;

@end
