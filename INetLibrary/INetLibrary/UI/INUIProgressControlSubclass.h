//
//  INUIProgressControlSubclass.h
//  iNetLibrary
//
//  Created by mtour on 13-12-31.
//
//

#import <iNetLibrary/INUIProgressControl.h>

@interface INUIProgressControl ()


// 在进度中
@property(nonatomic,assign,readonly) bool isInProgress;
// 是否有进度值
@property(nonatomic,assign,readonly) bool hasProgressValue;
// 进度值，从0到1
@property(nonatomic,assign,readonly) float progressValue;

// 需要重试
@property(nonatomic,assign,readonly) bool needRetry;
// 重试
-(void)retry;


@end
