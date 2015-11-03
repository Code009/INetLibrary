//
//  INNetActivityIndicator.h
//  iNetLibrary
//
//  Created by Code009 on 13-11-30.
//
//

#import <Foundation/Foundation.h>

// 网络进度提示
//	有任何对象标志为真时，显示网络进度指示
@interface INNetActivityIndicator : NSObject

// 显示网络进度提示
@property(nonatomic,assign) bool showNetActivityIndicator;

@end
