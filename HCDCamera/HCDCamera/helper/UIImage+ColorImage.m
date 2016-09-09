//
//  UIImage+ColorImage.m
//  SnackMan
//
//  Created by cheaterhu on 16/3/2.
//  Copyright © 2016年 apple. All rights reserved.
//

#import "UIImage+ColorImage.h"

@implementation UIImage (ColorImage)

+ (UIImage *)imageWithColor:(UIColor *)aColor {
    
    return [self imageWithColor:aColor Rect:CGRectMake(0, 0, 1, 1)];
}

+ (UIImage *)imageWithColor:(UIColor *)aColor Rect:(CGRect)aRect {
    
    UIGraphicsBeginImageContext(aRect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [aColor CGColor]);
    CGContextFillRect(context, aRect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
    
}
@end
