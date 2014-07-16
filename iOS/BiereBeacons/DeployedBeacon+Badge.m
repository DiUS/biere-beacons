//
//  DeployedBeacon+Badge.m
//  BiereBeacons
//
//  Created by Brenton Crowley on 10/07/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import "DeployedBeacon+Badge.h"
#import "BeaconManager.h"

@implementation DeployedBeacon (Badge)

- (void)setIsFound:(BOOL)isFound
{
    NSMutableDictionary *custom = [NSMutableDictionary
                                   dictionaryWithDictionary:self.customProperties];
    
    custom[@"isFound"] = [NSNumber numberWithBool:isFound];
    
    self.customProperties = custom;
    
    if (!isFound)
        self.findStatus = FindStatusUnknown;
    
    [BeaconManager writeBeaconsToFile];
}

- (BOOL)isFound
{
    NSNumber *isFound = self.customProperties[@"isFound"];
    
    if (!isFound)
        return NO;
    
    return isFound.boolValue;
}

@end
