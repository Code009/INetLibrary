//
//  INetRequestQueue.h
//  iNetLibrary
//
//  Created by Code009 on 13-11-30.
//
//

#import <Foundation/Foundation.h>

#import <iNetLibrary/INetRequest.h>

@class INetRequestQueue;

// 带队列的网络请求
@interface INetQueuedRequest : INetRequest

// 队列
@property (nonatomic,retain) INetRequestQueue *queue;
// 加入队尾
@property (nonatomic,assign) bool tailQueue;

// subclass -  子类需要重写的内容

-(bool)queuedInProgress;	// 判断请求本身是否在进行中，子类重写此方法，而不要重写isInProgress
-(bool)queuedStart;			// 开始请求，子类应重写此方法，而不要重写start
-(void)queuedStop;			// 停止请求，子类应重写此方法，而不要重写stop

@end

@interface INetRequestQueue : NSObject

// 将请求加入队首
-(void)pushRequest:(INetQueuedRequest*)Request;
// 将请求加入队尾
-(void)enqueueRequest:(INetQueuedRequest*)Request;
// 移除请求
-(bool)removeRequest:(INetQueuedRequest*)Request;

// 判断请求是否在队列中
-(bool)isInQueue:(INetQueuedRequest*)Request;

// 最大同时请求的数量
@property(nonatomic,assign) unsigned int maxParrielRequestCount;

// 由INetQueuedRequest调用，通知INetQueuedRequest下载已完成
-(void)notifyRequestCompleted:(INetQueuedRequest*)Request;

@end

