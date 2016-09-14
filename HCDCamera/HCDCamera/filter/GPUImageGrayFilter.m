//
//  GPUImageGrayFilter.m
//  HCDCamera
//
//  Created by cheaterhu on 16/9/13.
//  Copyright © 2016年 hcd. All rights reserved.
//

#import "GPUImageGrayFilter.h"

@interface GrayFilter : GPUImageThreeInputFilter

@end

NSString *const kGrayFilterFragmentShaderString = SHADER_STRING
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
     float gray = (color.r + color.g + color.b) / 3.0;
     gl_FragColor = vec4(gray,gray,gray,1.0);
 }
 );

@implementation GrayFilter

- (id)init {
    if (self = [super initWithFragmentShaderFromString:kGrayFilterFragmentShaderString]) {
    }
    return self;
}

@end

@interface GPUImageGrayFilter ()
{
    GrayFilter *grayFilter;
    GPUImageBilateralFilter *bilateralFilter;
    GPUImageCannyEdgeDetectionFilter *cannyEdgeFilter;
    GPUImageHSBFilter *hsbFilter;
}
@end

@implementation GPUImageGrayFilter

- (id)init;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    // Third pass: combination bilateral, edge detection and origin
    grayFilter = [[GrayFilter alloc] init];
    [self addFilter:grayFilter];
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
    [bilateralFilter addTarget:grayFilter];
    [cannyEdgeFilter addTarget:grayFilter];
    
    //    [reliefFilter addTarget:hsbFilter];
    
    self.initialFilters = [NSArray arrayWithObjects:bilateralFilter,cannyEdgeFilter,grayFilter,nil];
    self.terminalFilter = grayFilter;
    
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
            if (currentFilter == grayFilter) {
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
        if (currentFilter == grayFilter) {
            textureIndex = 2;
        }
        [currentFilter setInputFramebuffer:newInputFramebuffer atIndex:textureIndex];
    }
}

@end
