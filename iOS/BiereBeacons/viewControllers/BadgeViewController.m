//
//  BadgeViewController.m
//  BiereBeacons
//
//  Created by Brenton Crowley on 24/06/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import "BadgeViewController.h"
#import "IngredientBadge.h"
#import "BadgeCell.h"
#import "RegionDefaults.h"
#import <CoreLocation/CoreLocation.h>
#import <MBProgressHUD.h>
#import "CaptureManager.h"

@interface BadgeViewController () <CLLocationManagerDelegate,
IngredientBadgeDelegate>

@property (nonatomic) NSArray *badges;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) RegionDefaults *regionDefaults;
@property (nonatomic) CaptureManager *captureManager;
@property (nonatomic) MBProgressHUD *hud;

@end

static NSString *kLockedBadgedImageName = @"locked";
static float kInset = 8.0f;

@implementation BadgeViewController

#pragma mark - Overrides

- (id)initWithBadges:(NSArray *)badges
{
    UICollectionViewFlowLayout *layout = [
                                      [UICollectionViewFlowLayout alloc] init];
    
    layout.minimumInteritemSpacing = layout.minimumLineSpacing = kInset;
    layout.itemSize = CGSizeMake(kCellSize, kCellSize);
    layout.sectionInset = UIEdgeInsetsMake(kInset, kInset, kInset, kInset);
    
    if ((self = [super initWithCollectionViewLayout:layout]))
    {
        _badges = badges;
        
        for (IngredientBadge *badge in _badges)
            badge.delegate = self;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.captureManager = [[CaptureManager alloc]
                           initWithBadges:self.badges];
    
    [self.collectionView registerClass:[BadgeCell class]
            forCellWithReuseIdentifier:kBadgeCellID];
    
    self.collectionView.backgroundColor =
                [UIColor colorWithWhite:(70.0/255.0) alpha:1.0];
    
    self.regionDefaults = [RegionDefaults sharedInstance];
    
    [self.locationManager
     startMonitoringForRegion:[self.regionDefaults beaconRegion]];
    
    NSNotificationCenter *nCenter = [NSNotificationCenter defaultCenter];
    
    [nCenter addObserver:self
                selector:@selector(didReceiveNotification:)
                    name:UIApplicationDidEnterBackgroundNotification
                  object:nil];
    
    [nCenter addObserver:self
                selector:@selector(didReceiveNotification:)
                    name:UIApplicationDidBecomeActiveNotification
                  object:nil];
    
}

#pragma mark - Public

#pragma mark - Private

-(CLLocationManager *)locationManager
{
    if (!_locationManager)
    {
        _locationManager = [[CLLocationManager alloc] init];
        [_locationManager setDelegate:self];
    }
    
    return _locationManager;
}

- (void)startRangingBeaconRegion:(CLBeaconRegion *)region
{
    if (![self.locationManager.rangedRegions containsObject:region])
        [self.locationManager
         startRangingBeaconsInRegion:(CLBeaconRegion*)region];
}

- (void)stopRangingBeaconRegion:(CLBeaconRegion *)region
{
    if ([self.locationManager.rangedRegions containsObject:region])
        [self.locationManager
         stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
}

#pragma mark Notification Callbacks

- (void)didReceiveNotification:(NSNotification *)notification
{
    if ([notification.name
         isEqualToString:UIApplicationDidEnterBackgroundNotification])
    {
        // handle enter background notification
        DLog(@"Entered Background");
//        [self stopRangingBeaconRegion:[self.regionDefaults beaconRegion]];
    }
    else if ([notification.name
              isEqualToString:UIApplicationDidBecomeActiveNotification])
    {
        // enter foreground
        DLog(@"Entered Foreground");
        [self.locationManager
         requestStateForRegion:[self.regionDefaults beaconRegion]];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    return self.badges.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    BadgeCell *cell = [collectionView
                  dequeueReusableCellWithReuseIdentifier:kBadgeCellID
                                  forIndexPath:indexPath];
    
    if (!cell)
    {
        cell = [[BadgeCell alloc]
                initWithFrame:CGRectMake(0.0,
                                         0.0,
                                         kCellSize,
                                         kCellSize)];
        
    }
    
    IngredientBadge *badge = self.badges[indexPath.row];
    
    NSString *imageName = nil;
    
    if (badge.isFound)
        imageName = [badge.imageURL lowercaseString];
    else
        imageName = kLockedBadgedImageName;
    
    cell.badgeView.image = [UIImage imageNamed:imageName];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

#pragma mark - CLLocationManagerDelegate

#pragma mark Region Monitoring

- (void)locationManager:(CLLocationManager *)manager
         didEnterRegion:(CLRegion *)region
{
    DLog(@"Did enter region");
}

- (void)locationManager:(CLLocationManager *)manager
          didExitRegion:(CLRegion *)region
{
    DLog(@"Did exit region");
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    DLog(@"Did fail");
}

- (void)locationManager:(CLLocationManager *)manager
didStartMonitoringForRegion:(CLRegion *)region
{
    DLog(@"Did start monitoring region. Total regions: %lu",
         (unsigned long)manager.monitoredRegions.count);
    
    [manager requestStateForRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager
      didDetermineState:(CLRegionState)state
              forRegion:(CLRegion *)region
{
    DLog(@"State: %ld for region: %@", (long)state, region);
    
    switch (state)
    {
        case CLRegionStateInside:
            [self startRangingBeaconRegion:(CLBeaconRegion *)region];
            break;
        default:
            [self stopRangingBeaconRegion:(CLBeaconRegion *)region];
            break;
    }
}

#pragma mark Ranging

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region
{
    [self.captureManager logRangedBeacons:beacons];
}

- (void)locationManager:(CLLocationManager *)manager
rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region
              withError:(NSError *)error
{
    DLog(@"Ranging beacons did fail");
}

#pragma mark - IngredientViewDelegate

- (void)ingredientBadgeDidStartLogging:(IngredientBadge *)badge
{
    DLog(@"Did start logging");
}

- (void)ingredientBadge:(IngredientBadge *)badge
      didUpdateLogCount:(int)logCount
{
    DLog(@"Did update log progress: %d", logCount);
}

- (void)ingredientBadgeDidFindBadge:(IngredientBadge *)badge
{
    DLog(@"Did find badge");
    [self.collectionView reloadData];
}

- (void)ingredientBadgeDidTimeout:(IngredientBadge *)badge
{
    DLog(@"Did timeout badge find");
}

@end
