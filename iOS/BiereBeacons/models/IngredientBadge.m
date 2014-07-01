//
//  IngredientBadge.m
//  BiereBeacons
//
//  Created by Brenton Crowley on 24/06/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import "IngredientBadge.h"

@interface IngredientBadge()

@property (nonatomic) NSFileManager *fileManager;
@property (nonatomic) NSArray *badges;
@property (nonatomic) NSTimer *logTimout;
@property (nonatomic) int logCount;

@end

@implementation IngredientBadge

NSString * const kDocumentName = @"badges";
NSString * const kDocumentExtension = @".plist";
NSString * const kUUIDKey = @"uuid";
NSString * const kMajorKey = @"major";
NSString * const kMinorKey = @"minor";
NSString * const kIsFoundKey = @"isFound";
NSString * const kNameKey = @"name";
NSString * const kImageURLKey = @"imageURL";
NSString const *kFirstRun = @"firstRun";
int const kNumSuccessiveLogs = 10;
//int const kGatherStartDelay = 3;
double const kGameThreadDuration = 0.5;
double const kGatherTimeoutDuration = 2.0;

#pragma mark - Public API

+ (id)sharedInstance
{
    static IngredientBadge *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (NSArray *)badges
{
    return [[IngredientBadge sharedInstance] badges];
}

+ (void)writeBadges
{
    IngredientBadge *instance = [IngredientBadge sharedInstance];
    
    [[IngredientBadge sharedInstance] writeBadges:[instance badges]];
}

- (id)initWithName:(NSString *)name
{
    if ((self = [super init]))
    {
        _name = name;
    }
    
    return self;
}

- (BadgeFindStatus)badgeFindStatus
{
    return self.findStatus;
}

- (void)setFindStatus:(BadgeFindStatus)findStatus
{
    _findStatus = findStatus;
    
    switch (_findStatus)
    {
        case FindStatusUnknown:
            
            [self stopGatherTimeout];
            
            break;
            
        case FindStatusSpotted:
            
            [self.delegate ingredientBadgeDidSpotBadge:self];
            self.findStatus = FindStatusGatherReady;
            
            break;
            
        case FindStatusGatherReady:
            
            self.logCount = 0;
            
            break;
            
        case FindStatusGathering:
            
            [self.delegate ingredientBadgeDidStartGathering:self];
            
            break;
            
        case FindStatusGatherTimeout:
            
            [self.delegate ingredientBadgeDidTimeout:self];
            self.findStatus = FindStatusGatherReady;
            
            break;
            
        case FindStatusFound:
            
            [self.delegate ingredientBadgeDidFindBadge:self];
            
            break;
            
        case FindStatusLost:
            
            [self.delegate ingredientBadgeDidExitBadgeArea:self];
            self.findStatus = FindStatusUnknown;
            
            break;
            
        default:
            break;
    }
}

- (void)updateLogCount
{
    [self stopGatherTimeout];
    [self startGatherTimeout];
    
    // increment logCount
    self.logCount += 1;
    [self.delegate ingredientBadge:self
                 didUpdateLogCount:self.logCount];
    // if log count == kNumSuccessiveLogs, then set to found
    if (self.logCount == (int)(kNumSuccessiveLogs / kGameThreadDuration))
    {
        self.findStatus = FindStatusFound;
        
        [self logBadgeAsFound];
        [self stopGatherTimeout];
    }
    
    DLog(@"Update Log Count - State: %d", self.findStatus);
}


#pragma mark - Private

- (NSArray *)badges
{
    if (!_badges)
    {
        NSMutableArray *badges = [NSMutableArray array];
        // load from url
        NSArray *documentBadges = [[NSArray alloc]
                                  initWithContentsOfFile:[self documentPath]];

        // First launch. Load from bundle plist
        if (!documentBadges)
        {
            NSString *bundlePath = [[NSBundle mainBundle]
                                        pathForResource:kDocumentName
                                        ofType:kDocumentExtension];
            
            NSArray *bundleDictBadges = [[NSArray alloc]
                                    initWithContentsOfFile:bundlePath];
            
            for (NSDictionary *dict in bundleDictBadges)
                [badges addObject:[self badgeForDictionary:dict]];
            
            [[IngredientBadge sharedInstance] writeBadges:badges];
            
            documentBadges = [[NSArray alloc]
                             initWithContentsOfFile:[self documentPath]];
        }
        
        if (!badges.count)
        {
            for (NSDictionary *dict in documentBadges)
                [badges addObject:[self badgeForDictionary:dict]];
        }
        
        _badges = badges;
    }
    
    return _badges;
}

- (NSString *)imageURL
{
    if (!_imageURL)
    {
        _imageURL = self.name;
    }
    
    return _imageURL;
}

- (void)setIsFound:(BOOL)isFound
{
    _isFound = isFound;
    
    self.findStatus = _isFound ? FindStatusFound : FindStatusUnknown;
}

- (void)logBadgeAsFound
{
    self.isFound = YES;
    [self.delegate ingredientBadgeDidFindBadge:self];
    [IngredientBadge writeBadges];
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

- (IngredientBadge *)badgeForDictionary:(NSDictionary *)dictionary
{
    IngredientBadge *badge = [[IngredientBadge alloc]
                              initWithName:dictionary[kNameKey]];
    badge.imageURL = dictionary[kImageURLKey];
    badge.uuid = [dictionary[kUUIDKey] uppercaseString];
    badge.major = ((NSNumber *)dictionary[kMajorKey]).integerValue;
    badge.minor = ((NSNumber *)dictionary[kMinorKey]).integerValue;
    badge.isFound = ((NSNumber *)dictionary[kIsFoundKey]).boolValue;
    
    badge.findStatus = badge.isFound ? FindStatusFound : FindStatusUnknown;
    
    return badge;
}

- (NSDictionary *)dictionaryForBadge:(IngredientBadge *)badge
{
    NSDictionary *dict = @{kNameKey: badge.name,
                           kImageURLKey: badge.imageURL,
                           kIsFoundKey: [NSNumber numberWithBool:badge.isFound],
                           kUUIDKey: badge.uuid,
                           kMajorKey: [NSNumber numberWithInteger:badge.major],
                           kMinorKey: [NSNumber numberWithInteger:badge.minor]
                           };
    
    return dict;
}

- (void)writeBadges:(NSArray *)badges
{
    NSMutableArray *dictBadges = [NSMutableArray array];
    
    for (IngredientBadge *badge in badges)
        [dictBadges addObject:[self dictionaryForBadge:badge]];
    
    NSString *error;
    NSData *badgeData = [NSPropertyListSerialization
                         dataFromPropertyList:dictBadges
                         format:NSPropertyListXMLFormat_v1_0
                         errorDescription:&error];
    if(badgeData)
    {
        [badgeData writeToFile:[[IngredientBadge sharedInstance] documentPath]
                    atomically:YES];
    }
    else {
        DLog(@"Error: %@", error);
    }
}

#pragma mark Timer

- (void)startGatherTimeout
{
    [self stopGatherTimeout];
    
    self.logTimout = [NSTimer
                      scheduledTimerWithTimeInterval:kGatherTimeoutDuration
                      target:self
                      selector:@selector(onLogTimedOut:)
                      userInfo:nil
                      repeats:NO
                      ];
}

- (void)stopGatherTimeout
{
    if (self.logTimout)
    {
        [self.logTimout invalidate];
        self.logTimout = nil;
    }
}

- (void)onLogTimedOut:(NSTimer *)timer
{
    [self stopGatherTimeout];
    
    self.findStatus = FindStatusGatherTimeout;
}

@end
