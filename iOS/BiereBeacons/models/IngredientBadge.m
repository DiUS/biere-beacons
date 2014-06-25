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
int const kNumSuccessiveLogs = 10;

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

- (IngredientBadge *)badgeForDictionary:(NSDictionary *)dictionary
{
    IngredientBadge *badge = [[IngredientBadge alloc]
                              initWithName:dictionary[kNameKey]];
    badge.imageURL = dictionary[kImageURLKey];
    badge.uuid = [dictionary[kUUIDKey] uppercaseString];
    badge.major = ((NSNumber *)dictionary[kMajorKey]).integerValue;
    badge.minor = ((NSNumber *)dictionary[kMinorKey]).integerValue;
    badge.isFound = ((NSNumber *)dictionary[kIsFoundKey]).boolValue;
    
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

+ (void)writeBadges
{
    IngredientBadge *instance = [IngredientBadge sharedInstance];

    [[IngredientBadge sharedInstance] writeBadges:[instance badges]];
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


- (void)updateCaptureCount
{
    
    [self stopTimeoutTimer];

    switch (self.logCount)
    {
        case kNumSuccessiveLogs:
            self.isFound = YES;
            // TODO: delegate callback for success
            [self.delegate ingredientBadgeDidFindBadge:self];
            // TODO: write badges
            [self stopTimeoutTimer];
            [IngredientBadge writeBadges];
            break;
        case 0:
            // TODO: notify delegate did start.
            [self.delegate ingredientBadgeDidStartLogging:self];
       
        default:
            self.logCount += 1;
            // TODO: notify delegate update
            [self.delegate ingredientBadge:self
                         didUpdateLogCount:self.logCount];
            
            // Every time there is an update restart the timeout.
            self.logTimout = [NSTimer
                              scheduledTimerWithTimeInterval:3.0
                              target:self
                              selector:@selector(onLogTimedOut:)
                              userInfo:nil
                              repeats:NO
                              ];
            
            break;
    }
    
}

- (void)onLogTimedOut:(NSTimer *)timer
{
    [self stopTimeoutTimer];
    
    // TODO: tell delegate that timed out
    [self.delegate ingredientBadgeDidTimeout:self];
    self.logCount = 0;
}

- (void)stopTimeoutTimer
{
    if (self.logTimout)
    {
        [self.logTimout invalidate];
        self.logTimout = nil;
    }
}

@end
