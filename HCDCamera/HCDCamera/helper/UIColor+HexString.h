//
//  UIColor+HexString.h
//  ZYMeiHuo
//
//  Created by cheaterhu on 15/12/16.
//  Copyright © 2015年 hcd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (HexString)
+ (UIColor *) colorWithHexString: (NSString *) stringToConvert;

//r-g-b 用-连接
+ (UIColor *) colorWithRGBIntegerString:(NSString *)rgbString;
@end
