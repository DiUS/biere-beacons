//
//  IngredientBadge.h
//  BiereBeacons
//
//  Created by Brenton Crowley on 24/06/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IngredientBadge : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) BOOL isFound;
@property (nonatomic) NSString *imageURL;

- (id)initWithName:(NSString *)name;

@end
