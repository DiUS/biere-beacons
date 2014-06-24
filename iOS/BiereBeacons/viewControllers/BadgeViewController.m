//
//  BadgeViewController.m
//  BiereBeacons
//
//  Created by Brenton Crowley on 24/06/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import "BadgeViewController.h"
#import "IngredientBadge.h"
#import "BadgeCell.h"

@interface BadgeViewController ()

@property (nonatomic) NSArray *badges;

@end

static NSString *kLockedBadgedImageName = @"locked";
static float kInset = 8.0f;

@implementation BadgeViewController

- (id)initWithBadges:(NSArray *)badges
{
    UICollectionViewFlowLayout *layout = [
                                      [UICollectionViewFlowLayout alloc] init];
    
    layout.minimumInteritemSpacing = layout.minimumLineSpacing = kInset;
    layout.itemSize = CGSizeMake(kCellSize, kCellSize);
    layout.sectionInset = UIEdgeInsetsMake(kInset, kInset, kInset, kInset);
    
    if ((self = [super initWithCollectionViewLayout:layout]))
    {
        _badges = badges;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.collectionView registerClass:[BadgeCell class]
            forCellWithReuseIdentifier:kBadgeCellID];
    
    self.collectionView.backgroundColor = [UIColor colorWithWhite:(70.0/255.0) alpha:1.0];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    return self.badges.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    BadgeCell *cell = [collectionView
                  dequeueReusableCellWithReuseIdentifier:kBadgeCellID
                                  forIndexPath:indexPath];
    
    if (!cell)
    {
        cell = [[BadgeCell alloc]
                initWithFrame:CGRectMake(0.0,
                                         0.0,
                                         kCellSize,
                                         kCellSize)];
        
    }
    
    IngredientBadge *badge = self.badges[indexPath.row];
    
    NSString *imageName = nil;
    
    if (badge.isFound)
        imageName = [badge.imageURL lowercaseString];
    else
        imageName = kLockedBadgedImageName;
    
    cell.badgeView.image = [UIImage imageNamed:imageName];
    
    DLog(@"Name: %@", badge.name);
    
    return cell;
}

#pragma mark - UICollectionViewDelegate



@end
