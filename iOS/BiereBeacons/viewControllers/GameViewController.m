//
//  GameViewController.m
//  BiereBeacons
//
//  Created by Brenton Crowley on 04/07/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import "GameViewController.h"
#import "BeaconManager.h"
#import "UserActionDetailViewController.h"
#import "IneligibleDeviceViewController.h"
#import "UIColor+AppColors.h"
#import "BadgeViewController.h"

@interface GameViewController () <UserActionDetailDelegate>

@property (nonatomic) NSInteger index;
@property (nonatomic) UIViewController *childController;

@end

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIPageControl *pageControl = [UIPageControl appearance];
    pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    pageControl.currentPageIndicatorTintColor = [UIColor appPaleYellow];
    pageControl.backgroundColor = [UIColor appPaleBrown];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(didLocationAuthorisationChange:)
     name:kLocationAuthorisationChange
     object:nil];
    
    [self invalidateChildController];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void)invalidateChildController
{
    if ([self.childViewControllers containsObject:self.childController])
    {
        [self.childController willMoveToParentViewController:nil];
        [self.childController.view removeFromSuperview];
        [self.childController removeFromParentViewController];
    }
    
    // reset childController
    self.childController = nil;
    
    [self addChildViewController:self.childController];
    self.childController.view.frame = CGRectMake(0.0,
                                                    0.0,
                                                    self.view.frame.size.width,
                                                    self.view.frame.size.height
                                                    );
    [self.view addSubview:self.childController.view];
    [self.childController didMoveToParentViewController:self];
    
    self.title = self.childController.title;
    self.navigationItem.rightBarButtonItem = [self.childController.navigationItem
                                              rightBarButtonItem];
    self.navigationItem.leftBarButtonItem = [self.childController.navigationItem
                                              leftBarButtonItem];
}

- (UIViewController *)childController
{
    if (!_childController)
    {
        if(![BeaconManager isBeaconReady])
        {
            _childController = [[IneligibleDeviceViewController alloc] init];
        }
        
        if (![BeaconManager isLocationAware])
        {
            UserActionDetailViewController *locationAction = [[UserActionDetailViewController alloc]
                                                              initWithTitle:@"Location Needed"
                                                              actionLabel:@"Authorise it now"
                                                              description:@"The game needs to know how close you are to iBeacons. In order to gain this information we need you to grant the app Location Service privileges. The game is otherwise unplayable."
                                                              ];
            [locationAction setDelegate:self];

            _childController = locationAction;
        }
        else
        {
            NSPredicate *badgePredicate = [NSPredicate
                                           predicateWithFormat:@"type = 'badge'"];
            NSArray *badges = [[BeaconManager deployedBeacons]
                               filteredArrayUsingPredicate:badgePredicate];

            _childController = [[BadgeViewController alloc ]
                                initWithBadges:badges];
        }
    }
    
    return _childController;
}

#pragma mark - UserActionDetailDelegate

- (void)userActionDetailVC:(UserActionDetailViewController *)vc
                  didPress:(id)sender
{
    if ([vc.title isEqualToString:@"Location Needed"])
        [BeaconManager requestAuthorisation];
}

- (void)didLocationAuthorisationChange:(NSNotification *)notification
{
    [self invalidateChildController];
}

@end
