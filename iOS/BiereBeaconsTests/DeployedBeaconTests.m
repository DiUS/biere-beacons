//
//  DeployedBeaconTests.m
//  BiereBeacons
//
//  Created by Brenton Crowley on 14/07/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "DeployedBeacon.h"

@interface DeployedBeaconTests : XCTestCase

@property (nonatomic) DeployedBeacon *beacon;

@end

@implementation DeployedBeaconTests

- (void)setUp
{
    [super setUp];
    self.beacon = [[DeployedBeacon alloc] initWithName:@"Test"];
}

- (void)tearDown
{
    self.beacon = nil;
    [super tearDown];
}

- (void)testExample
{
    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

@end
