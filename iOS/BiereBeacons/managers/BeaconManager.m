//
//  BeaconManager.m
//  BiereBeacons
//
//  Created by Brenton Crowley on 03/07/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import "BeaconManager.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
#import "DeployedBeacon.h"
#import "DeployedBeacon+Badge.h"

@interface BeaconManager() <CBCentralManagerDelegate, CLLocationManagerDelegate>

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) CBCentralManager *centralManager;
@property (nonatomic) NSFileManager *fileManager;
@property (nonatomic) NSDictionary *deployedBeacons;

@end

@implementation BeaconManager

NSString *kTemplate = @"template";

// File handling
NSString *kDocumentName = @"beacons";
NSString *kDocumentExtension = @".plist";
NSString *kUUIDKey = @"uuid";
NSString *kMajorKey = @"major";
NSString *kMinorKey = @"minor";
//NSString *kIsFoundKey = @"isFound";
NSString *kNameKey = @"name";
NSString *kTypeKey = @"type";
NSString *kPrimaryProximityKey = @"primaryProximity";
NSString *kSecondaryProximityKey = @"secondaryProximity";
NSString *kMeasuredPower = @"measuredPower";
NSString *kImageNamesKey = @"imageNames";
NSString *kCustomPropertiesKey = @"customProperties";

NSString *kLocationAuthorisationChange = @"LocationAuthorisationChange";

#pragma mark - Class Public API

+ (id)sharedInstance
{
    static BeaconManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}


+ (void)requestAuthorisation
{
    BeaconManager *manager = [BeaconManager sharedInstance];
    if (![BeaconManager isLocationAware])
    {
        switch ([CLLocationManager authorizationStatus])
        {
            case kCLAuthorizationStatusNotDetermined:
            {
                if ([manager.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
                {
                    [manager.locationManager requestAlwaysAuthorization];
                    DLog(@"ios 8");
                } else {
                    [manager.locationManager startUpdatingLocation];
                    DLog(@"ios 7");
                }
                break;
            }
            default:
                
                [[[UIAlertView alloc]
                 initWithTitle:@"Location already denied."
                 message:@"This isn't the first time we've requested access. You'll need to authorise this app for location updates in the Settings app."
                 delegate:nil
                 cancelButtonTitle:@"Okay"
                 otherButtonTitles:nil] show];
                
                break;
        }
        
    }
    else
    {
        [[BeaconManager sharedInstance] locationManager:manager.locationManager
       didChangeAuthorizationStatus:[CLLocationManager authorizationStatus]];
    }
}

+ (BOOL)isLocationAware
{
    if ([CLLocationManager locationServicesEnabled] &&
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized)
    {
        return YES;
    }
    
    return NO;
}

+ (BOOL)isBeaconReady
{
    if (![CLLocationManager
          isMonitoringAvailableForClass:[CLBeaconRegion class]] ||
        ![CLLocationManager isRangingAvailable])
    {
        return NO;
    }
    
    return YES;
}

+ (NSArray *)deployedBeacons
{
    NSSortDescriptor *sortDesc = [[NSSortDescriptor alloc]
                                  initWithKey:@"name"
                                  ascending:YES];
    
    return [[[[BeaconManager sharedInstance]
              deployedBeacons]
             allValues] sortedArrayUsingDescriptors:@[sortDesc]];
}

+ (void)writeBeaconsToFile
{
    [[BeaconManager sharedInstance]
     writeBeacons:[BeaconManager deployedBeacons]];
}

#pragma mark - Instance Public API

#pragma mark - Private API

-(CLLocationManager *)locationManager
{
    if (!_locationManager)
    {
        _locationManager = [[CLLocationManager alloc] init];
        [_locationManager setDelegate:[BeaconManager sharedInstance]];
    }
    
    return _locationManager;
}

- (CBCentralManager *)centralManager
{
    if (!_centralManager)
    {
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:NO],
                                 CBCentralManagerOptionShowPowerAlertKey, nil
                                 ];
        _centralManager = [[CBCentralManager alloc ]
                           initWithDelegate:self
                           queue:dispatch_get_main_queue()
                           options:options];

        [self centralManagerDidUpdateState:_centralManager];
    }
    
    return _centralManager;
}

