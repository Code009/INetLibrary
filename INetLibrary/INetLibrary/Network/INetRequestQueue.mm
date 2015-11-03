//
//  INetRequestQueue.m
//  iNetLibrary
//
//  Created by Code009 on 13-11-30.
//
//
#include <vector>

#import "INetRequestQueue.h"
#import "Debug.h"


using namespace iNetLib;

#pragma mark -

@implementation INetQueuedRequest
{
	// 正在排队中的队列
	INetRequestQueue *fProcessingQueue;
}

@synthesize queue;
@synthesize tailQueue;


-(bool)isInProgress
{
	if(fProcessingQueue!=nil){
		if([fProcessingQueue isInQueue:self]){
			return true;
		}
	}
    return [self queuedInProgress];
}


-(bool)start
{
	if(queue==nil)
		return [self queuedStart];
	if(tailQueue){
		[queue enqueueRequest:self];
	}
	else{
		[queue pushRequest:self];
	}
	return true;
}

-(void)cancel
{
	if(fProcessingQueue!=nil){
		if([fProcessingQueue removeRequest:self])
			return;
	}
	if(self.isInProgress==false)
		return;
	[self queuedStop];
}


-(bool)queuedInProgress
{
	return false;
}

-(bool)queuedStart
{
	return false;
}
-(void)queuedStop
{
}

-(void)requestCompleted:(NSError*)error
{
	if(fProcessingQueue!=nil){
		[fProcessingQueue notifyRequestCompleted:self];
		fProcessingQueue=nil;
	}
	
	[super requestCompleted:error];
}

-(void)onRequestQueueEnter:(INetRequestQueue*)sender
{
	IN_ASSERT(fProcessingQueue==nil);
	
	fProcessingQueue=sender;
}
-(void)onRequestQueueLeave:(INetRequestQueue*)sender
{
	if(fProcessingQueue==sender){
		fProcessingQueue=nil;
	}
}

@end

#pragma mark -

@implementation INetRequestQueue
{
	std::vector<INetQueuedRequest*> RequestQueue;
	unsigned int RequestCount;
	unsigned int MaxParrielRequestCount;
}

@synthesize maxParrielRequestCount=MaxParrielRequestCount;

-(id)init
{
	self=[super init];
	if(self==nil)
		return nil;

	MaxParrielRequestCount=1;
	return self;
}

-(void)notifyRequestCompleted:(INetQueuedRequest*)Request
{
	IN_ASSERT(RequestCount!=0);
	RequestCount--;
	[Request onRequestQueueLeave:self];
	[self continueProcessRequest];
}


-(void)doProcessRequest
{
	while(RequestCount<MaxParrielRequestCount){
		auto count=RequestQueue.size();
		if(count==0){
			// 没有等待中的请求
			return;
		}

		// 提取请求
		auto *Request=RequestQueue[count-1];
		RequestQueue.pop_back();

		// 开始
		if([Request queuedStart]){
			// 标记请求数
			RequestCount++;
		}
		else{
			// 请求失败
		}
	}

}

-(void)continueProcessRequest
{
	[self doProcessRequest];
}

-(void)pushRequest:(INetQueuedRequest*)Request
{
	IN_ASSERT(Request!=nullptr);
	IN_ASSERT(Request.isInProgress==false);

	// 从队列中删除
	bool Exists=[self internal_RemoveRequest:Request];
	// 重新加入队列
	RequestQueue.push_back(Request);
	if(Exists==false){
		// 通知请求对象：新加入队列
		[Request onRequestQueueEnter:self];
	}

	// 继续请求
	[self continueProcessRequest];
}

-(void)enqueueRequest:(INetQueuedRequest*)Request
{
	IN_ASSERT(Request!=nullptr);
	IN_ASSERT(Request.isInProgress==false);

	// 从队列中删除
	bool Exists=[self internal_RemoveRequest:Request];
	// 重新加入队列
	RequestQueue.insert(RequestQueue.begin(),Request);
	if(Exists==false){
		// 通知请求对象：新加入队列
		[Request onRequestQueueEnter:self];
	}
	// 继续请求

	[self continueProcessRequest];
}

-(bool)internal_RemoveRequest:(INetQueuedRequest*)Request
{
	if(Request==nullptr)
		return false;
	for(auto i=RequestQueue.begin();i<RequestQueue.end();i++){
		if(*i==Request){
			RequestQueue.erase(i);
			return true;
		}
	}
	return false;
}

-(bool)removeRequest:(INetQueuedRequest*)Request
{
	if([self internal_RemoveRequest:Request]){
		// 通知请求对象：退出队列
		[Request onRequestQueueLeave:self];
		return true;
	}
	return false;
}


-(bool)isInQueue:(INetQueuedRequest*)Request
{
	return find(RequestQueue.begin(),RequestQueue.end(),Request)!=RequestQueue.end();
}



@end

