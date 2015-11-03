//
//  INUIProgressControl.m
//  iNetLibrary
//
//  Created by mtour on 13-12-31.
//
//

#import "INUIProgressControlSubclass.h"
#import "INetDataControl.h"

using namespace iNetLib;


#pragma mark 进度控制

@implementation INUIProgressControl
{
	UIView<INUI_ProgressView> *fProgressView;
	UIView<INUI_ProgressErrorView> *fErrorView;
	bool fShowProgress;
}
@synthesize errorView=fErrorView;
@synthesize progressView=fProgressView;


-(void)dealloc
{
	if(fErrorView!=nil){
		[fErrorView removeOnRetry:self sel:@selector(retry)];
	}
}

-(void)setErrorView:(UIView<INUI_ProgressErrorView> *)errorView
{
	if(fErrorView!=nil){
		[fErrorView removeOnRetry:self sel:@selector(retry)];
	}
	
	fErrorView=errorView;
	
	if(fErrorView!=nil){
		[fErrorView addOnRetry:self sel:@selector(retry)];
	}
}

-(bool)showProgress
{
	return fShowProgress;
}

-(void)setShowProgress:(bool)showProgress
{
	if(fShowProgress==showProgress)
		return;
	fShowProgress=showProgress;
	if(fShowProgress){
		[fProgressView setProgressValue:0];
		fProgressView.animating=true;
	}
	else{
		fProgressView.animating=false;
	}
}


-(void)updateProgress
{
	bool NeedRetry=self.needRetry;
	bool DataIsInProgress=self.isInProgress;

	if(self.hasProgressValue){
		[fProgressView setProgressValue:self.progressValue];
	}
	else{
		[fProgressView setProgressValue:0.];
	}
	if(DataIsInProgress==false){
		// 未加载
		if(NeedRetry){
			// 需要重试，提出错误view
			fErrorView.hidden=false;
			self.showProgress=false;
			fErrorView.hidden=false;
			return;
		}
		else{
			// 没有进度
			fErrorView.hidden=true;
			self.showProgress=false;
		}
	}
	else{
		// 加载中
		fErrorView.hidden=true;
		self.showProgress=true;
	}
}

#pragma mark subclass

-(bool)isIsInProgress
{
	return false;
}

-(bool)hasProgressValue
{
	return false;
}


-(float)progressValue
{
	return 0.0;
}

-(bool)needRetry
{
	return false;
}

-(void)retry
{
}

@end



#pragma mark 系统进度条


@implementation INUISysProgressView
{
	UIActivityIndicatorView *AIView;
	bool Animating;
}

