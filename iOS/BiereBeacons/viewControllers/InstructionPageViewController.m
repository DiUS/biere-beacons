//
//  TutorialViewController.m
//  BiereBeacons
//
//  Created by Brenton Crowley on 17/07/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import "InstructionPageViewController.h"

@interface InstructionPageViewController ()

@property (nonatomic) NSDictionary *pageDict;

@end

@implementation InstructionPageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (instancetype)initWithPageDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        _pageDict = dict;
        
        self.title = _pageDict[@"title"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.pageDict[@"title"];
    self.subtitle.text = self.pageDict[@"subtitle"];
    self.imageInstruction.image = [UIImage
                                   imageNamed:self.pageDict[@"imageInstructionName"]];
    self.detailDescription.text = self.pageDict[@"detailDescription"];
    self.detailDescription.editable = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSDictionary *)pageDict
{
    return _pageDict;
}

@end
