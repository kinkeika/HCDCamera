//
//  ViewController.m
//  HCDCamera
//
//  Created by cheaterhu on 16/9/6.
//  Copyright © 2016年 hcd. All rights reserved.
//

#import "ViewController.h"
#import <GPUImage/GPUImage.h>
#import "GPUImageBeautifyFilter.h"
#import "GPUImageReliefFilter.h"
#import <AssetsLibrary/ALAsset.h>
#import "HCDIndicatorView.h"
#import "UIButton+HCDCamera.h"
#import "GPUImageNoneFilter.h"
#import "HCDProgressView.h"
#import "GPUImageGrayFilter.h"
#import "GPUImageOriginFilter.h"
#import "GPUImageBlack_WhiteFilter.h"

@interface ViewController ()
{
    NSInteger selectedIndex;
    BOOL isPhotoMode;
    NSInteger progress;
}
@property (nonatomic, strong) GPUImageFilterGroup *currentFilter;
@property (nonatomic, strong) GPUImageView *filterView;
@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) NSArray *filters;
@property (nonatomic, strong) NSArray *filterNames;
@property (nonatomic, strong) NSArray<__kindof NSString *> *filterBtnBgColors; //RGB integer string 215-220-125 eg.

//视频相关
@property (nonatomic, strong) GPUImageMovieWriter *movieWriter;
@property (nonatomic, strong) NSString *moviePath;
@property (nonatomic, strong) HCDProgressView *progressView;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) NSTimer *videoTimer;

//照片相关
@property (nonatomic, strong) UIButton *captureButton;
@property (nonatomic, strong) UIImageView *imageView;

//通用
@property (nonatomic, strong) UIScrollView *topToolScrollView;
@property (nonatomic, strong) UIButton *changeInputButton;
@property (nonatomic, strong) UIButton *modeButton;
@end

@implementation ViewController

#pragma mark - lifeCycle

-(void)dealloc
{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [self.videoTimer invalidate];
    self.videoTimer = nil;
    [self.videoCamera stopCameraCapture];
    self.videoCamera = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    progress = 0.0;
    [self p_initCamera];
    [self p_initUI];
    
    [[NSFileManager defaultManager] removeItemAtPath:self.moviePath error:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

#pragma mark - notification

- (void)appDidEnterBackground
{
    [self.videoCamera stopCameraCapture];
}

- (void)appWillEnterForeground
{
    [self.videoCamera startCameraCapture];
}

#pragma mark - private

- (void)p_initUI
{
    self.topToolScrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.topToolScrollView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:self.topToolScrollView];
    
    UIScrollView *bottomToolScrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:bottomToolScrollView];
   
    [self.topToolScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view.mas_width);
        make.height.equalTo(@80);
        make.centerX.equalTo(self.view.mas_centerX);
        make.top.equalTo(self.view.mas_top);
    }];
    
    [bottomToolScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view.mas_width);
        make.height.equalTo(@80);
        make.centerX.equalTo(self.view.mas_centerX);
        make.bottom.equalTo(self.view.mas_bottom);
    }];
    
    //各种滤镜按钮 ===========
    for (int i = 0 ; i < self.filters.count; i++) {
        
        UIButton *filterButton = [UIButton buttonWithMyType];
        [filterButton setTitle:self.filterNames[i] forState:UIControlStateNormal];
        [filterButton addTarget:self action:@selector(filter:) forControlEvents:UIControlEventTouchUpInside];
        filterButton.tag = 1000 + i;
        filterButton.backgroundColor = [UIColor colorWithRGBIntegerString:self.filterBtnBgColors[i]];
        [filterButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithRGBIntegerString:self.filterBtnBgColors[i]]] forState:UIControlStateNormal];
        
        filterButton.frame = CGRectMake(20 + i*(80+20), 20, 80, 40);
        
        [self.topToolScrollView addSubview:filterButton];
    }
    
    self.topToolScrollView.contentSize = CGSizeMake(self.filters.count * (80 + 20) + 20, 80);
    
    //底下操作按钮 ==========
    self.captureButton = [UIButton buttonWithMyType];
    [self.captureButton setTitle:@"拍照" forState:UIControlStateNormal];
    [self.captureButton addTarget:self action:@selector(capture) forControlEvents:UIControlEventTouchUpInside];
    self.captureButton.layer.cornerRadius = 30.0;
    self.captureButton.backgroundColor = [UIColor colorWithRGBIntegerString:@"172-218-224"];
    [self.captureButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithRGBIntegerString:@"172-218-224"]] forState:UIControlStateNormal];
    
    [bottomToolScrollView addSubview:self.captureButton];
    [self.captureButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(bottomToolScrollView.mas_centerY);
        make.width.equalTo(@60);
        make.height.equalTo(@60);
        make.centerX.equalTo(bottomToolScrollView.mas_centerX);
    }];
    
    //前后切换
    self.changeInputButton = [UIButton buttonWithMyType];
    [self.changeInputButton setTitle:@"前/后" forState:UIControlStateNormal];
    [self.changeInputButton addTarget:self action:@selector(changeInput) forControlEvents:UIControlEventTouchUpInside];
    self.changeInputButton.backgroundColor = [UIColor colorWithRGBIntegerString:@"198-168-186"];
    [self.changeInputButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithRGBIntegerString:@"198-168-186"]] forState:UIControlStateNormal];
    
    [bottomToolScrollView addSubview:self.changeInputButton];
    [self.changeInputButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.captureButton.mas_centerY);
        make.width.equalTo(@80);
        make.height.equalTo(@40);
        make.right.equalTo(self.captureButton.mas_left).offset(-20);
    }];
    
    //照片  视频
    self.modeButton = [UIButton buttonWithMyType];
    [self.modeButton setTitle:@"视频" forState:UIControlStateNormal];
    [self.modeButton addTarget:self action:@selector(changeMode:) forControlEvents:UIControlEventTouchUpInside];
    self.modeButton.backgroundColor = [UIColor colorWithRGBIntegerString:@"162-207-125"];
    [self.modeButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithRGBIntegerString:@"162-207-125"]] forState:UIControlStateNormal];
    
    [bottomToolScrollView addSubview:self.modeButton];
    [self.modeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.captureButton.mas_centerY);
        make.width.equalTo(@80);
        make.height.equalTo(@40);
        make.left.equalTo(self.captureButton.mas_right).offset(20);
    }];
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.imageView.center = self.view.center;
    self.imageView.hidden = YES;
    [self.view insertSubview:self.imageView aboveSubview:self.filterView];
    
    self.progressView = [[HCDProgressView alloc] init];
    self.progressView.hidden = YES;
    [self.view insertSubview:self.progressView aboveSubview:self.imageView];
            
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left);
        make.bottom.equalTo(self.view.mas_bottom);
        make.width.equalTo(self.view.mas_width);
        make.height.equalTo(@(3.5));
    }];
    
    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.timeLabel];
    self.timeLabel.hidden = YES;
    self.timeLabel.font = [UIFont systemFontOfSize:12.0];
    self.timeLabel.textColor = [UIColor whiteColor];
    self.timeLabel.text = @"00:00:00";
    
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view.mas_right).offset(-2);
        make.bottom.equalTo(self.progressView.mas_top).offset(-2);
    }];
}

