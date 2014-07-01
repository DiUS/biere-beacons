//
//  UIColor+AppColors.m
//  BiereBeacons
//
//  Created by Brenton Crowley on 30/06/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import "UIColor+AppColors.h"

@implementation UIColor (AppColors)

+ (UIColor *)appPaleBrown
{
    return [self colorWithRed:169 green:112 blue:68];
}

+ (UIColor *)appPaleYellow
{
    return [self colorWithRed:254 green:248 blue:235];
}

+ (UIColor *)colorWithRed:(CGFloat)red
                    green:(CGFloat)green
                     blue:(CGFloat)blue
{
    return [UIColor colorWithRed:(red/255.0)
                           green:(green/255.0)
                            blue:(blue/255.0)
                           alpha:1];
}

@end
