//
//  HCDIndicatorView.h
//  HCDCamera
//
//  Created by cheaterhu on 16/9/7.
//  Copyright © 2016年 hcd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HCDIndicatorView : UIView

+ (void)showProgressInView:(UIView *)view completeHandler:(void(^)())completeHandler;

@end
