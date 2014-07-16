//
//  UserActionDetailViewController.m
//  BiereBeacons
//
//  Created by Brenton Crowley on 04/07/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import "UserActionDetailViewController.h"

@interface UserActionDetailViewController ()

@property (nonatomic) NSString *actionDetailText;
@property (nonatomic) NSString *descriptionText;

@end

@implementation UserActionDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithTitle:(NSString *)title
        actionLabel:(NSString *)actionLabelText
        description:(NSString *)description
{
    if ((self = [super init]))
    {
        _actionDetailText = actionLabelText;
        _descriptionText = description;
        self.title = title;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.actionButton setTitle:self.actionDetailText
                   forState:UIControlStateNormal
     ];
    
    self.textView.text = self.descriptionText;
    self.textView.selectable = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didPressAction:(id)sender
{
    [self.delegate userActionDetailVC:self didPress:sender];
}
@end
