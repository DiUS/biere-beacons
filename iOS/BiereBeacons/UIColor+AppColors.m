//
//  UIColor+AppColors.m
//  BiereBeacons
//
//  Created by Brenton Crowley on 30/06/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import "UIColor+AppColors.h"

@implementation UIColor (AppColors)

+ (UIColor *)appPaleBrownAlpha:(CGFloat)alpha
{
    return [self colorWithRed:169 green:112 blue:68 opacity:alpha];
}

+ (UIColor *)appPaleYellowAlpha:(CGFloat)alpha
{
    return [self colorWithRed:254 green:248 blue:235 opacity:alpha];
}

+ (UIColor *)appPaleBrown
{
    return [self appPaleBrownAlpha:1];
}

+ (UIColor *)appPaleYellow
{
    return [self appPaleYellowAlpha:1];
}

+ (UIColor *)colorWithRed:(CGFloat)red
                    green:(CGFloat)green
                     blue:(CGFloat)blue
                    opacity:(CGFloat)opacity
{
    return [UIColor colorWithRed:(red/255.0)
                           green:(green/255.0)
                            blue:(blue/255.0)
                           alpha:opacity];
}

@end
