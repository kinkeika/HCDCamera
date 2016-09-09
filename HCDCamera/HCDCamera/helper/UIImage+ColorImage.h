//
//  UIImage+ColorImage.h
//  SnackMan
//
//  Created by cheaterhu on 16/3/2.
//  Copyright © 2016年 apple. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ColorImage)

+ (UIImage *)imageWithColor:(UIColor *)aColor;

+ (UIImage *)imageWithColor:(UIColor *)aColor Rect:(CGRect)aRect;
@end
