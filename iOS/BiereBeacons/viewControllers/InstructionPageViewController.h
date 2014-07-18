//
//  TutorialViewController.h
//  BiereBeacons
//
//  Created by Brenton Crowley on 17/07/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InstructionPageViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *subtitle;
@property (weak, nonatomic) IBOutlet UIImageView *imageInstruction;
@property (weak, nonatomic) IBOutlet UITextView *detailDescription;

- (instancetype)initWithPageDictionary:(NSDictionary *)dict;
- (NSDictionary *)pageDict;

@end
