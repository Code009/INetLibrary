//
//  INetSimulateRequest.m
//  iNetLibrary
//
//  Created by mtour on 13-12-5.
//
//

#import "INetSimulateRequest.h"

@implementation INetSimulateRequest
{
	NSTimer *Timer;
}

-(id)init
{
	self=[super init];
	if(self==nil)
		return nil;
		
	_delayTime=.5;
	return self;
}

-(void)requestCompleted:(NSError*)error
{
	[super requestCompleted:error];
}

-(bool)isInProgress
{
	return Timer!=nil;
}

-(NSData *)responseData
{
	if(Timer!=nil)
		return nil;
	return _simulateData;
}

-(void)timerHit
{
	Timer=nil;
	
	[self requestCompleted:nil];
}

-(bool)start
{
	if(Timer!=nil)
		return false;
	Timer=[NSTimer scheduledTimerWithTimeInterval:_delayTime target:self selector:@selector(timerHit) userInfo:nil repeats:FALSE];
	return true;
}

-(void)cancel
{
	if(Timer!=nil){
		[Timer invalidate];
		Timer=nil;
		
		[self requestCompleted:nil];
	}
}


@end
