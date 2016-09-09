//
//  GPUImageReliefFilter
//  HCDCamera
//
//  Created by cheaterhu on 16/9/5.
//  Copyright © 2016年 hcd. All rights reserved.
//

#import "GPUImageReliefFilter.h"
#import "GPUImageBilateralFilter.h"
#import "GPUImageCannyEdgeDetectionFilter.h"

@interface ReliefFilter : GPUImageThreeInputFilter

@end

NSString *const kReliefFilterVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute mediump vec4 texturecoordinate;
 varying mediump vec2 coordinate;
 
 void main()
 {
    gl_Position = position;
    coordinate = texturecoordinate.xy;
 }
 );

NSString *const kReliefFilterFragmentShaderString = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 varying highp vec2 textureCoordinate3;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform sampler2D inputImageTexture3;
 
 vec4 reliefFragColor();
 
 void main()
 {
    gl_FragColor = reliefFragColor();
 }
 
 vec4 reliefFragColor(){
     
     ivec2 inFrame = ivec2(1080,720);
     
     vec3 currentColor = texture2D(inputImageTexture3, textureCoordinate3).rgb;
     
     vec2 gap = vec2(1.0/float(inFrame.s),0.0);
     
     vec3 rightColor = texture2D(inputImageTexture3, textureCoordinate3 + gap).rgb;
     
     vec3 subColor = currentColor - rightColor;
     
     float maxValue = subColor.r;
     
     if (abs(subColor.g) > abs(maxValue)) {
         maxValue = subColor.g;
     }
     
     if (abs(subColor.b) > abs(maxValue)) {
         maxValue = subColor.b;
     }
     
     
     float gray = clamp(maxValue + 0.5, 0.0 ,1.0);
     
     return  vec4(gray,gray,gray,1.0);
            //vec4(currentColor.r,currentColor.g,currentColor.b,1.0);
 }
 );


@implementation ReliefFilter

- (id)init {
    if (self = [super initWithFragmentShaderFromString:kReliefFilterFragmentShaderString]) {
    }
    return self;
}

@end


@interface GPUImageReliefFilter ()
{
    ReliefFilter *reliefFilter;
    GPUImageBilateralFilter *bilateralFilter;
    GPUImageCannyEdgeDetectionFilter *cannyEdgeFilter;
    GPUImageHSBFilter *hsbFilter;
}
@end
@implementation GPUImageReliefFilter

- (id)init;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    // Third pass: combination bilateral, edge detection and origin
    reliefFilter = [[ReliefFilter alloc] init];
    [self addFilter:reliefFilter];
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
    [bilateralFilter addTarget:reliefFilter];
    [cannyEdgeFilter addTarget:reliefFilter];
    
//    [reliefFilter addTarget:hsbFilter];
    
    self.initialFilters = [NSArray arrayWithObjects:bilateralFilter,cannyEdgeFilter,reliefFilter,nil];
    self.terminalFilter = reliefFilter;
    
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
            if (currentFilter == reliefFilter) {
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
        if (currentFilter == reliefFilter) {
            textureIndex = 2;
        }
        [currentFilter setInputFramebuffer:newInputFramebuffer atIndex:textureIndex];
    }
}

@end







