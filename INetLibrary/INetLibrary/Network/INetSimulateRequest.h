//
//  INetSimulateRequest.h
//  iNetLibrary
//
//  Created by mtour on 13-12-5.
//
//

#import <iNetLibrary/INetRequest.h>

// 模拟网络请求
@interface INetSimulateRequest : INetRequest

// 完成延迟时间
@property(nonatomic,assign) NSTimeInterval delayTime;
// 下载的内容
@property(nonatomic,retain) NSData *simulateData;

@end
