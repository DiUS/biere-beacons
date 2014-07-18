//
//  InstructionsViewController.m
//  BiereBeacons
//
//  Created by Brenton Crowley on 17/07/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import "InstructionsViewController.h"
#import "InstructionPageViewController.h"
#import "UIColor+AppColors.h"

@interface InstructionsViewController () <UIPageViewControllerDataSource,
UIPageViewControllerDelegate>

@property (nonatomic) NSArray *pages;

@end

@implementation InstructionsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;    
    
    UIBarButtonItem *close = [[UIBarButtonItem alloc]
                              initWithTitle:@"Close"
                              style:UIBarButtonItemStyleDone
                              target:self
                              action:@selector(close)];
    
    self.navigationItem.rightBarButtonItem = close;
    
    self.view.backgroundColor = [UIColor appPaleYellow];
    
    self.delegate = self;
    self.dataSource = self;

    InstructionPageViewController *vc = [[InstructionPageViewController alloc]
                                         initWithPageDictionary:[self.pages
                                                                 firstObject]
                                         ];
    
    [self setViewControllers:@[vc]
                   direction:UIPageViewControllerNavigationDirectionForward
                    animated:NO
                  completion:nil];
    
    [self invalidate];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSArray *)pages
{
    if (!_pages)
    {
        NSString *bundlePath = [[NSBundle mainBundle]
                                pathForResource:@"tutorial"
                                ofType:@"plist"];
        
        NSArray *pages = [[NSArray alloc]
                           initWithContentsOfFile:bundlePath];
        
        _pages = pages;
    }
    
    return _pages;
}

- (void)invalidate
{
    InstructionPageViewController *vc = [self.viewControllers firstObject];
    self.title = vc.title;
}

- (void)close
{
    [self.instructionsDelegate instructionsDidClose:self];
}

#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController
{
    
    InstructionPageViewController *currentPage =
    (InstructionPageViewController *)viewController;
    
    NSInteger currentIndex = [self.pages indexOfObject:[currentPage pageDict]];
    
    if (currentIndex == 0)
        return nil;
    
    currentIndex--;
    
    InstructionPageViewController *vc = [[InstructionPageViewController alloc]
                                         initWithPageDictionary:self.pages[currentIndex]
                                         ];
    return vc;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController
{
    InstructionPageViewController *currentPage =
    (InstructionPageViewController *)viewController;
    
    NSInteger currentIndex = [self.pages indexOfObject:[currentPage pageDict]];
    
    if (currentIndex == self.pages.count - 1)
        return nil;
    
    currentIndex++;
    
    InstructionPageViewController *vc = [[InstructionPageViewController alloc]
                                         initWithPageDictionary:self.pages[currentIndex]
                                         ];
    
    return vc;
}

- (void)pageViewController:(UIPageViewController *)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray *)previousViewControllers
       transitionCompleted:(BOOL)completed
{
    [self invalidate];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return self.pages.count;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    InstructionPageViewController *currentPage =
    (InstructionPageViewController *)[pageViewController.viewControllers firstObject];
    
    NSInteger currentIndex = [self.pages indexOfObject:[currentPage pageDict]];

    return currentIndex;
}


@end
