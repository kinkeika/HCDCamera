//
//  GPUImageBlack_WhiteFilter.m
//  HCDCamera
//
//  Created by cheaterhu on 16/9/13.
//  Copyright © 2016年 hcd. All rights reserved.
//

#import "GPUImageBlack_WhiteFilter.h"

@interface Black_WhiteFilter : GPUImageThreeInputFilter

@end

NSString *const kBlack_WhiteFilterFragmentShaderString = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 varying highp vec2 textureCoordinate3;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform sampler2D inputImageTexture3;
 
 void main()
 {
     vec4 color = texture2D(inputImageTexture3, textureCoordinate3);
     
     float average = (color.r + color.g + color.b)/3.0;
     
     if (average > 0.5) {
         average = 1.0;
     }else{
         average = 0.0;
     }
  
     gl_FragColor = vec4(average);
 }
 );

@implementation Black_WhiteFilter

- (id)init {
    if (self = [super initWithFragmentShaderFromString:kBlack_WhiteFilterFragmentShaderString]) {
    }
    return self;
}

@end

@interface GPUImageBlack_WhiteFilter ()
{
    Black_WhiteFilter *black_WhiteFilter;
    GPUImageBilateralFilter *bilateralFilter;
    GPUImageCannyEdgeDetectionFilter *cannyEdgeFilter;
    GPUImageHSBFilter *hsbFilter;
}
@end

@implementation GPUImageBlack_WhiteFilter

- (id)init;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    // Third pass: combination bilateral, edge detection and origin
    black_WhiteFilter = [[Black_WhiteFilter alloc] init];
    [self addFilter:black_WhiteFilter];
    //
    
    // First pass: face smoothing filter
    bilateralFilter = [[GPUImageBilateralFilter alloc] init];
    bilateralFilter.distanceNormalizationFactor = 1.0;
    [self addFilter:bilateralFilter];
    
    // Second pass: edge detection
    cannyEdgeFilter = [[GPUImageCannyEdgeDetectionFilter alloc] init];
    [self addFilter:cannyEdgeFilter];
    
    // Adjust HSB
    hsbFilter = [[GPUImageHSBFilter alloc] init];
    [hsbFilter adjustBrightness:1.1];
    [hsbFilter adjustSaturation:1.1];
    //
    [bilateralFilter addTarget:black_WhiteFilter];
    [cannyEdgeFilter addTarget:black_WhiteFilter];
    
//        [black_WhiteFilter addTarget:hsbFilter];
    
    self.initialFilters = [NSArray arrayWithObjects:bilateralFilter,cannyEdgeFilter,black_WhiteFilter,nil];
    self.terminalFilter = black_WhiteFilter;
    
    return self;
}

#pragma mark -
#pragma mark GPUImageInput protocol

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    for (GPUImageOutput<GPUImageInput> *currentFilter in self.initialFilters)
    {
        if (currentFilter != self.inputFilterToIgnoreForUpdates)
        {
            if (currentFilter == black_WhiteFilter) {
                textureIndex = 2;
            }
            [currentFilter newFrameReadyAtTime:frameTime atIndex:textureIndex];
        }
    }
}

- (void)setInputFramebuffer:(GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex;
{
    for (GPUImageOutput<GPUImageInput> *currentFilter in self.initialFilters)
    {
        if (currentFilter == black_WhiteFilter) {
            textureIndex = 2;
        }
        [currentFilter setInputFramebuffer:newInputFramebuffer atIndex:textureIndex];
    }
}

@end
