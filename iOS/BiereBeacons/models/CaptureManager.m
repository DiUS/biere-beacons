//
//  CaptureManager.m
//  BiereBeacons
//
//  Created by Brenton Crowley on 25/06/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import "CaptureManager.h"
#import "RegionDefaults.h"
#import "BeaconManager.h"
#import "DeployedBeacon+Badge.h"

@interface CaptureManager()

@property (nonatomic) NSMutableArray *loggedBeacons;
@property (nonatomic) DeployedBeacon *activeBadge;

@end

@implementation CaptureManager

- (void)logRangedBeacons:(NSArray *)beacons
{
    CLBeacon *closestBeacon = [beacons firstObject];
    NSString *key = [BeaconManager keyForUUID:closestBeacon.proximityUUID.UUIDString
                                        major:closestBeacon.major.integerValue
                                        minor:closestBeacon.minor.integerValue
                     ];
    
    DeployedBeacon *rangedBadge = [BeaconManager
                                   deployedBeaconForKey:key];
    
    // if ranged badge is found ignore updates
    
    if (self.activeBadge &&
        self.activeBadge != rangedBadge)
    {
        self.activeBadge.findStatus = FindStatusLost;
        self.activeBadge = nil;
        return;
    }
    
    if (!beacons.count)
        return;
    
    if (closestBeacon && [self isValidSpottedProximityForBeacon:closestBeacon])
    {
        self.activeBadge = rangedBadge;
        
        if (![self.activeBadge isFound])
        {
            switch (self.activeBadge.findStatus)
            {
                case FindStatusUnknown:
                    
                    self.activeBadge.rssiWhenSpotted = closestBeacon.rssi;
                    self.activeBadge.accuracyWhenSpotted = closestBeacon.accuracy;
                    self.activeBadge.findStatus = FindStatusSpotted;
                    
                    break;
                    
                case FindStatusGatherReady:
                {
                    if ([self isValidGatherProximityForBeacon:closestBeacon])
                        self.activeBadge.findStatus = FindStatusGathering;
                    
                    break;
                }
                case FindStatusGathering:
                    
                    if ([self isValidGatherProximityForBeacon:closestBeacon])
                        [self.activeBadge updateLogCount];
                    
                    break;
                    
                default:
                    break;
            }
        }
    }
}

- (BOOL)isValidGatherProximityForBeacon:(CLBeacon *)beacon
{
    NSString *key = [BeaconManager keyForUUID:beacon.proximityUUID.UUIDString
                                        major:beacon.major.integerValue
                                        minor:beacon.minor.integerValue];
    
    DeployedBeacon *deployedBeacon = [BeaconManager deployedBeaconForKey:key];
    
    if (deployedBeacon.primaryProximity == CLProximityUnknown)
        return YES;
    
    if (beacon.proximity != CLProximityUnknown &&
        beacon.proximity <= deployedBeacon.primaryProximity)
        return YES;
    
    return NO;
}

- (BOOL)isValidSpottedProximityForBeacon:(CLBeacon *)beacon
{
    NSString *key = [BeaconManager keyForUUID:beacon.proximityUUID.UUIDString
                                        major:beacon.major.integerValue
                                        minor:beacon.minor.integerValue];
    
    DeployedBeacon *deployedBeacon = [BeaconManager deployedBeaconForKey:key];
    
    if (deployedBeacon.secondaryProximity == CLProximityUnknown)
        return YES;
    
    if (beacon.proximity != CLProximityUnknown &&
        beacon.proximity <= deployedBeacon.secondaryProximity)
        return YES;
    
    return NO;
}

@end
