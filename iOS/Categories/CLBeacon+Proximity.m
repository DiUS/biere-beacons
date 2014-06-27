//
//  CLBeacon+Proximity.m
//  BiereBeacons
//
//  Created by Brenton Crowley on 27/06/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import "CLBeacon+Proximity.h"

@implementation CLBeacon (Proximity)

- (BOOL)isBeaconImmediate
{
    switch (self.proximity)
    {
        case CLProximityImmediate:
        case CLProximityNear:
            return YES;
            break;
            
        default:
            break;
    }
    
    return NO;
}

@end
