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
#import <CoreBluetooth/CoreBluetooth.h>
#import <AudioToolbox/AudioServices.h>

@interface BadgeViewController () <CLLocationManagerDelegate,
IngredientBadgeDelegate, UIActionSheetDelegate, MBProgressHUDDelegate,
CBCentralManagerDelegate>

@property (nonatomic) NSArray *badges;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) RegionDefaults *regionDefaults;
@property (nonatomic) CaptureManager *captureManager;
@property (nonatomic) IngredientBadge *focussedBadge;
@property (nonatomic) MBProgressHUD *hud;
@property (nonatomic) UIImageView *gameStatusImageView;


@end

NSString * const kLockedBadgedImageName = @"locked";
NSString * kBoundaryNotificationBody = \
    @"You're in the game area. Starting finding ingredients!";
static float kInset = 8.0f;

@implementation BadgeViewController

#pragma mark - Overrides

- (id)initWithBadges:(NSArray *)badges
{
    UICollectionViewFlowLayout *layout = [
                                      [UICollectionViewFlowLayout alloc] init];
    
    layout.minimumInteritemSpacing = layout.minimumLineSpacing = kInset;
    layout.itemSize = CGSizeMake(kCellWidth, kCellHeight);
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
    
    self.title = @"Found badges";
    
    UIBarButtonItem *infoItem = [[UIBarButtonItem alloc]
                                 initWithTitle:@"?"
                                 style:UIBarButtonItemStyleBordered
                                 target:self
                                 action:@selector(showGameInstructions)];

    self.navigationItem.rightBarButtonItem = infoItem;
    
    self.captureManager = [[CaptureManager alloc]
                           initWithBadges:self.badges];
    
    [self.collectionView registerClass:[BadgeCell class]
            forCellWithReuseIdentifier:kBadgeCellID];
    
    self.collectionView.backgroundColor =
                [UIColor colorWithWhite:(250.0/255.0) alpha:1.0];
    
    self.regionDefaults = [RegionDefaults sharedInstance];
    
    [self.locationManager
     startMonitoringForRegion:[self.regionDefaults beaconRegion]];
    
    [self.locationManager requestStateForRegion:
     [self.regionDefaults beaconRegion]];
    
    NSNotificationCenter *nCenter = [NSNotificationCenter defaultCenter];
    
    [nCenter addObserver:self
                selector:@selector(didReceiveNotification:)
                    name:UIApplicationDidEnterBackgroundNotification
                  object:nil];
    
    [nCenter addObserver:self
                selector:@selector(didReceiveNotification:)
                    name:UIApplicationDidBecomeActiveNotification
                  object:nil];

    [nCenter addObserver:self
                selector:@selector(didReceiveNotification:)
                    name:kBoundaryNotificationBody
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

- (UIImageView *)gameStatusImageView
{
    if (!_gameStatusImageView)
    {
        _gameStatusImageView = [[UIImageView alloc]
                                initWithFrame:self.view.frame];
        [self.view addSubview:_gameStatusImageView];
        _gameStatusImageView.hidden = YES;
    }
    
    return _gameStatusImageView;
}

- (NSString *)gameBeaconUUID
{
    return [[[RegionDefaults sharedInstance] regionUUID] UUIDString];
}

- (NSInteger)gameMajor
{
    return 15295;
}

- (NSInteger)gameMinor
{
    return 49236;
}

- (NSPredicate *)gameBeaconPredicate
{
    return [NSPredicate predicateWithFormat:@"major = %ld AND minor = %ld",
            [self gameMajor],
            [self gameMinor]
            ];
}

- (BOOL)isGameOver
{
    return [self foundBadges].count == self.badges.count;
}

- (void)showGameInstructions
{
    NSString *message = @"Rex Banner has enforced Prohibition in the office. You've got to stop him. Overcome these draconian measures by walking around the Queen Street office and finding all the ingredients needed to start your own production. Keep checking the fridge to see if you have them all.";
    
    [[[UIAlertView alloc] initWithTitle:@"Stop Rex Banner!"
                                message:message
                               delegate:nil
                      cancelButtonTitle:@"Start"
                      otherButtonTitles:nil] show];
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
        [self.locationManager requestStateForRegion:
         [self.regionDefaults beaconRegion]
         ];
    }
    else if ([notification.name isEqualToString:kBoundaryNotificationBody])
    {
        if ([[self foundBadges] count] == 0)
            [self showGameInstructions];
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
                                         kCellWidth,
                                         kCellHeight)];
        
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

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    
    DLog(@"State: %ld", central.state);
    
    if (central.state == CBCentralManagerStatePoweredOn)
    {
        [self.locationManager requestStateForRegion:
         [[RegionDefaults sharedInstance] beaconRegion]];
    }
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
    
    BOOL isNotGameOver = ![self isGameOver];
    BOOL isNoAppBadges = ([[UIApplication sharedApplication]
                          applicationIconBadgeNumber] == 0);
    BOOL isApplicationInBackground = ([[UIApplication sharedApplication]
                          applicationState] == UIApplicationStateBackground);
    switch (state)
    {
        case CLRegionStateInside:
            
            
            // Notify
            if (isNotGameOver &&
                isNoAppBadges &&
                isApplicationInBackground)
            {
                [[UIApplication sharedApplication]
                 setApplicationIconBadgeNumber:1];
                
                UILocalNotification *notification = [
                                        [UILocalNotification alloc] init];
                notification.alertBody = kBoundaryNotificationBody;
                [[UIApplication sharedApplication]
                 presentLocalNotificationNow:notification];
            }
            
            
            if ([[UIApplication sharedApplication] applicationState] ==
                UIApplicationStateActive)
            {
                [self startRangingBeaconRegion:(CLBeaconRegion *)region];
            }
            
            
            break;
        default:
            [self stopRangingBeaconRegion:(CLBeaconRegion *)region];
            
            // To remove any notification that may be present when
            // outside the boundary.
            if ([[UIApplication sharedApplication] applicationIconBadgeNumber]
                > 0)
            {
                [[UIApplication sharedApplication]
                 setApplicationIconBadgeNumber: 0];
                [[UIApplication sharedApplication]
                 cancelAllLocalNotifications];
            }
            
            break;
    }
}

#pragma mark Ranging

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region
{
    
    CLBeacon *gameBeacon = [[beacons
                            filteredArrayUsingPredicate:
                            [self gameBeaconPredicate]
                            ] firstObject];

    if (gameBeacon &&
        (gameBeacon.proximity == CLProximityNear ||
         gameBeacon.proximity == CLProximityImmediate))
    {
        NSString *imageName = \
                [self isGameOver] ? @"game_success" : @"game_error";
        
        self.gameStatusImageView.image = [UIImage imageNamed:imageName];
        
        if (self.gameStatusImageView.hidden)
            self.gameStatusImageView.hidden = NO;
        
        return;
    }
    
    if (!self.gameStatusImageView.hidden)
        self.gameStatusImageView.hidden = YES;
    
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
    DLog(@"Ranging beacons did fail: %@", error);
    CBCentralManager *bluetoothManager = [[CBCentralManager alloc]
                                 initWithDelegate:self
                                 queue:dispatch_get_main_queue()];
    
    DLog(@"Bluetooth State: %ld", bluetoothManager.state);
    [self centralManagerDidUpdateState:bluetoothManager];
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
    
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
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
