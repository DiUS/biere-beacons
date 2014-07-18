//
//  BadgeViewController.m
//  BiereBeacons
//
//  Created by Brenton Crowley on 24/06/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import "BadgeViewController.h"
#import "BadgeCell.h"
#import "RegionDefaults.h"
#import <CoreLocation/CoreLocation.h>
#import "CaptureManager.h"
#import <MBProgressHUD.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <AudioToolbox/AudioServices.h>
#import "UIColor+AppColors.h"
#import "BeaconManager.h"
#import "DeployedBeacon+Badge.h"
#import "GatherProgressView.h"
#import "InstructionsViewController.h"

@interface BadgeViewController () <CLLocationManagerDelegate,
DeployedBeaconDelegate, UIActionSheetDelegate, MBProgressHUDDelegate,
CBCentralManagerDelegate, InstructionsViewControllerDelegate>

@property (nonatomic) NSArray *deployedBeacons;
@property (nonatomic) NSArray *rangedBeacons;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) RegionDefaults *regionDefaults;
@property (nonatomic) CaptureManager *captureManager;
@property (nonatomic) DeployedBeacon *focussedBadge;
@property (nonatomic) MBProgressHUD *hud;
@property (nonatomic) UIImageView *gameStatusImageView;
@property (nonatomic) NSTimer *gameThread;
@property (nonatomic) BOOL debug;
@property (nonatomic) UIImageView *debugImageView;
@property (nonatomic) BOOL isGameThreadPaused;

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
        _deployedBeacons = badges;
        
        for (DeployedBeacon *badge in _deployedBeacons)
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
    
    UIBarButtonItem *debugItem = [[UIBarButtonItem alloc]
                                 initWithTitle:@"debug"
                                 style:UIBarButtonItemStyleBordered
                                 target:self
                                 action:@selector(toggleDebug)];
    
//    self.navigationItem.leftBarButtonItem = debugItem;
    
    self.captureManager = [[CaptureManager alloc] init];
    
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

    [self validateBluetoothStatus];
    
    self.debug = NO;
    
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
    [BeaconManager writeBeaconsToFile];
    [self.collectionView reloadData];
}

- (NSArray *)foundBadges
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFound = YES"];
    return [self.deployedBeacons filteredArrayUsingPredicate:predicate];
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

- (BOOL)isGameOver
{
    return [self foundBadges].count == self.deployedBeacons.count;
}

- (UIImageView *)debugImageView
{
    if (!_debugImageView)
    {
        NSInteger width = 50;
        NSInteger height = width;
        NSInteger x = 0;
        NSInteger y = self.view.frame.size.height - height;
        
        _debugImageView = [[UIImageView alloc]
                           initWithFrame:CGRectMake(x,y,width,height)
                           ];
        _debugImageView.contentMode = UIViewContentModeScaleAspectFit;
        _debugImageView.hidden = !self.debug;
        [self.view addSubview:_debugImageView];
    }
    
    return _debugImageView;
}

- (void)setDebug:(BOOL)debug
{
    _debug = debug;
    
    self.debugImageView.hidden = !self.debug;
    [self.navigationItem.leftBarButtonItem setTitle:[NSString stringWithFormat:@"Debug:%@", _debug ? @"Y" : @"N"]];
}

#pragma mark - TargetActions

- (void)toggleDebug
{
    self.debug = !self.debug;
}

- (void)validateBluetoothStatus
{
    CBCentralManager *bluetoothManager = [[CBCentralManager alloc]
                                          initWithDelegate:self
                                          queue:dispatch_get_main_queue()];
    
    DLog(@"Bluetooth State: %ld", (unsigned long)bluetoothManager.state);
    [self centralManagerDidUpdateState:bluetoothManager];
}

- (void)showGameInstructions
{
    InstructionsViewController *vc = [[InstructionsViewController alloc]
                                      initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                      navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                      options:nil];
    vc.instructionsDelegate = self;
    
    UINavigationController *nav = [[UINavigationController alloc]
                                   initWithRootViewController:vc];

    [self.navigationController presentViewController:nav
                                            animated:YES
                                          completion:nil];
    
    self.isGameThreadPaused = YES;
    
}

- (void)editSettings
{

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
        
        DLog(@"Entered Foreground");
        [self.locationManager requestStateForRegion:
         [self.regionDefaults beaconRegion]
         ];
        [self startGameThread];
    }
}

#pragma mark - InstructionsViewControllerDelegate

