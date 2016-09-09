//
//  GPUImageNoneFilter.m
//  HCDCamera
//
//  Created by cheaterhu on 16/9/8.
//  Copyright © 2016年 hcd. All rights reserved.
//

#import "GPUImageNoneFilter.h"

@interface NoneFilter : GPUImageThreeInputFilter

@end

NSString *const kNoneFilterFragmentShaderString = SHADER_STRING
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
     gl_FragColor = texture2D(inputImageTexture3, textureCoordinate3);
 }
 );

@implementation NoneFilter

- (id)init {
    if (self = [super initWithFragmentShaderFromString:kNoneFilterFragmentShaderString]) {
    }
    return self;
}

@end

@interface GPUImageNoneFilter ()
{
    NoneFilter *noneFilter;
    GPUImageBilateralFilter *bilateralFilter;
    GPUImageCannyEdgeDetectionFilter *cannyEdgeFilter;
    GPUImageHSBFilter *hsbFilter;
}
@end

@implementation GPUImageNoneFilter

- (id)init;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    // Third pass: combination bilateral, edge detection and origin
    noneFilter = [[NoneFilter alloc] init];
    [self addFilter:noneFilter];
    //
    
    // First pass: face smoothing filter
    bilateralFilter = [[GPUImageBilateralFilter alloc] init];
    bilateralFilter.distanceNormalizationFactor = 4.0;
    [self addFilter:bilateralFilter];
    
    // Second pass: edge detection
    cannyEdgeFilter = [[GPUImageCannyEdgeDetectionFilter alloc] init];
    [self addFilter:cannyEdgeFilter];
    
    // Adjust HSB
    hsbFilter = [[GPUImageHSBFilter alloc] init];
    [hsbFilter adjustBrightness:1.1];
    [hsbFilter adjustSaturation:1.1];
    //
    [bilateralFilter addTarget:noneFilter];
    [cannyEdgeFilter addTarget:noneFilter];
    
    //    [reliefFilter addTarget:hsbFilter];
    
    self.initialFilters = [NSArray arrayWithObjects:bilateralFilter,cannyEdgeFilter,noneFilter,nil];
    self.terminalFilter = noneFilter;
    
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
            if (currentFilter == noneFilter) {
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
        if (currentFilter == noneFilter) {
            textureIndex = 2;
        }
        [currentFilter setInputFramebuffer:newInputFramebuffer atIndex:textureIndex];
    }
}

@end

