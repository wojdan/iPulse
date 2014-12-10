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


#import "HeartRateChart.h"

#define FPS 15

@implementation HeartRateChart

@synthesize points, pointsToDraw;

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {

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
}

- (void)drawOriginalSignal {

    if(pointsToDraw.count==0) return;

    CGContextRef context=UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(context, 3);
    CGContextBeginPath(context);
    float xpos=self.bounds.size.width;
    float ypos=self.bounds.size.height/2;

    CGContextMoveToPoint(context, xpos, ypos);
    for(int i=0; i<pointsToDraw.count; i++) {
        xpos-=4;

        if (xpos < -20) {
            break;
        }

        float ypos=[[pointsToDraw objectAtIndex:i] floatValue];
        if(isnan(ypos) || ABS(ypos) > 2) {
            continue;
        }
        CGContextAddLineToPoint(context, xpos, self.bounds.size.height/2+ypos*self.bounds.size.height/6);
    }
    CGContextStrokePath(context);
}

-(void) addPoint:(NSNumber *) newPoint {
    if(!points) {
        points=[[NSMutableArray alloc] init];
        for (int i = 0; i < 100; i++) {
            [points addObject:@(0)];
        }
    }
	[points insertObject:newPoint atIndex:0];
	while(points.count>FPS * 12) {
		[points removeLastObject];
	}

    self.pointCount++;
    if (self.pointCount == 60) {
        [self runFindingPulsAlgorithmWithCompletionHandler:^(BOOL success, float pulse) {


        }];
        self.pointCount = 0;
    }
    self.pointsToDraw = [self.points mutableCopy];
    [self meanSignalForDrawing:self.pointsToDraw];
	[self setNeedsDisplay];
}

- (void)runFindingPulsAlgorithmWithCompletionHandler:(void (^)(BOOL success, float pulse))handler {

    NSMutableArray *signal = [self.points mutableCopy];
    if ([signal count] < FPS * 5) {
        return;
    }

    [self deleteNanSamplesInSignal:signal];
    [self smoothSignal:signal];
    [self meanSignal:signal toValue:2 withStep:50];
    [self runQualityFilterOnSignal:signal];
    [self searchPeaksInSignal:signal numberOfPeaksToFind:10 completionHandel:^(BOOL success, float pulse) {

        if (success) {
            [self.delegate foundHeartRate:@((unsigned int)round(pulse))];
        } else {
            [self.delegate updateInfoLabel:@"searching"];
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

    if (signal.count < 5) {
        return;
    }

    NSMutableArray *sCopy = [[NSMutableArray alloc] initWithArray:signal];
    for (int i = 2; i < [signal count] - 2; i++) {
        signal[i] = @( ([sCopy[i-2] floatValue] + 2*[sCopy[i-1] floatValue] + 3*[sCopy[i] floatValue] + 2*[sCopy[i+1] floatValue] + [sCopy[i+2] floatValue])/9.f);
    }
}

- (void)meanSignal:(NSMutableArray*)signal toValue:(float)meanValue withStep:(NSInteger)step {

    if (signal.count < step) {
        return;
    }

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

- (void)meanSignalForDrawing:(NSMutableArray*)signal{

    float maxValue = -MAXFLOAT;
    for (int i = 0; i < 100; i++) {
        NSNumber *value = signal[i];
        if ([value floatValue] > maxValue) {
            maxValue = [value floatValue];
        }
    }

    float ratio = maxValue == 0 ? 0 : 1 / maxValue;

    for (int j = 0; j < 100; j++) {
        signal[j] = @(ratio * [signal[j] floatValue]);
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

        float prev = [signal[i-1] floatValue];
        float curr = [signal[i] floatValue];
        float next = [signal[i+1] floatValue];

        if (curr > prev && curr > next) {
            [peaks addObject:@(i)];
            [peakvals addObject:signal[i]];
            peakFound = true;
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
                return;
            }

            peaks = [NSMutableArray new];
            peakvals = [NSMutableArray new];

        }
    }
    handler(NO,0);
}

- (void)dealloc {
	self.points = nil;
}


@end
