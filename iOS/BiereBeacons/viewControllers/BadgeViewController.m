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
#import "CaptureManager.h"
#import <MBProgressHUD.h>

@interface BadgeViewController () <CLLocationManagerDelegate,
IngredientBadgeDelegate, UIActionSheetDelegate, MBProgressHUDDelegate>

@property (nonatomic) NSArray *badges;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) RegionDefaults *regionDefaults;
@property (nonatomic) CaptureManager *captureManager;
@property (nonatomic) IngredientBadge *focussedBadge;
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
    
    DLog(@"Found Badges: %@", [self foundBadges]);
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

- (void)refreshBadges
{
    [IngredientBadge writeBadges];
    [self.collectionView reloadData];
}

- (NSArray *)foundBadges
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFound = YES"];
    return [self.badges filteredArrayUsingPredicate:predicate];
}

#pragma mark Notification Callbacks

- (void)didReceiveNotification:(NSNotification *)notification
{
    if ([notification.name
         isEqualToString:UIApplicationDidEnterBackgroundNotification])
    {
        // handle enter background notification
        DLog(@"Entered Background");
        [self stopRangingBeaconRegion:[self.regionDefaults beaconRegion]];
    }
    else if ([notification.name
              isEqualToString:UIApplicationDidBecomeActiveNotification])
    {
        // enter foreground
        DLog(@"Entered Foreground");
        [self startRangingBeaconRegion:[self.regionDefaults beaconRegion]];
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
    return [self foundBadges].count;
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
    
    IngredientBadge *badge = [self foundBadges][indexPath.row];
    
    NSString *imageName = nil;
    
    if (badge.isFound)
        imageName = [badge.imageURL lowercaseString];
    else
        imageName = kLockedBadgedImageName;
    
    cell.badgeView.image = [UIImage imageNamed:imageName];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UIActionSheet *actionSheet = [
                                  [UIActionSheet alloc]
                                  initWithTitle:nil
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  destructiveButtonTitle:@"Reset"
                                  otherButtonTitles: nil];

    [actionSheet showInView:self.navigationController.view];
    
    self.focussedBadge = [self foundBadges][indexPath.row];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet
clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Reset"])
    {
        self.focussedBadge.isFound = NO;
        [self refreshBadges];
    }
    
    self.focussedBadge = nil;
}

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
    if (beacons.count)
    {
        [self.captureManager logRangedBeacons:beacons];
        DLog(@"did range beacons. %ld", beacons.count);
    }
}

- (void)locationManager:(CLLocationManager *)manager
rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region
              withError:(NSError *)error
{
    DLog(@"Ranging beacons did fail");
}

#pragma mark - IngredientViewDelegate

- (void)ingredientBadgeDidSpotBadge:(IngredientBadge *)badge
{
    DLog(@"Did Spot Badge");
    [self hideCurrentHUD];
    
    self.hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
	[self.navigationController.view addSubview:self.hud];
    
    // Recommended icon size for progress hud.
    UIImageView *customView = [[UIImageView alloc]
                               initWithFrame:CGRectMake(0.0,
                                                        0.0,
                                                        100.0,
                                                        100.0)
                               ];
    customView.contentMode = UIViewContentModeScaleAspectFit;
    customView.image = [UIImage imageNamed:kLockedBadgedImageName];
    
    self.hud.customView = customView;
    
	// Set custom view mode
	self.hud.mode = MBProgressHUDModeCustomView;
    
	self.hud.delegate = self;
	self.hud.labelText = @"Ingredient Spotted!";
    
	[self.hud show:YES];
	[self.hud hide:YES afterDelay:kGatherStartDelay];
}

- (void)ingredientBadgeDidStartGathering:(IngredientBadge *)badge
{
    DLog(@"Did start gathering");
    [self hideCurrentHUD];
}

- (void)ingredientBadge:(IngredientBadge *)badge
      didUpdateLogCount:(int)logCount
{
    DLog(@"Did update log progress: %d", logCount);
    if (!self.hud)
    {
        self.hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:self.hud];
        
        // Set determinate mode
        self.hud.mode = MBProgressHUDModeDeterminate;
        
        self.hud.delegate = self;
        self.hud.labelText = @"Gathering ingredient";
        
        // myProgressTask uses the HUD instance to update progress
        [self.hud show:YES];
    }
    
    if (self.hud.mode == MBProgressHUDModeDeterminate)
        self.hud.progress = (logCount / (double)kNumSuccessiveLogs);
    
    CABasicAnimation *animation = [CABasicAnimation animation];
    animation.fromValue = @(self.hud.progress);
    animation.toValue = @(logCount / (double)kNumSuccessiveLogs);
    animation.duration = 0.3;
}

- (void)ingredientBadgeDidFindBadge:(IngredientBadge *)badge
{
    DLog(@"Did find ingredient");
    
    [self hideCurrentHUD];
    
    self.hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
	[self.navigationController.view addSubview:self.hud];
    
    // Recommended icon size for progress hud.
    UIImageView *customView = [[UIImageView alloc]
                               initWithFrame:CGRectMake(0.0,
                                                        0.0,
                                                        100.0,
                                                        100.0)
                               ];
    customView.contentMode = UIViewContentModeScaleAspectFit;
    customView.image = [UIImage imageNamed:badge.imageURL];
    
    self.hud.customView = customView;
    
	// Set custom view mode
	self.hud.mode = MBProgressHUDModeCustomView;
    
	self.hud.delegate = self;
	self.hud.labelText = [NSString stringWithFormat:@"Found %@", badge.name];
    
	[self.hud show:YES];
	[self.hud hide:YES afterDelay:3];
    [self refreshBadges];
}

- (void)ingredientBadgeDidTimeout:(IngredientBadge *)badge
{
    DLog(@"Did timeout badge find");
    
    [self hideCurrentHUD];
    
    self.hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
	[self.navigationController.view addSubview:self.hud];
    
    self.hud.mode = MBProgressHUDModeText;
    
	self.hud.labelText = @"Lost ingredient!";
	self.hud.detailsLabelText = @"Keep looking";
    
    [self.hud show:YES];
    [self.hud hide:YES afterDelay:3.0];
}

#pragma mark - MBProgressHudDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
	[self.hud removeFromSuperview];
	self.hud = nil;
}

- (void)onLogUpdate:(NSNumber *)logCount
{
    float progress = (logCount.floatValue / kNumSuccessiveLogs);
    self.hud.progress = progress;
    usleep(50000);
}

- (void)hideCurrentHUD
{
    if (self.hud)
    {
        [self.hud hide:NO];
        [self.hud removeFromSuperview];
        self.hud = nil;
    }
}

@end