- (NSDictionary *)deployedBeacons
{
    if (!_deployedBeacons)
    {
        BeaconManager *manager = [BeaconManager  sharedInstance];
        NSMutableDictionary *beacons = [NSMutableDictionary dictionary];

        // load from url
        NSArray *documentBeacons = [[NSArray alloc]
                                   initWithContentsOfFile:[self documentPath]];
        
        // First launch. Load from bundle plist
        BOOL needsWrite = NO;
        if (!documentBeacons)
        {
            NSString *bundlePath = [[NSBundle mainBundle]
                                    pathForResource:kDocumentName
                                    ofType:kDocumentExtension];
            
            documentBeacons = [[NSArray alloc]
                                         initWithContentsOfFile:bundlePath];
            needsWrite = YES;
        }
        
        for (NSDictionary *dict in documentBeacons)
        {
            DeployedBeacon *beacon = [manager beaconForDictionary:dict];
            NSString *key = [BeaconManager keyForUUID:beacon.uuid
                                              major:beacon.major
                                              minor:beacon.minor
                             ];
            beacons[key] = beacon;
        }
        
        if (needsWrite)
            [manager writeBeacons:[beacons allValues]];
        
        _deployedBeacons = beacons;
    }
    
    return _deployedBeacons;
}

+ (DeployedBeacon *)deployedBeaconForKey:(NSString *)key
{
    BeaconManager *manager = [BeaconManager sharedInstance];

    return manager.deployedBeacons[key];
}

+ (NSString *)keyForUUID:(NSString *)uuid
                   major:(NSInteger)major
                   minor:(NSInteger)minor
{
    NSString *key = [NSString stringWithFormat:@"%@%ld%ld",
                     uuid,
                     (long)major,
                     (long)minor];
    
    return key;
}

#pragma mark - File Handling

- (NSFileManager *)fileManager
{
    if (!_fileManager)
        _fileManager = [[NSFileManager alloc] init];
    
    return _fileManager;
}

- (NSString *)documentPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *document = nil;
    
    if ([paths count] > 0)
    {
        
        document = [[paths objectAtIndex:0]
                    stringByAppendingPathComponent:
                    [NSString stringWithFormat:@"%@%@",
                     kDocumentName,
                     kDocumentExtension]
                    ];
    }
    else
        NSLog(@"Could not find the Documents folder.");
    
    return document;
}

- (DeployedBeacon *)beaconForDictionary:(NSDictionary *)dictionary
{
    // will need to alloc init according to the `type`
    DeployedBeacon *beacon = [[DeployedBeacon alloc]
                              initWithName:dictionary[kNameKey]];

    beacon.uuid = [dictionary[kUUIDKey] uppercaseString];
    beacon.major = ((NSNumber *)dictionary[kMajorKey]).integerValue;
    beacon.minor = ((NSNumber *)dictionary[kMinorKey]).integerValue;
    beacon.measuredPower = ((NSNumber *)dictionary[kMeasuredPower]).integerValue;
    beacon.primaryProximity = ((NSNumber *)dictionary[kPrimaryProximityKey]).integerValue;
    beacon.secondaryProximity = ((NSNumber *)dictionary[kSecondaryProximityKey]).integerValue;
    beacon.type = dictionary[kTypeKey];
    beacon.imageNames = dictionary[kImageNamesKey] ? dictionary[kImageNamesKey] : @[];
    beacon.customProperties = dictionary[kCustomPropertiesKey] ? dictionary[kCustomPropertiesKey] : @{};
    
    beacon.findStatus = [beacon isFound] ? FindStatusFound : FindStatusUnknown;
    
    return beacon;
}

- (NSDictionary *)dictionaryForDeployedBeacon:(DeployedBeacon *)beacon
{
    NSDictionary *dict = @{kNameKey: beacon.name,
                           kTypeKey: beacon.type,
                           kImageNamesKey: beacon.imageNames,
                           kCustomPropertiesKey: beacon.customProperties,
                           kUUIDKey: beacon.uuid,
                           kMajorKey: [NSNumber numberWithInteger:beacon.major],
                           kMinorKey: [NSNumber numberWithInteger:beacon.minor],
                           kPrimaryProximityKey: [NSNumber numberWithInteger:beacon.primaryProximity],
                           kSecondaryProximityKey: [NSNumber numberWithInteger:beacon.secondaryProximity],
                           kMeasuredPower: [NSNumber numberWithInteger:beacon.measuredPower],
                           };
    
    return dict;
}

- (void)writeBeacons:(NSArray *)beacons
{
    NSMutableArray *dictBeacons = [NSMutableArray array];
    
    for (DeployedBeacon *beacon in beacons)
        [dictBeacons addObject:[self dictionaryForDeployedBeacon:beacon]];
    
    NSString *error;
    NSData *beaconData = [NSPropertyListSerialization
                         dataFromPropertyList:dictBeacons
                         format:NSPropertyListXMLFormat_v1_0
                         errorDescription:&error];
    if(beaconData)
    {
        [beaconData writeToFile:[[BeaconManager sharedInstance] documentPath]
                    atomically:YES];
    }
    else {
        DLog(@"Error: %@", error);
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSNotification *n = [NSNotification
                        notificationWithName:kLocationAuthorisationChange
                        object:self];
    
    [[NSNotificationCenter defaultCenter] postNotification:n];
    DLog(@"Authorisation did change: %i", status);
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    [manager stopUpdatingLocation];
}

@end
