//
//  UIButton+HCDCamera.m
//  HCDCamera
//
//  Created by cheaterhu on 16/9/7.
//  Copyright © 2016年 hcd. All rights reserved.
//

#import "UIButton+HCDCamera.h"

@implementation UIButton (HCDCamera)
+(instancetype)buttonWithMyType
{
    UIButton *button = [self buttonWithType:UIButtonTypeCustom];
    button.layer.cornerRadius = 4.0;
    button.layer.masksToBounds = YES;
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage imageWithColor:[UIColor clearColor]] forState:UIControlStateSelected];
    return button;
}
@end
