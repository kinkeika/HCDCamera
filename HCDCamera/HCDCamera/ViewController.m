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
#import <Masonry/Masonry.h>
#import "GPUImageReliefFilter.h"
#import <AssetsLibrary/ALAsset.h>
#import "HCDIndicatorView.h"
#import "UIButton+HCDCamera.h"
#import "UIImage+ColorImage.h"
#import "UIColor+HexString.h"
#import "GPUImageNoneFilter.h"

#ifdef DEBUG
#define HCDLog(format, ...) NSLog(format, ##__VA_ARGS__)
#else
#define NSLog(format, ...)
#define HCDLog(format, ...)
#endif

@interface ViewController ()
{
    NSInteger selectedIndex;
    BOOL isPhotoMode;
}
@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageMovieWriter *movieWriter;
@property (nonatomic, strong) NSString *moviePath;

@property (nonatomic, strong) GPUImageView *filterView;

@property (nonatomic, strong) UIButton *captureButton;
@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) GPUImageFilterGroup *currentFilter;

@property (nonatomic, strong) NSArray *filters;
@end

@implementation ViewController

#pragma mark - lifeCycle

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

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
    UIScrollView *topToolScrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:topToolScrollView];
    
    UIScrollView *bottomToolScrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:bottomToolScrollView];
   
    [topToolScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
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
    //无滤镜
    UIButton *normalButton = [UIButton buttonWithMyType];
    [normalButton setTitle:@"正常" forState:UIControlStateNormal];
    [normalButton addTarget:self action:@selector(filter:) forControlEvents:UIControlEventTouchUpInside];
    normalButton.tag = 1000;
    normalButton.backgroundColor = [UIColor colorWithRGBIntegerString:@"200-230-226"];
    [normalButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithRGBIntegerString:@"200-230-226"]] forState:UIControlStateNormal];
    
    [topToolScrollView addSubview:normalButton];
    [normalButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(topToolScrollView.mas_top).offset(20);
        make.width.equalTo(@80);
        make.height.equalTo(@40);
        make.left.equalTo(topToolScrollView.mas_left).offset(20);
    }];
    
    //美颜
    UIButton *beautifyButton = [UIButton buttonWithMyType];
    [beautifyButton setTitle:@"美颜" forState:UIControlStateNormal];
    [beautifyButton addTarget:self action:@selector(filter:) forControlEvents:UIControlEventTouchUpInside];
    beautifyButton.tag = 1001;
    beautifyButton.backgroundColor = [UIColor colorWithRGBIntegerString:@"236-186-193"];
    [beautifyButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithRGBIntegerString:@"236-186-193"]] forState:UIControlStateNormal];
    
    [topToolScrollView addSubview:beautifyButton];
    
    [beautifyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(normalButton.mas_centerY);
        make.width.equalTo(@80);
        make.height.equalTo(@40);
        make.left.equalTo(normalButton.mas_right).offset(20);
    }];
    
    //浮雕
    UIButton *reliefButton = [UIButton buttonWithMyType];
    [reliefButton setTitle:@"浮雕" forState:UIControlStateNormal];
    [reliefButton addTarget:self action:@selector(filter:) forControlEvents:UIControlEventTouchUpInside];
    reliefButton.tag = 1002;
    reliefButton.backgroundColor = [UIColor colorWithRGBIntegerString:@"252-222-180"];
    [reliefButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithRGBIntegerString:@"252-222-180"]] forState:UIControlStateNormal];
    
    [topToolScrollView addSubview:reliefButton];
    [reliefButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(beautifyButton.mas_centerY);
        make.width.equalTo(@80);
        make.height.equalTo(@40);
        make.left.equalTo(beautifyButton.mas_right).offset(20);
    }];
    
    
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
    UIButton *changeInputButton = [UIButton buttonWithMyType];
    [changeInputButton setTitle:@"前/后" forState:UIControlStateNormal];
    [changeInputButton addTarget:self action:@selector(changeInput) forControlEvents:UIControlEventTouchUpInside];
    changeInputButton.backgroundColor = [UIColor colorWithRGBIntegerString:@"198-168-186"];
    [changeInputButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithRGBIntegerString:@"198-168-186"]] forState:UIControlStateNormal];
    
    
    [bottomToolScrollView addSubview:changeInputButton];
    [changeInputButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.captureButton.mas_centerY);
        make.width.equalTo(@80);
        make.height.equalTo(@40);
        make.right.equalTo(self.captureButton.mas_left).offset(-20);
    }];
    
    //照片  视频
    UIButton *modeButton = [UIButton buttonWithMyType];
    [modeButton setTitle:@"视频" forState:UIControlStateNormal];
    [modeButton addTarget:self action:@selector(changeMode:) forControlEvents:UIControlEventTouchUpInside];
    modeButton.backgroundColor = [UIColor colorWithRGBIntegerString:@"162-207-125"];
    [modeButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithRGBIntegerString:@"162-207-125"]] forState:UIControlStateNormal];
    
    [bottomToolScrollView addSubview:modeButton];
    [modeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.captureButton.mas_centerY);
        make.width.equalTo(@80);
        make.height.equalTo(@40);
        make.left.equalTo(self.captureButton.mas_right).offset(20);
    }];
    
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.imageView.center = self.view.center;
    self.imageView.hidden = YES;
    [self.view insertSubview:self.imageView aboveSubview:self.filterView];
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
            
            self.videoCamera.captureSessionPreset = AVCaptureSessionPreset640x480;
            [self.currentFilter addTarget:self.movieWriter];
            self.videoCamera.audioEncodingTarget = self.movieWriter;
            [self.movieWriter startRecording];
            
        }else if ([self.captureButton.titleLabel.text isEqualToString:@"停止"]){
            [self.videoCamera stopCameraCapture];
            [self.currentFilter removeTarget:self.movieWriter];
            
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
    }else{
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
    
    if (isPhotoMode) {
        [self.currentFilter useNextFrameForImageCapture];
    }
    
    [self.videoCamera addTarget:self.currentFilter];
    [self.currentFilter addTarget:self.filterView];
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
            weakSelf.movieWriter = nil;
            [weakSelf.videoCamera startCameraCapture];
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
        _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:[NSURL fileURLWithPath:self.moviePath] size:CGSizeMake(640, 480) fileType:AVFileTypeMPEG4 outputSettings:nil];
        _movieWriter.encodingLiveVideo = YES;
    }
    return _movieWriter;
}

- (NSString *)moviePath
{
    return [NSString stringWithFormat:@"%@myMoviewName.mp4", NSTemporaryDirectory()];
}

- (NSArray *)filters
{
    if (!_filters) {
        _filters = @[[[GPUImageNoneFilter alloc]init],[[GPUImageBeautifyFilter alloc] init],[[GPUImageReliefFilter alloc] init]];
    }
    return _filters;
}


@end
