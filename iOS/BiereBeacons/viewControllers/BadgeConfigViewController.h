//
//  BadgeConfigViewController.h
//  BiereBeacons
//
//  Created by Brenton Crowley on 16/07/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeployedBeacon+Badge.h"

@class BadgeConfigViewController;

@protocol BadgeConfigDelegate <NSObject>

- (void)badgeConfigVCDidUpdate:(BadgeConfigViewController *)vc
                        beacon:(DeployedBeacon *)beacon;

@end

@interface BadgeConfigViewController : UIViewController

@property (weak, nonatomic) IBOutlet UISegmentedControl *spottedControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *gatherControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *foundControl;

@property (weak, nonatomic) id <BadgeConfigDelegate> delegate;
@property (nonatomic) DeployedBeacon *beacon;

@end
