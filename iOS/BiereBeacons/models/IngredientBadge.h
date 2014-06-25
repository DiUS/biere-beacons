//
//  IngredientBadge.h
//  BiereBeacons
//
//  Created by Brenton Crowley on 24/06/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IngredientBadge;

@protocol IngredientBadgeDelegate <NSObject>

- (void)ingredientBadgeDidStartLogging:(IngredientBadge *)badge;
- (void)ingredientBadge:(IngredientBadge *)badge
      didUpdateLogCount:(int)logCount;
- (void)ingredientBadgeDidFindBadge:(IngredientBadge *)badge;
- (void)ingredientBadgeDidTimeout:(IngredientBadge *)badge;

@end

@interface IngredientBadge : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) BOOL isFound;
@property (nonatomic) NSString *imageURL;

// Beacon Association
@property (nonatomic) NSString *uuid;
@property (nonatomic) NSInteger major;
@property (nonatomic) NSInteger minor;
@property (nonatomic, weak) id <IngredientBadgeDelegate> delegate;

+ (NSArray *)badges;
+ (void)writeBadges;

- (id)initWithName:(NSString *)name;
- (void)updateCaptureCount;

@end
