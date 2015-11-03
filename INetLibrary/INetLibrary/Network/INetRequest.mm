//
//  INetRequest.m
//  iNetLibrary
//
//  Created by Code009 on 13-11-30.
//
//

#import "INetRequest.h"

#import "Debug.h"

@implementation INetRequest

@synthesize delegate;

-(void)requestCompleted:(NSError*)error
{
	[delegate netRequestCompletion:self error:error];
}

-(NSData *)responseData
{
	return nil;
}

-(bool)isInProgress
{
	IN_ASSERT(0);	//需要子类实现
	return false;
}

-(bool)start
{
	IN_ASSERT(0);	//需要子类实现
	return false;
}

-(void)cancel
{
	IN_ASSERT(0);	//需要子类实现
}

@end
