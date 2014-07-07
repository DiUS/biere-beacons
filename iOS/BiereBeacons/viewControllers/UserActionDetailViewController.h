//
//  UserActionDetailViewController.h
//  BiereBeacons
//
//  Created by Brenton Crowley on 04/07/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UserActionDetailViewController;

@protocol UserActionDetailDelegate <NSObject>

- (void)userActionDetailVC:(UserActionDetailViewController *)vc didPress:(id)sender;

@end

@interface UserActionDetailViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@property (weak, nonatomic) id <UserActionDetailDelegate> delegate;

- (id)initWithTitle:(NSString *)title
        actionLabel:(NSString *)actionLabelText
        description:(NSString *)description;

@end