- (void)instructionsDidClose:(InstructionsViewController *)controller
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    
    self.isGameThreadPaused = NO;
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
    
    DeployedBeacon *badge = [self foundBadges][indexPath.row];
    
    NSString *imageName = nil;
    
    if ([badge isFound])
    {
        imageName = [badge.name lowercaseString];
        cell.badgeView.image = [UIImage imageNamed:imageName];
        cell.badgeView.hidden = NO;
    }
    else
    {
        cell.badgeView.image = nil;
        cell.badgeView.hidden = YES;
    }
    
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
                                  destructiveButtonTitle:@"Reset found to 'no'"
                                  otherButtonTitles: @"Edit settings", nil];

    [actionSheet showInView:self.navigationController.view];
    
    self.focussedBadge = [self foundBadges][indexPath.row];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet
clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Reset found to 'no'"])
    {
        [self.focussedBadge setIsFound:NO];
        [self refreshBadges];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Edit settings"])
    {
        [self stopGameThread];
        
        BadgeConfigViewController *vc = [[BadgeConfigViewController alloc]
                                         init];
        vc.beacon = self.focussedBadge;
        vc.delegate = self;
        UINavigationController *navVC = [[UINavigationController alloc]
                                         initWithRootViewController:vc];
        [self.navigationController presentViewController:navVC
                                                animated:YES
                                              completion:nil];
    }
    
    self.focussedBadge = nil;
}

#pragma mark - BadgeConfigDelegate

- (void)badgeConfigVCDidUpdate:(BadgeConfigViewController *)vc
                        beacon:(DeployedBeacon *)beacon
{
    if (beacon)
    {
        [BeaconManager writeBeaconsToFile];
        [self refreshBadges];
    }
    
    [self.navigationController dismissViewControllerAnimated:YES
                                                  completion:nil];
    
    [self startGameThread];
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    
    DLog(@"State: %ld", (long)central.state);
    
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
    
    NSSortDescriptor *proximity = [[NSSortDescriptor alloc]
                                   initWithKey:@"proximity"
                                   ascending:YES
                                   comparator:^NSComparisonResult(NSNumber *prox1, NSNumber *prox2) {
                                       
                                       if ([prox1 integerValue] == 0)
                                           return (NSComparisonResult)NSOrderedDescending;
                                       
                                       return (NSComparisonResult)[prox1 compare:prox2];
                                   }];
    
    NSSortDescriptor *accuracy = [[NSSortDescriptor alloc ]
                                  initWithKey:@"accuracy"
                                  ascending:YES
                                  comparator:^NSComparisonResult(NSNumber *acc1, NSNumber *acc2) {
                                      
                                      if ([acc1 doubleValue] < 0)
                                          return (NSComparisonResult)NSOrderedDescending;
                                      
                                      return (NSComparisonResult)[acc1 compare:acc2];
                                  }];
    
    self.rangedBeacons = [beacons sortedArrayUsingDescriptors:@[
                                                                proximity,
                                                                accuracy
                                                                ]
                          ];
    
//    DLog(@"did range beacons. %ld", (unsigned long)beacons.count);
}

- (void)locationManager:(CLLocationManager *)manager
rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region
              withError:(NSError *)error
{
    DLog(@"Ranging beacons did fail: %@", error);
    [self validateBluetoothStatus];
}

#pragma mark - DeployedBeaconDelegate

- (void)deployedBeaconDidSpotBadge:(DeployedBeacon *)beacon
{
    DLog(@"Did Spot Badge");
    [self hideCurrentHUD];
    
    self.hud = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:self.hud];
    
    // Recommended icon size for progress hud.
    UIImageView *customView = [[UIImageView alloc]
                               initWithFrame:CGRectMake(0.0,
                                                        0.0,
                                                        100.0,
                                                        100.0)
                               ];
    customView.contentMode = UIViewContentModeScaleAspectFit;
    customView.image = [UIImage imageNamed:kLockedBadgedImageName];
    
    self.hud.customView = [[GatherProgressView alloc]
                           initWithFrame:CGRectMake(0.0,
                                                    0.0,
                                                    100.0,
                                                    140.0)
                           ];
    
	// Set custom view mode
	self.hud.mode = MBProgressHUDModeCustomView;
    
	self.hud.delegate = self;
	self.hud.labelText = @"Ingredient Spotted!";
    self.hud.detailsLabelText = @"Get closer to the ingredient to gather it.";
    
	[self.hud show:YES];
    
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
}

- (void)deployedBeaconDidStartGathering:(DeployedBeacon *)deployedBeacon
{
    DLog(@"Did start gathering");
    [self hideCurrentHUD];
}

