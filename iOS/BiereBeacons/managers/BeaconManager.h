//
//  BeaconManager.h
//  BiereBeacons
//
//  Created by Brenton Crowley on 03/07/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DeployedBeacon.h"
#import <CoreLocation/CoreLocation.h>

@interface BeaconManager : NSObject

extern NSString *kTemplate;
extern NSString *kLocationAuthorisationChange;

+ (id)sharedInstance;
+ (NSArray *)deployedBeacons;
+ (BOOL)isBeaconReady;
+ (BOOL)isLocationAware;
+ (void)requestAuthorisation;
+ (void)writeBeaconsToFile;
+ (DeployedBeacon *)deployedBeaconForKey:(NSString *)key;
+ (NSString *)keyForUUID:(NSString *)uuid
                   major:(NSInteger)major
                   minor:(NSInteger)minor;

@end
