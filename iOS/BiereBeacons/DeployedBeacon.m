//
//  DeployedBeacon.m
//  BiereBeacons
//
//  Created by Brenton Crowley on 09/07/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import "DeployedBeacon.h"

@interface DeployedBeacon()

@property (nonatomic) NSTimer *logTimout;
@property (nonatomic) int logCount;

@end

@implementation DeployedBeacon

NSString const *kFirstRun = @"firstRun";
NSString const *kTypeGame = @"game";
NSString const *kTypeBadge = @"badge";
int const kNumSuccessiveLogs = 10;
double const kGameThreadDuration = 0.5;
double const kGatherTimeoutDuration = 2.0;

- (id)initWithName:(NSString *)name
{
    if ((self = [super init]))
    {
        _name = name;
    }
    
    return self;
}

- (BadgeFindStatus)badgeFindStatus
{
    return self.findStatus;
}

- (void)setFindStatus:(BadgeFindStatus)findStatus
{
    _findStatus = findStatus;
    
    switch (_findStatus)
    {
        case FindStatusUnknown:
            
            [self stopGatherTimeout];
            
            break;
            
        case FindStatusSpotted:
            
            [self.delegate deployedBeaconDidSpotBadge:self];
            self.findStatus = FindStatusGatherReady;
            
            break;
            
        case FindStatusGatherReady:
            
            self.logCount = 0;
            
            break;
            
        case FindStatusGathering:
            
            [self.delegate deployedBeaconDidStartGathering:self];
            
            break;
            
        case FindStatusGatherTimeout:
            
            [self.delegate deployedBeaconDidTimeout:self];
            self.findStatus = FindStatusGatherReady;
            
            break;
            
        case FindStatusFound:
            
            [self.delegate deployedBeaconDidFindBadge:self];
            
            break;
            
        case FindStatusLost:
            
            [self.delegate deployedBeaconDidExitBadgeArea:self];
            self.findStatus = FindStatusUnknown;
            
            break;
            
        default:
            break;
    }
}

- (void)updateLogCount
{
    [self stopGatherTimeout];
    [self startGatherTimeout];
    
    // increment logCount
    self.logCount += 1;
    [self.delegate deployedBeacon:self
                 didUpdateLogCount:self.logCount];
    // if log count == kNumSuccessiveLogs, then set to found
    if (self.logCount == (int)(kNumSuccessiveLogs / kGameThreadDuration))
    {
        self.findStatus = FindStatusFound;
        [self stopGatherTimeout];
    }
    
    DLog(@"Update Log Count - State: %d", self.findStatus);
}

#pragma mark - Private

#pragma mark Timer

- (void)startGatherTimeout
{
    [self stopGatherTimeout];
    
    self.logTimout = [NSTimer
                      scheduledTimerWithTimeInterval:kGatherTimeoutDuration
                      target:self
                      selector:@selector(onLogTimedOut:)
                      userInfo:nil
                      repeats:NO
                      ];
}

- (void)stopGatherTimeout
{
    if (self.logTimout)
    {
        [self.logTimout invalidate];
        self.logTimout = nil;
    }
}

- (void)onLogTimedOut:(NSTimer *)timer
{
    [self stopGatherTimeout];
    
    self.findStatus = FindStatusGatherTimeout;
}

@end