- (void)deployedBeacon:(DeployedBeacon *)deployedBeacon
      didUpdateLogCount:(int)logCount
{
    DLog(@"Did update log progress: %d", logCount);
    if (!self.hud)
    {
        self.hud = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:self.hud];
        
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

- (void)deployedBeaconDidFindBadge:(DeployedBeacon *)deployedBeacon
{
    DLog(@"Did find ingredient");
    [deployedBeacon setIsFound:YES];
    
    [self hideCurrentHUD];
    
    self.hud = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:self.hud];
    
    // Recommended icon size for progress hud.
    UIImageView *customView = [[UIImageView alloc]
                               initWithFrame:CGRectMake(0.0,
                                                        0.0,
                                                        100.0,
                                                        140.0)
                               ];
    customView.contentMode = UIViewContentModeScaleAspectFit;
    customView.image = [UIImage imageNamed:[deployedBeacon.name lowercaseString]];
    
    self.hud.customView = customView;
    
	// Set custom view mode
	self.hud.mode = MBProgressHUDModeCustomView;
    
	self.hud.delegate = self;
	self.hud.labelText = [NSString stringWithFormat:@"Found %@", deployedBeacon.name];
    
	[self.hud show:YES];
	[self.hud hide:YES afterDelay:3];
    [self refreshBadges];
}

- (void)deployedBeaconDidExitBadgeArea:(DeployedBeacon *)deployedBeacon
{
    [self hideCurrentHUD];
    
    if (![deployedBeacon isFound])
    {
        self.hud = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:self.hud];
        
        self.hud.mode = MBProgressHUDModeText;
        
        self.hud.labelText = @"Lost ingredient :(";
        self.hud.detailsLabelText = @"Keep looking...";
        
        [self.hud show:YES];
        [self.hud hide:YES afterDelay:3.0];
    }
}

- (void)deployedBeaconDidTimeout:(DeployedBeacon *)deployedBeacon
{
    DLog(@"Did timeout badge find");
    
    [self hideCurrentHUD];
    
    self.hud = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:self.hud];
    
    // Recommended icon size for progress hud.
    UIImageView *customView = [[UIImageView alloc]
                               initWithFrame:CGRectMake(0.0,
                                                        0.0,
                                                        100.0,
                                                        100.0)
                               ];
    customView.contentMode = UIViewContentModeScaleAspectFit;
    customView.image = [UIImage imageNamed:kLockedBadgedImageName];
    
    self.hud.customView = [[GatherProgressView alloc]
                           initWithFrame:CGRectMake(0.0,
                                                    0.0,
                                                    100.0,
                                                    140.0)
                           ];
    
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
    [self stopGameThread];
    
    self.gameThread = [NSTimer
                       scheduledTimerWithTimeInterval:kGameThreadDuration
                       target:self
                       selector:@selector(updateGame:)
                       userInfo:nil
                       repeats:YES
                       ];
    DLog(@"Started Game Thread");
}

- (void)stopGameThread
{
    if (self.gameThread)
        [self.gameThread invalidate];
    
    DLog(@"Stopped Game Thread");
}

- (void)updateGame:(NSTimer *)timer
{
    if (self.isGameThreadPaused)
        return;
    
    CLBeacon *closestBeacon = [self.rangedBeacons firstObject];
    NSString *key = [BeaconManager keyForUUID:closestBeacon.proximityUUID.UUIDString
                                        major:closestBeacon.major.integerValue
                                        minor:closestBeacon.minor.integerValue
                     ];
    
    DeployedBeacon *deployedBeacon = [BeaconManager deployedBeaconForKey:key];
    
    if ([deployedBeacon.type isEqualToString:kTypeBadge])
    {
        [self.captureManager logRangedBeacons:@[closestBeacon]];
        
        if (!self.gameStatusImageView.hidden)
            self.gameStatusImageView.hidden = YES;
        
    }
    else if([deployedBeacon.type isEqualToString:kTypeGame] &&
            closestBeacon.proximity == CLProximityImmediate)
    {
        // we have a game beacon
        NSString *imageName = \
        [self isGameOver] ? @"game_success" : @"game_error";
        
        self.gameStatusImageView.image = [UIImage imageNamed:imageName];
        
        if (self.gameStatusImageView.hidden)
            self.gameStatusImageView.hidden = NO;
        
        [self.captureManager logRangedBeacons:nil];
    }
    
    if (self.debug && deployedBeacon)
        self.debugImageView.image = [UIImage
                                     imageNamed:[deployedBeacon.name lowercaseString]];
    else
        self.debugImageView.image = nil;
    
    // Give the user an indication of their proximity when the ingredient is
    // spotted.
    if (self.hud)
    {
        if ([self.hud.customView isKindOfClass:[GatherProgressView class]])
        {
            GatherProgressView *view = (GatherProgressView *)self.hud.customView;
            
            if ([closestBeacon accuracy] > [deployedBeacon accuracyWhenSpotted])
                deployedBeacon.accuracyWhenSpotted = closestBeacon.accuracy;
            
            // Accuracy progress
            CGFloat min = 0;
            CGFloat max = [deployedBeacon accuracyWhenSpotted];
            CGFloat currentValue =
                                    [closestBeacon accuracy] != -1 ?
                                    [closestBeacon accuracy] :
                                    max;
            
            CGFloat progress = 1 - (currentValue - min) / (max - min);
            [view setProgress:progress];
        }
    }
}

@end
