//
//  IngredientBadge.m
//  BiereBeacons
//
//  Created by Brenton Crowley on 24/06/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import "IngredientBadge.h"

@implementation IngredientBadge

- (id)initWithName:(NSString *)name
{
    if ((self = [super init]))
    {
        _name = name;
    }
    
    return self;
}

- (NSString *)imageURL
{
    if (!_imageURL)
    {
        _imageURL = self.name;
    }
    
    return _imageURL;
}

@end
