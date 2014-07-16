//
//  BadgeConfigViewController.m
//  BiereBeacons
//
//  Created by Brenton Crowley on 16/07/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import "BadgeConfigViewController.h"

@interface BadgeConfigViewController ()

@end

@implementation BadgeConfigViewController

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
    
    [self.spottedControl setSelectedSegmentIndex:self.beacon.secondaryProximity];
    [self.gatherControl setSelectedSegmentIndex:self.beacon.primaryProximity];
    [self.foundControl setSelectedSegmentIndex:[self.beacon isFound]];
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc]
                               initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                               target:self
                               action:@selector(cancel:)];
    
    UIBarButtonItem *save = [[UIBarButtonItem alloc]
                               initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                               target:self
                               action:@selector(save:)];
    
    self.navigationItem.rightBarButtonItem = save;
    self.navigationItem.leftBarButtonItem = cancel;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)cancel:(id)sender
{
    [self.delegate badgeConfigVCDidUpdate:self beacon:nil];
}

- (void)save:(id)sender
{
    self.beacon.primaryProximity = [self
                                    proximityForControl:self.gatherControl];
    self.beacon.secondaryProximity = [self
                                      proximityForControl:self.spottedControl];

    [self.beacon setIsFound:self.foundControl.selectedSegmentIndex];
    
    [self.delegate badgeConfigVCDidUpdate:self beacon:self.beacon];
}

- (NSInteger)proximityForControl:(UISegmentedControl *)segmentedControl
{
    return segmentedControl.selectedSegmentIndex;
}

@end
