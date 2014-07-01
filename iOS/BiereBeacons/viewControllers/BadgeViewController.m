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
#import "UIColor+AppColors.h"

@interface BadgeViewController () <CLLocationManagerDelegate,
IngredientBadgeDelegate, UIActionSheetDelegate, MBProgressHUDDelegate,
CBCentralManagerDelegate>

@property (nonatomic) NSArray *badges;
@property (nonatomic) NSArray *rangedBeacons;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) RegionDefaults *regionDefaults;
@property (nonatomic) CaptureManager *captureManager;
@property (nonatomic) IngredientBadge *focussedBadge;
@property (nonatomic) MBProgressHUD *hud;
@property (nonatomic) UIImageView *gameStatusImageView;
@property (nonatomic) NSTimer *gameThread;

@end

NSString * const kLockedBadgedImageName = @"locked";
NSString * kBoundaryNotificationBody = \
    @"You're in the game area. Start finding ingredients!";
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
    [infoItem setTitleTextAttributes:@{
                   NSForegroundColorAttributeName : [UIColor appPaleYellow]}
                            forState:UIControlStateNormal];
    
    self.navigationItem.rightBarButtonItem = infoItem;
    
    self.captureManager = [[CaptureManager alloc]
                           initWithBadges:self.badges];
    
    [self.collectionView registerClass:[BadgeCell class]
            forCellWithReuseIdentifier:kBadgeCellID];
    
    self.collectionView.backgroundColor = [UIColor appPaleYellow];
    
    self.regionDefaults = [RegionDefaults sharedInstance];
    
    
    
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

    // Show instuctions if first run
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *firstRun = (NSNumber *)[defaults
                          objectForKey:kFirstRun];
    if (firstRun.boolValue)
    {
        [self showGameInstructions];
        [defaults setObject:[NSNumber numberWithBool:NO] forKey:kFirstRun];
        [defaults synchronize];
    }
    
    [self validateBluetoothStatus];
    
}

#pragma mark - Public

#pragma mark - Private

- (NSArray *)rangedBeacons
{
    if (!_rangedBeacons)
    {
        _rangedBeacons = @[];
    }
    
    return _rangedBeacons;
}

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
    NSString *message = @"Rex Banner has enforced Prohibition in the office. You must stop him. Overcome these draconian measures by walking around the Queen Street office and finding all the ingredients needed to start your own beer production. After you find an ingredient, check the white fridge by standing in front of it to see if you have them all.";
    
    [[[UIAlertView alloc] initWithTitle:@"Stop Rex Banner!"
                                message:message
                               delegate:nil
                      cancelButtonTitle:@"Okay"
                      otherButtonTitles:nil] show];
}

- (void)validateBluetoothStatus
{
    CBCentralManager *bluetoothManager = [[CBCentralManager alloc]
                                          initWithDelegate:self
                                          queue:dispatch_get_main_queue()];
    
    DLog(@"Bluetooth State: %ld", (unsigned long)bluetoothManager.state);
    [self centralManagerDidUpdateState:bluetoothManager];
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
        [self stopGameThread];
    }
    else if ([notification.name
              isEqualToString:UIApplicationDidBecomeActiveNotification])
    {
        self.locationManager = nil;
        // enter foreground
        [self.locationManager
         startMonitoringForRegion:[self.regionDefaults beaconRegion]];
        
        [self.locationManager requestStateForRegion:
         [self.regionDefaults beaconRegion]];
        DLog(@"Entered Foreground");
        [self.locationManager requestStateForRegion:
         [self.regionDefaults beaconRegion]
         ];
        [self startGameThread];
    }
//    else if ([notification.name isEqualToString:kBoundaryNotificationBody])
//    {
//        if ([[self foundBadges] count] == 0)
//            [self showGameInstructions];
//    }
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
    
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:

            [self.locationManager
             requestStateForRegion:[self.regionDefaults beaconRegion]];
            
            break;
            
        default:
            
            break;
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
            
            // Notification when app is in background to play the game.
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
    
    self.rangedBeacons = beacons;
    
    DLog(@"did range beacons. %ld", (unsigned long)beacons.count);
}

- (void)locationManager:(CLLocationManager *)manager
rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region
              withError:(NSError *)error
{
    DLog(@"Ranging beacons did fail: %@", error);
    [self validateBluetoothStatus];
}

#pragma mark - IngredientBadgeDelegate

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
    self.hud.detailsLabelText = @"Get closer to the ingredient to gather it.";
    
	[self.hud show:YES];
//    [self.hud hide:YES afterDelay:3];
    
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
        self.hud.progress = (logCount / (kNumSuccessiveLogs / kGameThreadDuration));
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

- (void)ingredientBadgeDidExitBadgeArea:(IngredientBadge *)badge
{
    [self hideCurrentHUD];
    
    if (!badge.isFound)
    {
        self.hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:self.hud];
        
        self.hud.mode = MBProgressHUDModeText;
        
        self.hud.labelText = @"Lost ingredient :(";
        self.hud.detailsLabelText = @"Keep looking...";
        
        [self.hud show:YES];
        [self.hud hide:YES afterDelay:3.0];
    }
}

- (void)ingredientBadgeDidTimeout:(IngredientBadge *)badge
{
    DLog(@"Did timeout badge find");
    
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
    
	self.hud.labelText = @"Gather timed out.";
	self.hud.detailsLabelText = @"You probably weren't close enough to the ingredient, but you're still near it, so try again.";
    
    [self.hud show:YES];
}

#pragma mark - MBProgressHudDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
	[self.hud removeFromSuperview];
	self.hud = nil;
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

#pragma mark - GameThread

- (void)startGameThread
{
    if (!self.gameThread)
    {
        self.gameThread = [NSTimer
                           scheduledTimerWithTimeInterval:kGameThreadDuration
                           target:self
                           selector:@selector(updateGame:)
                           userInfo:nil
                           repeats:YES
                           ];
        DLog(@"Started Game Thread");
    }
}

- (void)stopGameThread
{
    [self.gameThread invalidate];
    self.gameThread = nil;
    
    DLog(@"Stopped Game Thread");
}

- (void)updateGame:(NSTimer *)timer
{
    DLog(@"Update Game: %@", self.rangedBeacons);
    
    NSArray *beacons = self.rangedBeacons;
    
    CLBeacon *gameBeacon = [[beacons
                             filteredArrayUsingPredicate:
                             [self gameBeaconPredicate]
                             ] firstObject];
    
    if (gameBeacon &&
        (gameBeacon.proximity == CLProximityImmediate ||
         gameBeacon.proximity == CLProximityNear)
        )
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
    
    NSPredicate *excludeGameBeacon = [NSPredicate
                                      predicateWithFormat:@"major != %ld",
                                      [self gameMajor]];
    
    NSArray *badgeBeacons = [beacons
                             filteredArrayUsingPredicate:excludeGameBeacon];
    
    [self.captureManager logRangedBeacons: badgeBeacons];
}

@end
