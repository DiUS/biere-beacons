//
//  BeaconManagerTests.m
//  BiereBeacons
//
//  Created by Brenton Crowley on 09/07/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BeaconManager.h"

@interface BeaconManagerTests : XCTestCase

@property (nonatomic) BeaconManager *manager;

@end

@implementation BeaconManagerTests

- (void)setUp
{
    [super setUp];
    self.manager = [BeaconManager sharedInstance];
}

- (void)tearDown
{
    self.manager = nil;
    [super tearDown];
}

- (void)testDeployedBeaconsFromFile
{
    NSArray *beacons = [BeaconManager deployedBeacons];
    
    XCTAssertNotNil(beacons, @"Beacons are nil when they shouldn't be.");
}

- (void)testFilterBadgesFromDeployedBeacons
{
    NSArray *beacons = [BeaconManager deployedBeacons];
    NSArray *badges = nil;
    NSPredicate *badgePredicate = [NSPredicate predicateWithFormat:@"type = 'badge'"];
    
    badges = [beacons filteredArrayUsingPredicate:badgePredicate];
    
    XCTAssertTrue(badges.count == 4, @"Badge count should be 4, but is not.");
}

@end
