//
//  INetRequest.h
//  iNetLibrary
//
//  Created by Code009 on 13-11-30.
//
//

#import <Foundation/Foundation.h>

@protocol INetRequestDelegate;

@interface INetRequest : NSObject

// （网络请求回调）通知网络请求完毕
-(void)requestCompleted:(NSError*)error;

// 开始请求
-(bool)start;

// 取消请求
-(void)cancel;

// 请求是否在进行中
@property(nonatomic,readonly) bool isInProgress;

// 通知
@property (nonatomic,weak) id<INetRequestDelegate> delegate;

// 网络返回数据
@property (nonatomic,readonly) NSData *responseData;

// 进度值，从0到1
@property(nonatomic,readonly) float progressPercent;
// 已下载的字节数
@property(nonatomic,readonly) NSUInteger completedSize;
// 预期下载的字节数
@property(nonatomic,readonly) NSUInteger expectedSize;

@end

@protocol INetRequestDelegate

// 有进度改变的通知
-(void)netRequestProgress:(INetRequest*)sender;
// 请求完成的通知
-(void)netRequestCompletion:(INetRequest*)sender error:(NSError*)error;

@end

