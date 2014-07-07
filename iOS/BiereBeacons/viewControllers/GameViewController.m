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
#import "IngredientBadge.h"

@interface GameViewController () <UIPageViewControllerDataSource,
UIPageViewControllerDelegate, UserActionDetailDelegate>

@property (nonatomic) UIPageViewController *pageViewController;
@property (nonatomic) NSArray *pages;
@property (nonatomic) NSInteger index;

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
    
    [self invalidatePageViewController];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void)invalidatePageViewController
{
    if ([self.childViewControllers containsObject:self.pageViewController])
    {
        [self.pageViewController willMoveToParentViewController:nil];
        [self.pageViewController.view removeFromSuperview];
        [self.pageViewController removeFromParentViewController];
    }
    
    self.pageViewController = nil;
    self.pages = nil;
    
    self.index = 0;
    
    [self addChildViewController:self.pageViewController];
    self.pageViewController.view.frame = CGRectMake(0.0,
                                                    0.0,
                                                    self.view.frame.size.width,
                                                    self.view.frame.size.height
                                                    );
    [self.view addSubview:self.pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
    
    self.title = [self.pages[self.index] title];
    self.navigationItem.rightBarButtonItem = [[self.pages[self.index]
                                               navigationItem]
                                              rightBarButtonItem];
    self.navigationItem.leftBarButtonItem = [[self.pages[self.index]
                                               navigationItem]
                                              leftBarButtonItem];
}

- (UIPageViewController *)pageViewController
{
    if (!_pageViewController)
    {
        _pageViewController = [
           [UIPageViewController alloc]
           initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
           navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
           options:nil
                               ];
        [_pageViewController setDelegate:self];
        [_pageViewController setDataSource:self];
        
        [_pageViewController setViewControllers:@[self.pages[self.index]]
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:NO
                                     completion:^(BOOL finished) {
                                         DLog(@"Finished");
                                     }];
    }
    
    return _pageViewController;
}

- (NSArray *)pages
{
    if (!_pages)
    {
        NSMutableArray *pages = [NSMutableArray array];
        
        if (![BeaconManager isBeaconReady])
        {
            _pages = @[
                       [[IneligibleDeviceViewController alloc] init]
                       ];
            return _pages;
        }
        
        if (![BeaconManager isLocationAware])
        {
            UserActionDetailViewController *locationAction = [[UserActionDetailViewController alloc]
                                                              initWithTitle:@"Location Needed"
                                                              actionLabel:@"Authorise it now"
                                                              description:@"The game needs to know how close you are to iBeacons. In order to gain this information we need you to grant the app Location Service privileges. The game is otherwise unplayable."
                                                              ];
            [locationAction setDelegate:self];
            [pages addObject:locationAction];
        }
        else
        {
            [pages addObject:[[BadgeViewController alloc ]
                              initWithBadges:[IngredientBadge badges]]
             ];
        }
        
        _pages = pages;
    }
    
    return _pages;
}

#pragma mark - UIPageViewControllerDataSource

-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController
     viewControllerBeforeViewController:(UIViewController *)viewController
{
    self.index = [self.pages indexOfObject:viewController];
    
    DLog(@"before");
    
    if (self.index == 0)
        return nil;
    
    return self.pages[self.index - 1];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController
{
    self.index = [self.pages indexOfObject:viewController];
    
    DLog(@"after");
    
    if (self.index == self.pages.count-1)
        return nil;
    
    
    
    return self.pages[self.index + 1];
}

#pragma mark - UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController
     willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    DLog(@"willTransitionToViewControllers: %@", pendingViewControllers);
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
    [self invalidatePageViewController];
}

@end
