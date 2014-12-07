//
//  SimpleChart.m
//  SampleHeartRateApp
//
//  Created by Chris Greening on 25/11/2010.
//  Copyright 2010 CMG Research. All rights reserved.
//

#import "SimpleChart.h"

#define FPS 15

@implementation SimpleChart

@synthesize points;

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {

    self = [super initWithCoder:aDecoder];
    self.pointCount = 0;
    return self;

}

- (void)drawRect:(CGRect)rect {
    [self drawOriginalSignal];
    [self drawFilteredSignal];

}

- (void)drawOriginalSignal {
    if(points.count==0) return;
    // Drawing code.
    CGContextRef context=UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
    CGContextSetLineWidth(context, 1);
    CGContextBeginPath(context);
    float xpos=self.bounds.size.width;
    float ypos=[[points objectAtIndex:0] floatValue];

    CGContextMoveToPoint(context, xpos, ypos);
    for(int i=1; i<points.count; i++) {
        xpos-=2;
        float ypos=[[points objectAtIndex:i] floatValue];
        if(isnan(ypos) || ABS(ypos) > 2) {
            continue;
        }
        CGContextAddLineToPoint(context, xpos, self.bounds.size.height/4+ypos*self.bounds.size.height/6);
    }
    CGContextStrokePath(context);
}

- (void)drawFilteredSignal {
    if(self.filteredPoints.count==0) return;
    // Drawing code.
    CGContextRef context=UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
    CGContextSetLineWidth(context, 1);
    CGContextBeginPath(context);
    float xpos=self.bounds.size.width;
    float ypos=[[self.filteredPoints objectAtIndex:0] floatValue];

    CGContextMoveToPoint(context, xpos, ypos);
    for(int i=1; i<self.filteredPoints.count; i++) {
        xpos-=2;
        float ypos=[[self.filteredPoints objectAtIndex:i] floatValue];
        if(isnan(ypos) || ABS(ypos) > 2) {
            continue;
        }
        CGContextAddLineToPoint(context, xpos, 3*self.bounds.size.height/4-ypos*self.bounds.size.height/6);
    }
    CGContextStrokePath(context);
}

-(void) addPoint:(NSNumber *) newPoint {
	if(!points) points=[[NSMutableArray alloc] init];
	[points insertObject:newPoint atIndex:0];
	while(points.count>FPS * 12) {
		[points removeLastObject];
	}

    self.pointCount++;
    if (self.pointCount == 60) {
        [self runFindingPulsAlgorithmWithCompletionHandler:^(BOOL success, float pulse) {

            [self.delegate updateInfoLabel:@"Algorithm re-runned"];
            
        }];
        self.pointCount = 0;
    }


//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSString *documentTXTPath = [documentsDirectory stringByAppendingPathComponent:@"data"];
//    NSString *savedString = [NSString stringWithFormat:@"\n%f", [newPoint floatValue]];
//
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    if(![fileManager fileExistsAtPath:documentTXTPath])
//    {
//        [savedString writeToFile:documentTXTPath atomically:YES];
//    }
//    else
//    {
//        NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:documentTXTPath];
//        [myHandle seekToEndOfFile];
//        [myHandle writeData:[savedString dataUsingEncoding:NSUTF8StringEncoding]];
//    }
	[self setNeedsDisplay];
}

- (void)runFindingPulsAlgorithmWithCompletionHandler:(void (^)(BOOL success, float pulse))handler {

    NSMutableArray *signal = [self.points mutableCopy];
    if ([signal count] < FPS * 5) {
        [self.delegate updateInfoLabel:@"Badanie rozpocznie się po 5 sekundach pomiaru"];
        return;
    }

    [self deleteNanSamplesInSignal:signal];
    [self smoothSignal:signal];
    [self meanSignal:signal toValue:2 withStep:50];
    [self runQualityFilterOnSignal:signal];
    [self searchPeaksInSignal:signal numberOfPeaksToFind:10 completionHandel:^(BOOL success, float pulse) {

        if (success) {
            [self.delegate updateInfoLabel:[NSString stringWithFormat:@"Heart rate: %f (BPM)", pulse]];
        }
        self.filteredPoints = signal;

    }];



}

- (void)deleteNanSamplesInSignal:(NSMutableArray*)signal {
    for (int i = 0; i < [signal count]; i++) {
        float s  = [signal[i] floatValue];
        if (isnan(s)) {
            if (i == 0) {
                signal[i] = @(0);
            } else {
                signal[i] = @([signal[i-1] floatValue]);
            }
        }
        signal[i] = @(-[signal[i] floatValue]);
    }
}

