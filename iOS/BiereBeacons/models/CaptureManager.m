//
//  CaptureManager.m
//  BiereBeacons
//
//  Created by Brenton Crowley on 25/06/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import "CaptureManager.h"
#import "IngredientBadge.h"
#import <CoreLocation/CoreLocation.h>
#import "RegionDefaults.h"
#import <MBProgressHUD.h>

@interface CaptureManager()

@property (nonatomic) NSArray *foundBeacons;
@property (nonatomic) NSMutableArray *loggedBeacons;
@property (nonatomic) NSDictionary *badges;

@end

@implementation CaptureManager

- (id)initWithBadges:(NSArray *)badges
{
    if ((self = [super init]))
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];

        for (IngredientBadge *badge in badges)
        {
            NSString *key = [self keyForUUID:badge.uuid
                                       major:badge.major
                                       minor:badge.minor];
            dict[key] = badge;
        }
        
        _badges = dict;
    }
    
    return self;
}

- (void)logRangedBeacons:(NSArray *)beacons
{
    CLBeacon *closestBeacon = [beacons firstObject];
    
    if (closestBeacon)
    {
        IngredientBadge *badge = [self badgeForBeacon:closestBeacon];
        
        if (!badge.isFound)
            [badge updateCaptureCount];
    }
}

- (IngredientBadge *)badgeForBeacon:(CLBeacon *)beacon
{
    
    NSString *key = [self keyForUUID:beacon.proximityUUID.UUIDString
                               major:beacon.major.integerValue
                               minor:beacon.minor.integerValue
                     ];
    
    return self.badges[key];
}

- (NSString *)keyForUUID:(NSString *)uuid
                   major:(NSInteger)major
                   minor:(NSInteger)minor
{
    NSString *key = [NSString stringWithFormat:@"%@%ld%ld",
                     uuid,
                     (long)major,
                     (long)minor];
    
    return key;
}

@end
