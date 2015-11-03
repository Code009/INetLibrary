//
//  INetDataControl.m
//  iNetLibrary
//
//  Created by Code009 on 13-11-30.
//
//
#include <sys/sysctl.h>

#import "Property.h"
#import "Debug.h"
#import "INetDataControl.h"

using namespace iNetLib;

#pragma mark thread


@interface INetDataThread : NSThread<NSMachPortDelegate>
@end
@implementation INetDataThread
{
	NSMachPort *MsgPort;
}

-(id)init
{
	self=[super init];
	if(self==nil)
		return nil;
	MsgPort=[[NSMachPort alloc]init];
	[MsgPort setDelegate:self];
	[self start];
	return self;
}

-(void)main
{
	// 数据线程优先级调低（界面线程应该是0.5）
	[NSThread setThreadPriority:0.3];

	auto CurRunLoop=[NSRunLoop currentRunLoop];

	// Install the port as an input source on the current run loop.
	[CurRunLoop addPort:MsgPort forMode:NSDefaultRunLoopMode];

	[CurRunLoop runUntilDate:[NSDate distantFuture]];
}

-(void)handleMachMessage:(void *)msg
{
}

@end


static NSThread *gDataThreadInit(void){
    size_t len;
    unsigned int ncpu=0;

    len = sizeof(ncpu);
    sysctlbyname ("hw.ncpu",&ncpu,&len,NULL,0);


	if(ncpu<=1){
		DebugLog(@"network in main thread\n");
		return [NSThread mainThread];
	}
	else{
		DebugLog(@"network multithreaded\n");
		return [[INetDataThread alloc]init];
	}
}

static NSThread *gDataThread=gDataThreadInit();

static bool IsDataThread(void){
	return [[NSThread currentThread] isEqual:gDataThread];
}


#pragma mark DataObject

@implementation INetDataObject

@synthesize updateDate;

@end


#pragma mark DataModel

@interface INetDataModel()

-(void)mainThread_CallUpdate;
-(void)main_thread_assigndata:(INetDataObject*)NewData;

@end

@implementation INetDataModel
{
	bool IsInUpdate;
@package
	INetRequest *netRequest;
	int RequestState;

	id ProcessingParam;

	ocNotifyList<void (void)> OnUpdate;
	ocNotifyList<void (void)> OnProgress;

	bool isCompleted;
	NSError *netError;
}

@synthesize processingParam=ProcessingParam;
@synthesize requestState=RequestState;
@synthesize netRequest;

@synthesize data;
@synthesize param;

@synthesize isCompleted;
@synthesize netError;

#pragma mark event

-(INNotifyList *)onUpdate{	return OnUpdate;	}
-(INNotifyList *)onProgress{	return OnProgress;	}

#pragma mark param

+(Class)paramClass
{
	OCPropertyInfo pInfo;

	if(pInfo.LoadClassProperty(self,"param")){
		// 从类型编码获取类型
		auto t=OCGetClassByTypeName(pInfo.type);
		if(t!=[NSObject class]){
			return t;
		}
	}
	// 找不到类型
	return [NSObject class];
}

static void CopyParam(Class cls,id dest,id src)
{	
	do{
		// 复制所有属性
		unsigned int ProCount=0;
		auto ProList=class_copyPropertyList(cls,&ProCount);
		for(unsigned int i=0;i<ProCount;i++){
			auto *ProName=[[NSString alloc]initWithUTF8String:property_getName(ProList[i])];
			id val=[src valueForKey:ProName];
			[dest setValue:val forKey:ProName];
		}

		// parent class property
		cls=class_getSuperclass(cls);
	}while(cls!=[NSObject class]);
}

-(id)copyProcessParam
{
	Class ParamClass=[param class];
	if(ParamClass==[NSObject class]){
		return [[NSObject alloc]init];
	}
	id NewParam=[[ParamClass alloc]init];
	// 复制所有属性
	CopyParam(ParamClass,NewParam,param);
	return NewParam;
}

#pragma mark init
-(id)init
{
	self=[super init];
	if(self==nil)
		return nil;

	Class ParamClass=[[self class] paramClass];
	param=[[ParamClass alloc]init];
	isCompleted=true;
	return self;
}

-(void)dealloc
{
	if(netRequest!=nil){
		netRequest.delegate=nil;
		[netRequest performSelector:@selector(cancel) onThread:gDataThread withObject:nil waitUntilDone:NO];
		netRequest=nil;
	}
}

#pragma mark request Subclass

-(void)createRequest
{
	DebugLog(@"%@类未实现 createRequest\n",[self class]);
}


-(void)processResponse
{
	DebugLog(@"%@类未实现 processResponse\n",[self class]);
	// 结束状态
	RequestState=0;
}


#pragma mark update notify

-(void)mainThread_CallUpdate
{
	OnUpdate();
}

-(void)callUpdate
{
	IN_ASSERT(IsDataThread());
	if(IsInUpdate)
		return;

	IsInUpdate=true;
	[self performSelectorOnMainThread:@selector(mainThread_CallUpdate) withObject:nil waitUntilDone:YES];
	IsInUpdate=false;
}

