//
//  CaptureManager.h
//  BiereBeacons
//
//  Created by Brenton Crowley on 25/06/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CaptureManager : NSObject

- (id)initWithBadges:(NSArray *)badges;
- (void)logRangedBeacons:(NSArray *)beacons;

@end
