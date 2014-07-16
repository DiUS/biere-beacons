//
//  DeployedBeacon.h
//  BiereBeacons
//
//  Created by Brenton Crowley on 09/07/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	
	FindStatusUnknown,
    FindStatusSpotted,
    FindStatusGatherReady,
    FindStatusGathering,
    FindStatusGatherTimeout,
    FindStatusLost,
    FindStatusFound
    
} BadgeFindStatus;

@class DeployedBeacon;

@protocol DeployedBeaconDelegate <NSObject>

- (void)deployedBeaconDidSpotBadge:(DeployedBeacon *)deployedBeacon;
- (void)deployedBeaconDidStartGathering:(DeployedBeacon *)deployedBeacon;
- (void)deployedBeacon:(DeployedBeacon *)deployedBeacon
      didUpdateLogCount:(int)logCount;
- (void)deployedBeaconDidFindBadge:(DeployedBeacon *)deployedBeacon;
- (void)deployedBeaconDidTimeout:(DeployedBeacon *)deployedBeacon;
- (void)deployedBeaconDidExitBadgeArea:(DeployedBeacon *)deployedBeacon;

@end

@interface DeployedBeacon : NSObject

extern const int kNumSuccessiveLogs;
extern const double kGameThreadDuration;
extern NSString *kFirstRun;
extern NSString *kTypeGame;
extern NSString *kTypeBadge;

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *uuid;
@property (nonatomic) NSInteger major;
@property (nonatomic) NSInteger minor;
@property (nonatomic) NSInteger primaryProximity;
@property (nonatomic) NSInteger secondaryProximity;
@property (nonatomic) NSInteger measuredPower;
@property (nonatomic) NSString *type;
@property (nonatomic) NSArray *imageNames;
@property (nonatomic) NSDictionary *customProperties;
@property (nonatomic) NSInteger rssiWhenSpotted;
@property (nonatomic) double accuracyWhenSpotted;

@property (nonatomic) BadgeFindStatus findStatus;
@property (nonatomic, weak) id <DeployedBeaconDelegate> delegate;

- (void)updateLogCount;

- (id)initWithName:(NSString *)name;

@end