#pragma mark progress
-(bool)isInProgress
{
	if(netRequest==nil)
		return false;
	return netRequest.isInProgress;
}

-(float)progressValue
{
	if(netRequest.isInProgress)
		return netRequest.progressPercent;
	return 0;
}

#pragma mark process


-(void)startRequest
{
	isCompleted=false;
	[self createRequest];
	if(netRequest!=nil){
		netRequest.delegate=self;
		[netRequest start];
		// notify progress
		OnProgress();
	}
}
-(void)stopRequest
{
	if(netRequest!=nil){
		netRequest.delegate=nil;
		[netRequest cancel];
		netRequest=nil;
	}
}

// 启动请求 必须在数据线程中调用
-(void)makeRequest:(id)Param
{
	IN_ASSERT(IsDataThread());

	[self stopRequest];

	RequestState=0;
	ProcessingParam=Param;

	[self startRequest];
	if(netRequest==nil){
		// 通知不加载
		[self callUpdate];
		return;
	}

	// 通知开始加载
	[self callUpdate];
}

// 清除数据, 必须在数据线程中调用
-(void)clearResult
{
	IN_ASSERT(IsDataThread());
	
	isCompleted=false;
	[self outputData:nil];
	[self callUpdate];
}


-(void)netRequestProgress:(INetRequest*)sender;
{
	if(netRequest!=sender)
		return;
	OnProgress();
}

-(void)netRequestCompletion:(INetRequest*)sender error:(NSError*)error
{
	if(netRequest!=sender)
		return;

	netError=error;

	netRequest.delegate=nil;
	isCompleted=true;

	
	[self processResponse];
	netRequest=nil;
	if(RequestState!=0){
		// 继续下一个请求
		[self startRequest];
		if(netRequest==nil){
			// 通知加载失败
			[self callUpdate];
		}
		return;
	}

	// 清除处理中的参数
	ProcessingParam=nil;

	[self callUpdate];
}

-(void)main_thread_assigndata:(INetDataObject*)NewData
{
	data=NewData;
}

-(void)outputData:(INetDataObject*)NewData
{
	// 转移到主线程赋值
	[self performSelectorOnMainThread:@selector(main_thread_assigndata:) withObject:NewData waitUntilDone:YES];
}



@end

#pragma mark Request

@implementation INetDataRequest

-(void)request:(id)Param
{
	if(self.isInProgress)
		return;
	[self makeRequest:Param];
}

-(bool)request
{
//	IN_ASSERT([NSThread isMainThread]);


	id NewParam=[self copyProcessParam];
	if(IsDataThread()){
		[self request:NewParam];
	}
	else{
		[self performSelector:@selector(request:) onThread:gDataThread withObject:NewParam waitUntilDone:NO];
	}
	return true;
}


@end

#pragma mark Control

@implementation INetDataControl
{
}



-(void)clear
{
	IN_ASSERT([NSThread isMainThread]);

	if(IsDataThread()){
		[self clearResult];
	}
	else{
		[self performSelector:@selector(clearResult) onThread:gDataThread withObject:nil waitUntilDone:NO];
	}
}

-(void)update
{
//	IN_ASSERT([NSThread isMainThread]);

	id NewParam=[self copyProcessParam];
	if(IsDataThread()){
		[self makeRequest:NewParam];
	}
	else{
		[self performSelector:@selector(makeRequest:) onThread:gDataThread withObject:NewParam waitUntilDone:NO];
	}
}

-(void)refresh:(id)Param
{
	[self outputData:nil];
	[self makeRequest:Param];
}
-(void)refresh
{
//	IN_ASSERT([NSThread isMainThread]);
	id NewParam=[self copyProcessParam];
	if(IsDataThread()){
		[self refresh:NewParam];
	}
	else{
		[self performSelector:@selector(refresh:) onThread:gDataThread withObject:NewParam waitUntilDone:NO];
	}
}

-(void)load:(id)Param
{
	if(self.isInProgress)
		return;
	if(self.data!=nil){
		if(netError==nil){
			return;
		}
	}
	[self makeRequest:Param];
}

-(void)load
{
//	IN_ASSERT([NSThread isMainThread]);
	id NewParam=[self copyProcessParam];
	if(IsDataThread()){
		[self load:NewParam];
	}
	else{
		[self performSelector:@selector(load:) onThread:gDataThread withObject:NewParam waitUntilDone:NO];
	}
}


-(void)loadCache:(id)Param
{
	if(self.isInProgress)
		return;
	if(self.data!=nil){
		if(netError==nil){
			return;
		}
	}
	
	[self createRequest];
	self.netRequest=nil;
}

-(void)loadCache
{
//	IN_ASSERT([NSThread isMainThread]);
	id NewParam=[self copyProcessParam];
	if(IsDataThread()){
		[self loadCache:NewParam];
	}
	else{
		[self performSelector:@selector(loadCache:) onThread:gDataThread withObject:NewParam waitUntilDone:NO];
	}
}


@end

#pragma mark Page

@implementation INetDataPageControl
{
	id RequestintParam;

	std::vector<bool> PageNeedLoad;
}

