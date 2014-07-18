//
//  InstructionsViewController.h
//  BiereBeacons
//
//  Created by Brenton Crowley on 17/07/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import <UIKit/UIKit.h>

@class InstructionsViewController;

@protocol InstructionsViewControllerDelegate <NSObject>

- (void)instructionsDidClose:(InstructionsViewController *)controller;

@end

@interface InstructionsViewController : UIPageViewController

@property (weak, nonatomic) id <InstructionsViewControllerDelegate> instructionsDelegate;

@end
