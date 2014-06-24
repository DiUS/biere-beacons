//
//  BadgeViewController.h
//  BiereBeacons
//
//  Created by Brenton Crowley on 24/06/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BadgeViewController : UICollectionViewController <
UICollectionViewDataSource, UICollectionViewDelegate>

- (id)initWithBadges:(NSArray *)badges;

@end