-(void)netRequestCompletion:(INetRequest*)sender error:(NSError*)error
{
	[super netRequestCompletion:sender error:error];
	if(_requestingPage<PageNeedLoad.size()){
		PageNeedLoad[_requestingPage]=false;
	}
}

#pragma mark -

-(void)setHasMorePage:(bool)Value
{
	_hasMorePage=Value;
}

-(int)pageCount
{
	return static_cast<int>(PageNeedLoad.size());
}

-(void)setPageCount:(int)Count
{
	auto Index=PageNeedLoad.size();
	PageNeedLoad.resize(Count);
	while(Index<Count){
		PageNeedLoad[Index]=true;
		Index++;
	}
}

#pragma mark -

-(void)clear
{
	IN_ASSERT([NSThread isMainThread]);

	if(IsDataThread()){
		[self stopRequest];
	}
	else{
		[self performSelector:@selector(clearResult) onThread:gDataThread withObject:nil waitUntilDone:NO];
	}
}

-(void)update:(id)Param
{
	_requestingPage=0;
	RequestintParam=Param;
	[self setNeedsUpdate_Func];
	[self makeRequest:Param];
}

-(void)update
{
//	IN_ASSERT([NSThread isMainThread]);

	id NewParam=[self copyProcessParam];
	if(IsDataThread()){
		[self update:NewParam];
	}
	else{
		[self performSelector:@selector(update:) onThread:gDataThread withObject:NewParam waitUntilDone:NO];
	}
}

-(void)refresh:(id)Param
{
	[self outputData:nil];
	self.pageCount=0;
	_requestingPage=0;
	RequestintParam=Param;
	[self makeRequest:Param];
}
-(void)refresh
{
//	IN_ASSERT([NSThread isMainThread]);
	id NewParam=[self copyProcessParam];
	if(IsDataThread()){
		[self refresh:NewParam];
	}
	else{
		[self performSelector:@selector(refresh:) onThread:gDataThread withObject:NewParam waitUntilDone:NO];
	}
}

-(void)load:(id)Param
{
	if(self.isInProgress)
		return;
	if(self.data!=nil){
		if(netError==nil){
			return;
		}
	}
	self.pageCount=0;
	_requestingPage=0;
	RequestintParam=Param;
	[self makeRequest:Param];
}

-(void)load
{
//	IN_ASSERT([NSThread isMainThread]);
	id NewParam=[self copyProcessParam];
	if(IsDataThread()){
		[self load:NewParam];
	}
	else{
		[self performSelector:@selector(load:) onThread:gDataThread withObject:NewParam waitUntilDone:NO];
	}
}

-(void)loadMore_func
{
	if(self.isInProgress)
		return;
	if(self.data==nil){
		self.pageCount=0;
		_requestingPage=0;
		[self makeRequest:RequestintParam];
	}
	else{
		if(_hasMorePage==false)
			return;
		_hasMorePage=false;
		_requestingPage=self.pageCount;
		[self makeRequest:RequestintParam];
	}
}

-(void)loadMore
{
//	IN_ASSERT([NSThread isMainThread]);
	if(IsDataThread()){
		[self loadMore_func];
	}
	else{
		[self performSelector:@selector(loadMore_func) onThread:gDataThread withObject:nil waitUntilDone:NO];
	}
}

-(void)setNeedsUpdate_Func
{
	for(size_t i=0,c=PageNeedLoad.size();i<c;i++)
		PageNeedLoad[i]=true;
}

-(void)setNeedsUpdate
{
//	IN_ASSERT([NSThread isMainThread]);
	if(IsDataThread()){
		[self setNeedsUpdate_Func];
	}
	else{
		[self performSelector:@selector(setNeedsUpdate_Func) onThread:gDataThread withObject:nil waitUntilDone:NO];
	}
}

-(void)loadPageAtItemIndex_func:(NSNumber*)ItemIndexObject
{
	if(self.isInProgress)
		return;
	auto ItemIndex=ItemIndexObject.intValue;
	auto PageIndex=static_cast<unsigned int>([self convertItemIndexToPageIndex:ItemIndex]);
	if(PageIndex>=self.pageCount){
		return;
	}

	// load spcified page
	if(PageNeedLoad[PageIndex]==false)
		return;

	_requestingPage=PageIndex;
	[self makeRequest:RequestintParam];

}


-(void)loadPageAtItemIndex:(int)ItemIndex
{
	IN_ASSERT([NSThread isMainThread]);
	if(IsDataThread()){
		[self loadPageAtItemIndex_func:@(ItemIndex)];
	}
	else{
		[self performSelector:@selector(loadPageAtItemIndex_func:) onThread:gDataThread withObject:@(ItemIndex) waitUntilDone:NO];
	}
}

-(int)convertItemIndexToPageIndex:(int)ItemIndex
{
	return 0;
}


#pragma mark progress

-(bool)isLoadingFirst
{
	if(netRequest==nil)
		return false;
	if(self.pageCount!=0)
		return false;
	if(_requestingPage!=0)
		return false;
	return netRequest.isInProgress;
}


@end


