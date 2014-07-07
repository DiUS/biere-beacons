//
//  BeaconManager.m
//  BiereBeacons
//
//  Created by Brenton Crowley on 03/07/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import "BeaconManager.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>

@interface BeaconManager() <CBCentralManagerDelegate, CLLocationManagerDelegate>

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) CBCentralManager *centralManager;

@end

@implementation BeaconManager

NSString *kTemplate = @"template";
NSString *kLocationAuthorisationChange = @"LocationAuthorisationChange";

#pragma mark - Class Public API

+ (id)sharedInstance
{
    static BeaconManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}


+ (void)requestAuthorisation
{
    if (![BeaconManager isLocationAware])
    {
        switch ([CLLocationManager authorizationStatus])
        {
            case kCLAuthorizationStatusNotDetermined:
            {
                BeaconManager *manager = [BeaconManager sharedInstance];
                [manager.locationManager startUpdatingLocation];
             
                break;
            }
            default:
                
                [[[UIAlertView alloc]
                 initWithTitle:@"Location already denied."
                 message:@"This isn't the first time we've requested access. You'll need to authorise this app for location updates in the Settings app."
                 delegate:nil
                 cancelButtonTitle:@"Okay"
                 otherButtonTitles:nil] show];
                
                break;
        }
        
    }
}

+ (BOOL)isLocationAware
{
    if ([CLLocationManager locationServicesEnabled] &&
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized)
    {
        return YES;
    }
    
    return NO;
}

//+ (BOOL)isBluetoothAware
//{
//    DLog(@"Bluetooth State: %ld", [[[BeaconManager sharedInstance] centralManager] state]);
//    
//    if ([[[BeaconManager sharedInstance] centralManager] state] ==
//        CBCentralManagerStatePoweredOn)
//        return YES;
//    
//    return NO;
//}

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

#pragma mark - Instance Public API

#pragma mark - Private API

-(CLLocationManager *)locationManager
{
    if (!_locationManager)
    {
        _locationManager = [[CLLocationManager alloc] init];
        [_locationManager setDelegate:self];
    }
    
    return _locationManager;
}

- (CBCentralManager *)centralManager
{
    if (!_centralManager)
    {
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:NO],
                                 CBCentralManagerOptionShowPowerAlertKey, nil
                                 ];
        _centralManager = [[CBCentralManager alloc ]
                           initWithDelegate:self
                           queue:dispatch_get_main_queue()
                           options:options];

        [self centralManagerDidUpdateState:_centralManager];
    }
    
    return _centralManager;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSNotification *n = [NSNotification
                        notificationWithName:kLocationAuthorisationChange
                        object:self];
    
    [[NSNotificationCenter defaultCenter] postNotification:n];
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    [manager stopUpdatingLocation];
}

#pragma mark Region Monitoring

- (void)locationManager:(CLLocationManager *)manager
         didEnterRegion:(CLRegion *)region
{
    // TODO: Implement
}

- (void)locationManager:(CLLocationManager *)manager
          didExitRegion:(CLRegion *)region
{
    // TODO: Implement
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    // TODO: Implement
}

- (void)locationManager:(CLLocationManager *)manager
didStartMonitoringForRegion:(CLRegion *)region
{
    // TODO: Implement
}

- (void)locationManager:(CLLocationManager *)manager
      didDetermineState:(CLRegionState)state
              forRegion:(CLRegion *)region
{
    // TODO: Implement
}

#pragma mark Ranging

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region
{
    // TODO: Implement
}

- (void)locationManager:(CLLocationManager *)manager
rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region
              withError:(NSError *)error
{
    // TODO: Implement
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    
    // TODO: Implement
}

@end
