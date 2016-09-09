//
//  HCDIndicatorView.m
//  HCDCamera
//
//  Created by cheaterhu on 16/9/7.
//  Copyright © 2016年 hcd. All rights reserved.
//

#import "HCDIndicatorView.h"
#import "UIColor+HexString.h"

#ifndef kScreenWidth
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#endif

#define kWidth kScreenWidth * 0.45
#define kProgressWidth 14.0

@interface HCDIndicatorView ()<UIAlertViewDelegate>
{
    CGFloat progress;
}
@property (nonatomic, strong) CAShapeLayer *shapeLayer;
@property (nonatomic, strong) CAGradientLayer *gradientLayer1;
@property (nonatomic, strong) CAGradientLayer *gradientLayer2;
@property (nonatomic, strong) CALayer *colorLayer;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, copy) void (^completeHandler)();
@end

@implementation HCDIndicatorView

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
    
    progress = 0.0;
    self.frame = CGRectMake(0, 0, kWidth, kWidth);

    self.colorLayer = [CALayer layer];
    self.colorLayer.frame = self.bounds;
    
    // d = self.bounds.size.width * 0.78
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:self.center radius:kWidth *0.58 *0.5 startAngle:-M_PI*0.5 endAngle:M_PI * 0.4999+M_PI clockwise:YES];
    
    CAShapeLayer *progressBackLayer = [CAShapeLayer layer];
    
    progressBackLayer.fillColor = [UIColor clearColor].CGColor;
    progressBackLayer.frame = self.bounds;
    progressBackLayer.lineWidth = kProgressWidth;
    progressBackLayer.strokeColor = [[UIColor grayColor] CGColor];
    progressBackLayer.opacity = 0.25;
    progressBackLayer.path = path.CGPath;
    [self.layer addSublayer:progressBackLayer];
    
    self.shapeLayer = [CAShapeLayer layer];
    self.shapeLayer.frame = self.bounds;
    self.shapeLayer.lineWidth = kProgressWidth;
    self.shapeLayer.fillColor = [UIColor clearColor].CGColor;
    self.shapeLayer.strokeColor = [UIColor yellowColor].CGColor;
    self.shapeLayer.path = path.CGPath;
    self.shapeLayer.strokeEnd = 0.0;
    
    
    self.gradientLayer1 =  [CAGradientLayer layer];
    self.gradientLayer1.frame = CGRectMake(0, 0, self.bounds.size.width/2, self.bounds.size.height);
    [self.gradientLayer1 setColors:[NSArray arrayWithObjects:(id)[[UIColor redColor] CGColor],(id)[[UIColor colorWithHexString:@"fde802"] CGColor], nil]];
    [self.gradientLayer1 setLocations:@[@0.5,@0.9,@1 ]];
    [self.gradientLayer1 setStartPoint:CGPointMake(0.5, 1)];
    [self.gradientLayer1 setEndPoint:CGPointMake(0.5, 0)];
    [self.colorLayer addSublayer:self.gradientLayer1];
    
    self.gradientLayer2 =  [CAGradientLayer layer];
    [self.gradientLayer2 setLocations:@[@0.1,@0.5,@1]];
    self.gradientLayer2.frame = CGRectMake(self.bounds.size.width/2, 0, self.bounds.size.width/2, self.bounds.size.height);
    [self.gradientLayer2 setColors:[NSArray arrayWithObjects:(id)[[UIColor colorWithHexString:@"fde802"] CGColor],(id)[[UIColor blueColor] CGColor], nil]];
    [self.gradientLayer2 setStartPoint:CGPointMake(0.5, 0)];
    [self.gradientLayer2 setEndPoint:CGPointMake(0.5, 1)];
    [self.colorLayer addSublayer:self.gradientLayer2];

    [self.colorLayer addSublayer:self.gradientLayer1];
    [self.colorLayer addSublayer:self.gradientLayer2];
    
    self.colorLayer.mask = self.shapeLayer;
    [self.layer addSublayer:self.colorLayer];
    
}

- (void)animate
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.03 target:self selector:@selector(setProgress) userInfo:nil repeats:YES];
}

- (void)setProgress
{
    progress += 0.01;
    
    if (progress > 1.01) {
        [self.timer invalidate];
        self.timer = nil;

#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"已保存到相册" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        alertView.delegate = self;
        [alertView show];
        return;
    }

    self.shapeLayer.strokeEnd = progress;
}

+ (void)showProgressInView:(UIView *)view completeHandler:(void (^)())completeHandler
{
    HCDIndicatorView *progressView = [[HCDIndicatorView alloc] init];
    progressView.center = view.center;
    progressView.completeHandler = completeHandler;
    [view addSubview:progressView];
    
    [progressView animate];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (self.completeHandler) {
        self.completeHandler();
        [self removeFromSuperview];
    }
}
#pragma clang diagnostic pop
@end
