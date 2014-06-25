//
//  BeaconManager.h
//  BiereBeacons
//
//  Created by Brenton Crowley on 24/06/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface RegionDefaults : NSObject

+ (id)sharedInstance;
+ (BOOL)isBeaconReady;

- (NSString *)regionID;
- (NSUUID *)regionUUID;
- (CLBeaconRegion *)beaconRegion;

@end