- (void)smoothSignal:(NSMutableArray*)signal {

    NSMutableArray *sCopy = [[NSMutableArray alloc] initWithArray:signal];
    for (int i = 2; i < [signal count] - 2; i++) {
        signal[i] = @( ([sCopy[i-2] floatValue] + 2*[sCopy[i-1] floatValue] + 3*[sCopy[i] floatValue] + 2*[sCopy[i+1] floatValue] + [sCopy[i+2] floatValue])/9.f);
    }
}

- (void)meanSignal:(NSMutableArray*)signal toValue:(float)meanValue withStep:(NSInteger)step {

    NSMutableArray *meanSignal = [NSMutableArray new];
    for (int i = 0; i <= [signal count] - step; i += step) {

        NSMutableArray *stepArray = [[NSMutableArray alloc] initWithArray:[signal objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(i, step)]]];

        float maxValue = -MAXFLOAT;
        for (NSNumber *value in stepArray) {
            if ([value floatValue] > maxValue) {
                maxValue = [value floatValue];
            }
        }

        float ratio = meanValue / maxValue;
        for (int j = 0; j < [stepArray count]; j++) {
            stepArray[j] = @(ratio * [stepArray[j] floatValue]);
        }

        [meanSignal addObjectsFromArray:stepArray];
    }

    int samplesLeft = [signal count] % step;

    NSMutableArray *stepArray = [[NSMutableArray alloc] initWithArray:[signal objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange([signal count] - samplesLeft, samplesLeft)]]];
    float maxValue = -MAXFLOAT;
    for (NSNumber *value in stepArray) {
        if ([value floatValue] > maxValue) {
            maxValue = [value floatValue];
        }
    }
    float ratio = meanValue / maxValue;

    for (int j = 0; j < [stepArray count]; j++) {
        stepArray[j] = @(ratio * [stepArray[j] floatValue]);
    }
    [meanSignal addObjectsFromArray:stepArray];

    if ([meanSignal count] == [signal count]) {

        for (int i = 0; i < [signal count]; i++) {
            signal[i] = @([meanSignal[i] floatValue]);
        }

    }
}

- (void)runQualityFilterOnSignal:(NSMutableArray*)signal {
    for (int i = 0; i < [signal count]; i++) {

        float floatValue = MAX(0,[signal[i] floatValue]);
        signal[i] = @(floatValue * floatValue);

    }
}

- (void)searchPeaksInSignal:(NSMutableArray*)signal numberOfPeaksToFind:(NSInteger)numberOfPeaks completionHandel:(void (^)(BOOL success, float pulse))handler{

    NSInteger N = numberOfPeaks;
    NSMutableArray *peaks = [NSMutableArray new];
    NSMutableArray *peakvals = [NSMutableArray new];

    BOOL peakFound = true;
    NSInteger delayCount = 0;

    for (int i = 1; i < [signal count] - 1; i++) {
        if (peakFound) {
            delayCount++;
            if (delayCount > 6) {
                delayCount = 0;
                peakFound = false;
            } else {
                continue;
            }
        }

        //Peak detection
        float prev = [signal[i-1] floatValue];
        float curr = [signal[i] floatValue];
        float next = [signal[i+1] floatValue];

        if (curr > prev && curr > next) {
            [peaks addObject:@(i)];
            [peakvals addObject:signal[i]];
            peakFound = true;

            //[self.delegate updateInfoLabel:[NSString stringWithFormat:@"Got %d peaks!", [peaks count]]];
        }

        if ([peaks count] == N) {

            float meanDist = 0;
            for (int j = 1; j < [peaks count]; j++) {
                meanDist += [peaks[j] floatValue] - [peaks[j-1] floatValue];
            }
            meanDist /= [peaks count] - 1;
            NSLog(@"Mean distance: %f", meanDist);

            BOOL pulseFound = true;
            for (int j = 1; j < [peaks count]; j++) {
                float dist = [peaks[j] floatValue] - [peaks[j-1] floatValue];
                if (dist > meanDist * 1.2) {
                    pulseFound = false;
                }
            }
            if (pulseFound) {
                handler(YES, 60*FPS/meanDist);
                break;
            }

            peaks = [NSMutableArray new];
            peakvals = [NSMutableArray new];

        }
    }
    handler(NO,0);
}

- (void)dealloc {
	self.points = nil;

	[super dealloc];
}


@end
