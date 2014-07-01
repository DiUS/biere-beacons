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

- (void)ingredientBadgeDidSpotBadge:(IngredientBadge *)badge;
- (void)ingredientBadgeDidStartGathering:(IngredientBadge *)badge;
- (void)ingredientBadge:(IngredientBadge *)badge
      didUpdateLogCount:(int)logCount;
- (void)ingredientBadgeDidFindBadge:(IngredientBadge *)badge;
- (void)ingredientBadgeDidTimeout:(IngredientBadge *)badge;
- (void)ingredientBadgeDidExitBadgeArea:(IngredientBadge *)badge;

@end

typedef enum {
	
	FindStatusUnknown,
    FindStatusSpotted,
    FindStatusGatherReady,
    FindStatusGathering,
    FindStatusGatherTimeout,
    FindStatusLost,
    FindStatusFound
    
} BadgeFindStatus;

@interface IngredientBadge : NSObject

extern const int kNumSuccessiveLogs;
extern const double kGameThreadDuration;
extern NSString *kFirstRun;

@property (nonatomic) NSString *name;
@property (nonatomic) BOOL isFound;
@property (nonatomic) NSString *imageURL;

// Beacon Association
@property (nonatomic) NSString *uuid;
@property (nonatomic) NSInteger major;
@property (nonatomic) NSInteger minor;
@property (nonatomic) BadgeFindStatus findStatus;
@property (nonatomic, weak) id <IngredientBadgeDelegate> delegate;

+ (NSArray *)badges;
+ (void)writeBadges;

- (id)initWithName:(NSString *)name;
- (void)updateLogCount;
- (void)logBadgeAsFound;

@end
