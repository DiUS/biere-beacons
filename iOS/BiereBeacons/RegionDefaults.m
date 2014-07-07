//
//  BeaconManager.m
//  BiereBeacons
//
//  Created by Brenton Crowley on 24/06/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import "RegionDefaults.h"

@interface RegionDefaults()

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) CLBeaconRegion *beaconRegion;
@property (nonatomic) NSUUID *regionUUID;

@end

@implementation RegionDefaults

#pragma mark - Public API

+ (id)sharedInstance
{
    static RegionDefaults *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (BOOL)isBeaconReady
{
    if (![CLLocationManager
         isMonitoringAvailableForClass:[CLBeaconRegion class]] ||
        ![CLLocationManager isRangingAvailable])
    {
        return NO;
    }
    
    return YES;
}

- (CLBeaconRegion *)beaconRegion
{
    if (!_beaconRegion)
    {
        
        _beaconRegion = [[CLBeaconRegion alloc]
                         initWithProximityUUID:[self regionUUID]
                         identifier:[self regionID]];
        [_beaconRegion setNotifyEntryStateOnDisplay:YES];
    }
    
    return _beaconRegion;
}

- (NSString *)regionID
{
    return @"region.dius";
}

- (NSUUID *)regionUUID
{
    if (!_regionUUID)
    {
        _regionUUID = [[NSUUID alloc]
                   initWithUUIDString:@"b9407f30-f5f8-466e-aff9-25556b57fe6d"];
    }
    
    return _regionUUID;
}

- (void)startMonitoring
{
    if (![self.locationManager.monitoredRegions
          containsObject:self.beaconRegion])
    {
        [self.locationManager startMonitoringForRegion:self.beaconRegion];
    }
}

@end
