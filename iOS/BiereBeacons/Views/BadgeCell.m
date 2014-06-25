//
//  BadgeCell.m
//  BiereBeacons
//
//  Created by Brenton Crowley on 24/06/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import "BadgeCell.h"

@implementation BadgeCell

double kCellSize = 144.0;

NSString const *kBadgeCellID = @"BadgeCell";

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (UIImageView *)badgeView
{
    if (!_badgeView)
    {
        CGRect frame = CGRectMake(0.0, 0.0, kCellSize, kCellSize);
        _badgeView = [[UIImageView alloc] initWithFrame:frame];
        
        [self addSubview:_badgeView];
    }
    
    return _badgeView;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