- (void)p_initCamera
{
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPresetiFrame1280x720 cameraPosition:AVCaptureDevicePositionBack];
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    
    self.filterView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    self.filterView.center = self.view.center;
    
    [self.view addSubview:self.filterView];
    [self.videoCamera addTarget:self.filterView];
    
    self.currentFilter = self.filters[0];
    selectedIndex = 1000;
    isPhotoMode = YES;
    
    if (isPhotoMode) {
      [self.currentFilter useNextFrameForImageCapture];
    }
    
    [self.videoCamera addTarget:self.currentFilter];
    [self.videoCamera startCameraCapture];
}

#pragma mark - target action

- (void)capture
{
    if (isPhotoMode) {
        [self.videoCamera stopCameraCapture];
        
        self.captureButton.enabled = NO;
        self.topToolScrollView.userInteractionEnabled = NO;
        self.changeInputButton.enabled = NO;
        self.modeButton.enabled = NO;
        
        UIImage *image = nil;
        
        if (!self.currentFilter) {
            self.currentFilter = [self.filters firstObject];
        }
        
        image = [self.currentFilter imageFromCurrentFramebuffer];
        
        self.imageView.image = image;
        self.imageView.hidden = NO;
        
        UIImageWriteToSavedPhotosAlbum(self.imageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    }else{
        
        if ([self.captureButton.titleLabel.text isEqualToString:@"录制"]) {
            [self.captureButton setTitle:@"停止" forState:UIControlStateNormal];
            
//            self.videoCamera.captureSessionPreset = AVCaptureSessionPreset640x480;
            [self.currentFilter addTarget:self.movieWriter];
            self.videoCamera.audioEncodingTarget = self.movieWriter;
            
            self.videoTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timeUpdate:) userInfo:nil repeats:YES];
            self.progressView.hidden = NO;
            self.timeLabel.hidden = NO;
            
            self.topToolScrollView.userInteractionEnabled = NO;
            self.changeInputButton.enabled = NO;
            self.modeButton.enabled = NO;
            
            [self.movieWriter startRecording];
            
        }else if ([self.captureButton.titleLabel.text isEqualToString:@"停止"]){
            [self.videoCamera stopCameraCapture];
            [self.currentFilter removeTarget:self.movieWriter];
            
            [self.videoTimer invalidate];
            self.videoTimer = nil;
            
            __weak typeof(self) weakSelf = self;
            [self.movieWriter finishRecordingWithCompletionHandler:^{
                UISaveVideoAtPathToSavedPhotosAlbum(weakSelf.moviePath, weakSelf, @selector(video:didFinishSavingWithError:contextInfo:), NULL);
            }];
        }
    }
}

