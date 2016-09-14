//
//  HCDProgressView.m
//  HCDCamera
//
//  Created by cheaterhu on 16/9/13.
//  Copyright © 2016年 hcd. All rights reserved.
//

#import "HCDProgressView.h"

@interface HCDProgressView ()
@property (nonatomic) CGFloat progress;
@property (nonatomic, strong) UIView *progressView;
@end

@implementation HCDProgressView

- (instancetype)init
{
    if (self = [super init]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit{

    self.progress = 0.0;
    self.backgroundColor = [UIColor blackColor] /*[UIColor colorWithRGBIntegerString:@"222-218-223"]*/;
    
    self.progressView = [[UIView alloc] init];
    self.progressView.backgroundColor = [UIColor whiteColor]/*[UIColor colorWithRGBIntegerString:@"207-173-154"]*/;
    [self addSubview:self.progressView];
    
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left);
        make.top.equalTo(self.mas_top);
        make.height.equalTo(self.mas_height);
        make.width.equalTo(self.mas_width).multipliedBy(self.progress);
    }];
}

-(void)setMyProgress:(CGFloat)progress
{
    self.progress = progress;
    
    if (self.progress > 1.0) {
        self.progress = 1.0;
    }
    
    HCDLog(@"=======%f",self.progress);
    
    [self.progressView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left);
        make.top.equalTo(self.mas_top);
        make.height.equalTo(self.mas_height);
        make.width.equalTo(self.mas_width).multipliedBy(self.progress);
    }];
}

@end
