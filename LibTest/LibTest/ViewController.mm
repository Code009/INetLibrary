//
//  ViewController.m
//  LibTest
//
//  Created by 韦晓磊 on 15/11/3.
//  Copyright (c) 2015年 Code009. All rights reserved.
//

#import "ViewController.h"

#import <INetLibrary/INetLibrary.h>
#import <INetLibrary/INetDataControl.h>

using namespace iNetLib;

@interface TestDataControl : INetDataControl

@end




@implementation TestDataControl
-(void)createRequest
{
	auto Request=[[INetHTTPRequest alloc]init];
	Request.destURL=[[NSURL alloc]initWithString:@"http://www.damai.com"];
//	Request.queue=nil;
//	Request.tailQueue=true;

	self.netRequest=Request;
}

-(void)processResponse
{
    if(self.netError){
        // error
    }
    else{
		auto Request=self.netRequest;
		[self dataProcess:Request.responseData];
    }
}

-(void)dataProcess:(NSData*)data
{
	NSLog(@"downloaded data : %@",data);
}

@end




@interface ViewController ()

@end

@implementation ViewController
{
	TestDataControl *dataCtrl;
	ocNotifyPointer notify;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

	dataCtrl=[[TestDataControl alloc]init];

	notify[self]=@selector(dataNotify);
	notify.Receive(dataCtrl.onUpdate);

	[dataCtrl refresh];


}

-(void)dataNotify
{
	NSLog(@"ui notify");
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
