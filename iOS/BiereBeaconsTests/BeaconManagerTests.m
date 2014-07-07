//
//  BeaconManagerTests.m
//  BiereBeacons
//
//  Created by Brenton Crowley on 03/07/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BeaconManager.h"

@interface BeaconManagerTests : XCTestCase

@property (nonatomic) BeaconManager *beaconManager;

@end

@implementation BeaconManagerTests

- (void)setUp
{
    [super setUp];
    
    self.beaconManager = [BeaconManager sharedInstance];
}

- (void)tearDown
{
    self.beaconManager = nil;
    
    [super tearDown];
}

- (void)testExample
{
    [BeaconManager requestAuthorisation];
    
    NSAssert(YES, @"Should be YES, but no");
}

@end
