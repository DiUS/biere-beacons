//
//  GatherProgressView.m
//  BiereBeacons
//
//  Created by Brenton Crowley on 10/07/2014.
//  Copyright (c) 2014 DiUS. All rights reserved.
//

#import "GatherProgressView.h"

@interface GatherProgressView()

@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UILabel *progressLabel;
@property (nonatomic) UIProgressView *progressView;
@property (nonatomic) NSArray *states;

@end

@implementation GatherProgressView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.image = [UIImage imageNamed:@"locked"];
        
        [self addSubview:_imageView];
        
        [_imageView makeConstraints:^(MASConstraintMaker *make) {
            
            make.top.equalTo(self.top);
            make.centerX.equalTo(self.centerX);
            make.width.equalTo(100.0);
            make.height.equalTo(100.0);
            
        }];
        
        _progressLabel = [[UILabel alloc] init];
        [_progressLabel setText:@"warm"];
        [_progressLabel setTextColor:[UIColor whiteColor]];
        
        [self addSubview:_progressLabel];
        
        [_progressLabel makeConstraints:^(MASConstraintMaker *make) {
            
            make.top.equalTo(_imageView.bottom).with.offset(5);
            make.centerX.equalTo(_imageView.centerX);
            
        }];
        
        _progressView = [[UIProgressView alloc]
                         initWithProgressViewStyle:UIProgressViewStyleDefault];
        
        [self addSubview:_progressView];
        
        [_progressView makeConstraints:^(MASConstraintMaker *make) {
            
            make.top.equalTo(_progressLabel.bottom).with.offset(5);
            make.centerX.equalTo(self.centerX);
            make.width.equalTo(self.width);
            
        }];
        
        [_progressView setHidden:YES];
    }
    return self;
}

- (CGSize)intrinsicContentSize
{
    CGFloat height = self.progressLabel.frame.origin.y +
                    self.progressLabel.frame.size.height +
                    10 +
                    self.progressView.frame.size.height;
    
    CGSize size = CGSizeMake(self.imageView.frame.size.width, height);
    
    return size;
}

- (void)setProgress:(CGFloat)progress
{
    progress = MIN(MAX(0, progress), 1);
    self.progressView.progress = progress;
    
    int max = (int)self.states.count;
    int index = MIN(MAX(floor(progress * max), 0), self.states.count - 1);
    
//    DLog(@"Progress: %f, index: %u", progress, index);
    
    self.progressLabel.text = self.states[index];
}

- (NSArray *)states
{
    if (!_states)
    {
        _states = @[@"Warm", @"Warmer", @"Hot"];
    }

    return _states;
    
    
    
}

@end
