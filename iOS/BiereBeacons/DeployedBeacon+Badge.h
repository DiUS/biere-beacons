//
//  DeployedBeacon+Badge.h
//  BiereBeacons
//
//  Created by Brenton Crowley on 10/07/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import "DeployedBeacon.h"

@interface DeployedBeacon (Badge)


- (void)setIsFound:(BOOL)isFound;
- (BOOL)isFound;

@end
