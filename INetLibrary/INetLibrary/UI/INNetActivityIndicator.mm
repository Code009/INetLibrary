//
//  INNetActivityIndicator.m
//  iNetLibrary
//
//  Created by Code009 on 13-11-30.
//
//

#import <UIKit/UIKit.h>
#import "INNetActivityIndicator.h"

@implementation INNetActivityIndicator
{
	bool ShowNetActivityIndicator;
}

-(void)dealloc
{
	// 停止显示
	self.showNetActivityIndicator=false;
}

#pragma mark -

-(bool)showNetActivityIndicator
{
	return ShowNetActivityIndicator;
}

-(void)setShowNetActivityIndicator:(bool)show
{
	if(ShowNetActivityIndicator==show)
		return;	// 标志无变化
	ShowNetActivityIndicator=show;
	if(show){
		// 增加显示引用
		if([NSThread isMainThread])
			[INNetActivityIndicator addShow];
		else
			[self performSelectorOnMainThread:@selector(callMainThread_Add) withObject:nil waitUntilDone:FALSE];
	}
	else{
		// 减少显示引用
		if([NSThread isMainThread])
			[INNetActivityIndicator subShow];
		else
			[self performSelectorOnMainThread:@selector(callMainThread_Sub) withObject:nil waitUntilDone:FALSE];
	}
}

-(void)callMainThread_Add
{
	[INNetActivityIndicator addShow];
}
-(void)callMainThread_Sub
{
	[INNetActivityIndicator subShow];
}

#pragma mark global

static int32_t NetActivityIndicatorVisibleCount=0;	// 显示引用数
static NSTimer *NetActivityIndicatorTimer=nil;		// 延时消失定时器

+(void)addShow
{
	NetActivityIndicatorVisibleCount++;
	if(NetActivityIndicatorVisibleCount==1){
		// 显示
		auto app=[UIApplication sharedApplication];
		app.networkActivityIndicatorVisible=true;
	}
}
+(void)subShow
{
	NetActivityIndicatorVisibleCount--;
	if(NetActivityIndicatorVisibleCount==0){
		// 延时隐藏
		if(NetActivityIndicatorTimer!=nil){
			[NetActivityIndicatorTimer invalidate];
			NetActivityIndicatorTimer=nil;
		}
		NetActivityIndicatorTimer=[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(doShowNetActivityIndicator) userInfo:nil repeats:NO];
	}
}

+(void)doShowNetActivityIndicator
{
	auto app=[UIApplication sharedApplication];
	app.networkActivityIndicatorVisible=NetActivityIndicatorVisibleCount!=0;
	NetActivityIndicatorTimer=nil;
}


@end
