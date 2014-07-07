//
//  BeaconManager.h
//  BiereBeacons
//
//  Created by Brenton Crowley on 03/07/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BeaconManager : NSObject

extern NSString *kTemplate;
extern NSString *kLocationAuthorisationChange;

+ (id)sharedInstance;
+ (BOOL)isBeaconReady;
+ (BOOL)isLocationAware;
+ (void)requestAuthorisation;

@end
