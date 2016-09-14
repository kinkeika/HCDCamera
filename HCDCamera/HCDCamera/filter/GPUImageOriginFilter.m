//
//  GPUImageOriginFilter.m
//  HCDCamera
//
//  Created by cheaterhu on 16/9/13.
//  Copyright © 2016年 hcd. All rights reserved.
//

#import "GPUImageOriginFilter.h"

@interface OriginFilter : GPUImageThreeInputFilter

@end

NSString *const kOriginFilterFragmentShaderString = SHADER_STRING
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
     gl_FragColor = vec4(1.0 - color.r, 1.0 - color.g, 1.0 - color.b, 1.0);
 }
 );

@implementation OriginFilter

- (id)init {
    if (self = [super initWithFragmentShaderFromString:kOriginFilterFragmentShaderString]) {
    }
    return self;
}

@end

@interface GPUImageOriginFilter ()
{
    OriginFilter *originFilter;
    GPUImageBilateralFilter *bilateralFilter;
    GPUImageCannyEdgeDetectionFilter *cannyEdgeFilter;
    GPUImageHSBFilter *hsbFilter;
}
@end

@implementation GPUImageOriginFilter

- (id)init;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    // Third pass: combination bilateral, edge detection and origin
    originFilter = [[OriginFilter alloc] init];
    [self addFilter:originFilter];
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
    [bilateralFilter addTarget:originFilter];
    [cannyEdgeFilter addTarget:originFilter];
    
    //    [reliefFilter addTarget:hsbFilter];
    
    self.initialFilters = [NSArray arrayWithObjects:bilateralFilter,cannyEdgeFilter,originFilter,nil];
    self.terminalFilter = originFilter;
    
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
            if (currentFilter == originFilter) {
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
        if (currentFilter == originFilter) {
            textureIndex = 2;
        }
        [currentFilter setInputFramebuffer:newInputFramebuffer atIndex:textureIndex];
    }
}
@end