-(id)initWithFrame:(CGRect)frame
{
	self=[super initWithFrame:frame];
	if(self==nil)
		return nil;

	self.alpha=0;
	self.layer.cornerRadius=5;

	self.backgroundColor=[UIColor blackColor];
	AIView=[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	[self addSubview:AIView];
	return self;
}

-(void)setHasData:(bool)value
{
}

-(void)setProgressValue:(float)value
{
	if(Animating==false)
		return;
}

-(void)layoutSubviews
{
	[super layoutSubviews];

	auto Bounds=self.bounds;
	CGSize ViewSize;
	if(Bounds.size.width<=50 || Bounds.size.height<=50){
		ViewSize.width=25;
		ViewSize.height=25;
	}
	else{
		ViewSize.width=50;
		ViewSize.height=50;
	}
	CGRect Frame;
	Frame.origin.x=(Bounds.size.width-ViewSize.width)/2;
	Frame.origin.y=(Bounds.size.height-ViewSize.height)/2;
	Frame.size=ViewSize;
	AIView.frame=Frame;

}

-(bool)animating
{
	return AIView.isAnimating;
}
-(void)setAnimating:(bool)animating
{
	Animating=animating;
	if(Animating==false){
		[AIView stopAnimating];
		[UIView animateWithDuration:0.3 animations:^{
			self.alpha=0;
		}];
	}
	else{
		// 延迟显示
#ifdef	DEBUG
	static const float Delay=0;
#else
		static const float Delay=0.8;
#endif
		[self performSelector:@selector(delayAnimate) withObject:nil afterDelay:Delay];
	}
}
-(void)delayAnimate
{
	if(Animating){
		[UIView animateWithDuration:0.3 animations:^{
			self.alpha = .75f;
		}];
		[AIView startAnimating];
	}
}


@end


#pragma mark 进度控制
@interface INUINetProgressControl()

@end

namespace{
struct cDataControlProgressItem
{
	INetDataControl *Object;
	ocNotifyPointer OnUpdate;
	ocNotifyPointer OnProgressUpdate;
};
struct cDataRequestProgressItem
{
	INetDataRequest *Object;
	ocNotifyPointer OnUpdate;
	ocNotifyPointer OnProgressUpdate;
};
struct cDataIncPageControlProgressItem
{
	INetDataPageControl *Object;
	ocNotifyPointer OnUpdate;
	ocNotifyPointer OnProgressUpdate;
};
}	// namespace anonymous

@implementation INUINetProgressControl
{
	std::vector<cDataControlProgressItem*> fControlList;
	std::vector<cDataRequestProgressItem*> fRequestList;
	std::vector<cDataIncPageControlProgressItem*> fIncPageControlList;
}
@synthesize hasProgressValue;
@synthesize needRetry;
@synthesize progressValue;
@synthesize isInProgress;

-(void)dealloc
{
	for(auto *Item : fControlList){
		delete Item;
	}
	for(auto *Item : fRequestList){
		delete Item;
	}
}

-(void)addDataControl:(INetDataControl *)DataControl
{
	auto *Item=new cDataControlProgressItem;
	Item->Object=DataControl;
	Item->OnUpdate[self]=@selector(onDataUpdate);
	Item->OnProgressUpdate[self]=@selector(onProgressUpdate);
	Item->OnUpdate.Receive(Item->Object.onUpdate);
	Item->OnProgressUpdate.Receive(Item->Object.onProgress);
	// 添加
	fControlList.push_back(Item);
	
	[self onDataUpdate];
}

-(void)removeDataControl:(INetDataControl *)DataControl
{
	// 搜索目标对象
	for(auto pItem=fControlList.begin();pItem!=fControlList.end();pItem++){
		if((*pItem)->Object==DataControl){
			// 删除
			
			fControlList.erase(pItem);
			break;
		}
	}
}

-(void)addDataRequest:(INetDataRequest *)DataRequest
{
	auto *Item=new cDataRequestProgressItem;
	Item->Object=DataRequest;
	Item->OnUpdate[self]=@selector(onDataUpdate);
	Item->OnProgressUpdate[self]=@selector(onProgressUpdate);
	Item->OnUpdate.Receive(Item->Object.onUpdate);
	Item->OnProgressUpdate.Receive(Item->Object.onProgress);
	// 添加
	fRequestList.push_back(Item);
	
	[self onDataUpdate];
}

-(void)removeDataRequest:(INetDataRequest *)DataRequest
{
	// 搜索目标对象
	for(auto pItem=fRequestList.begin();pItem!=fRequestList.end();pItem++){
		if((*pItem)->Object==DataRequest){
			// 删除
			fRequestList.erase(pItem);
			break;
		}
	}
}

-(void)addDataPageControl:(INetDataPageControl *)DataControl
{
	auto *Item=new cDataIncPageControlProgressItem;
	Item->Object=DataControl;
	Item->OnUpdate[self]=@selector(onDataUpdate);
	Item->OnProgressUpdate[self]=@selector(onProgressUpdate);
	Item->OnUpdate.Receive(Item->Object.onUpdate);
	Item->OnProgressUpdate.Receive(Item->Object.onProgress);
	// 添加
	fIncPageControlList.push_back(Item);
	
	[self onDataUpdate];
}

-(void)removeDataPageControl:(INetDataPageControl *)DataControl
{
	// 搜索目标对象
	for(auto pItem=fIncPageControlList.begin();pItem!=fIncPageControlList.end();pItem++){
		if((*pItem)->Object==DataControl){
			// 删除
			fIncPageControlList.erase(pItem);
			break;
		}
	}
}

-(void)onProgressUpdate
{
	bool HasData=false;
	if(fControlList.size()>0){
		for(auto *Item : fControlList){
			if(Item->Object.isInProgress){
				// 有数据在进度中
				isInProgress=true;
				// 显示进度
				auto v=Item->Object.progressValue;
				if(v<1.0){
					progressValue=Item->Object.progressValue;
					[self updateProgress];
					return;
				}
			}
		}
		// 判断是否有数据
		HasData=fControlList[0]->Object.data!=nil;
	}
	else if(fIncPageControlList.size()>0){
		// 判断是否有数据
		HasData=fIncPageControlList[0]->Object.data!=nil;
	}
	if(_majorData!=nil){
		// 判断是否有数据
		HasData=_majorData.data!=nil;
	}
	// 设置数据标志
	[self.progressView setHasData:HasData];
	if(isInProgress){
		progressValue=1.f;
	}
	else{
		progressValue=0.f;
	}
	// 更新进度
	[self updateProgress];
}

-(void)onDataUpdate
{
	needRetry=false;
	isInProgress=false;
	for(auto *Item : fControlList){
		if(Item->Object.isInProgress){
			isInProgress=true;
		}
		if(Item->Object.netError){
			needRetry=true;
		}
	}
	for(auto *Item : fRequestList){
		if(Item->Object.isInProgress){
			isInProgress=true;
		}
	}
	for(auto *Item : fIncPageControlList){
		if(Item->Object.isLoadingFirst){
			isInProgress=true;
		}
		if(Item->Object.pageCount==0 && Item->Object.netError){
			needRetry=true;
		}
	}

	[self onProgressUpdate];
}

-(void)retry
{
	for(auto *Item : fControlList){
		if(Item->Object.netError){
			[Item->Object update];
		}
	}
}

@end