- (void)changeMode:(UIButton *)sender
{
    isPhotoMode = !isPhotoMode;
    
    if (isPhotoMode) {
        [self.captureButton setTitle:@"拍照" forState:UIControlStateNormal];
        [sender setTitle:@"视频" forState:UIControlStateNormal];
        self.progressView.hidden = YES;
        self.timeLabel.hidden = YES;
    }else{
        self.progressView.hidden = NO;
        self.timeLabel.hidden = NO;
        [self.captureButton setTitle:@"录制" forState:UIControlStateNormal];
        [sender setTitle:@"照片" forState:UIControlStateNormal];
    }
}

- (void)changeInput
{
    [self.videoCamera rotateCamera];
}

- (void)filter:(UIButton *)sender {
    
    if (selectedIndex == sender.tag) {
        return;
    }
    
    selectedIndex = sender.tag;
    
    [self.videoCamera removeAllTargets];
    self.currentFilter = self.filters[sender.tag - 1000];
    [self.currentFilter useNextFrameForImageCapture];
    
    [self.videoCamera addTarget:self.currentFilter];
    [self.currentFilter addTarget:self.filterView];
}

- (void)timeUpdate:(NSTimer *)timer
{
    progress += 1;
    [self.progressView setMyProgress:(CGFloat)progress/3600]; // 假设最多录制一小时
    self.timeLabel.text = [NSString stringWithFormat:@"%02li:%02li:%02li",(long)progress/3600,(long)progress/60,(long)progress%60];
}

- (BOOL)shouldAutorotate{
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    self.videoCamera.outputImageOrientation = self.interfaceOrientation;
#pragma clang diagnostic pop
    return YES;
}

-(void)viewWillLayoutSubviews
{
    self.filterView.frame = self.view.bounds;
}

#pragma mark - save image/video callback

- (void)image:(UIImage *) image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo {
    
    __weak typeof(self) weakSelf = self;
    if(error == nil) {
    
        [HCDIndicatorView showProgressInView:self.view completeHandler:^{
            weakSelf.captureButton.enabled = YES;
            
            weakSelf.imageView.hidden = YES;
            self.topToolScrollView.userInteractionEnabled = YES;
            self.changeInputButton.enabled = YES;
            self.modeButton.enabled = YES;
            
            [weakSelf.videoCamera startCameraCapture];
        }];
    }
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    
    __weak typeof(self) weakSelf = self;
    if(error == nil) {
        [weakSelf.captureButton setTitle:@"录制" forState:UIControlStateNormal];
        
        dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
            
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:self.moviePath error:&error];
            
            HCDLog(@"%@======",error.localizedDescription);
        });
        
        [HCDIndicatorView showProgressInView:self.view completeHandler:^{
            weakSelf.captureButton.enabled = YES;
            
            weakSelf.imageView.hidden = YES;
            self.topToolScrollView.userInteractionEnabled = YES;
            self.changeInputButton.enabled = YES;
            self.modeButton.enabled = YES;
            
            weakSelf.movieWriter = nil;
            [weakSelf.videoCamera startCameraCapture];
            
            [self.progressView setMyProgress:0.0];
            self.timeLabel.text = @"00:00:00";
            
        }];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
//    [self.videoCamera stopCameraCapture];
}

#pragma mark - getter

- (GPUImageMovieWriter *)movieWriter
{
    if(!_movieWriter){
        _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:[NSURL fileURLWithPath:self.moviePath] size:CGSizeMake(1280, 640) fileType:AVFileTypeQuickTimeMovie outputSettings:nil];
        _movieWriter.encodingLiveVideo = YES;
        [_movieWriter setHasAudioTrack:YES audioSettings:nil];
    }
    return _movieWriter;
}

- (NSString *)moviePath
{
    return [NSString stringWithFormat:@"%@myMoviewName.mov", NSTemporaryDirectory()];
}

- (NSArray *)filters
{
    if (!_filters) {
        _filters = @[[[GPUImageNoneFilter alloc]init],[[GPUImageBeautifyFilter alloc] init],[[GPUImageReliefFilter alloc] init],[[GPUImageGrayFilter alloc] init],[[GPUImageOriginFilter alloc] init],[[GPUImageBlack_WhiteFilter alloc] init]];
    }
    return _filters;
}

- (NSArray *)filterNames
{
    if (!_filterNames) {
        _filterNames = @[@"正常",@"美颜",@"浮雕",@"灰度图",@"底片",@"黑白"];
    }
    return _filterNames;
}

- (NSArray *)filterBtnBgColors
{
    if (!_filterBtnBgColors) {
        _filterBtnBgColors = @[@"200-230-226",@"236-186-193",@"252-222-180",@"252-222-180",@"252-222-180",@"252-222-180"];
    }
    return _filterBtnBgColors;
}

@end
