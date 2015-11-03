//
//  INUINaviTabScrollView.m
//  iNetLibrary
//
//  Created by Code009 on 14-6-28.
//  Copyright (c) 2014年 Code009. All rights reserved.
//

#import "INUINaviTabScrollView.h"

void MoveView(UIView *NewParent,UIView *View){
	auto Frame=[NewParent convertRect:View.frame fromView:View.superview];
	[View removeFromSuperview];
	View.frame=Frame;
	[NewParent addSubview:View];
}


@interface INUINaviTabScrollView()<UIScrollViewDelegate>
@end

@implementation INUINaviTabScrollView
{
	// 当前页面
	NSInteger PageIndex;
	
	float ScrollViewWidth;

	// 当前活动状态的scrollview
	UIScrollView *ActiveScrollView;
	// 记录上次活动的位置
	CGPoint ActiveLastOffset;
	
	// 导航标签Y位置
	float NavigatorBottom;
	float NavigatorStayBottom;
	
	bool NavigatorInSelf;
	int PageScrollAnimating;
	bool DisableUpdatePosition;
}

static bool operator !=(const UIEdgeInsets &v1,const UIEdgeInsets &v2)
{
	if(v1.top!=v2.top)
		return true;
	if(v1.left!=v2.left)
		return true;
	if(v1.right!=v2.right)
		return true;
	if(v1.bottom!=v2.bottom)
		return true;
	return false;
}

-(void)layoutSubviews
{
	[super layoutSubviews];

	auto SBounds=self.bounds;
	auto Insets=self.contentInset;
	NavigatorStayBottom=_navigatorView.bounds.size.height;

	self.contentSize=CGSizeMake(SBounds.size.width*_subScrollViews.count,SBounds.size.height-Insets.top-Insets.bottom);
	ScrollViewWidth=SBounds.size.width;
}

-(void)hostLayout
{
	auto Insets=self.contentInset;
	NavigatorStayBottom=_navigatorView.bounds.size.height;

	auto SBounds=self.bounds;

	CGRect Frame;
	Frame.origin.x=0;
	Frame.origin.y=-Insets.top;
	Frame.size=SBounds.size;


	
	auto PageInsets=Insets;
	PageInsets.top+=_navigatorView.bounds.size.height+_headerView.bounds.size.height;
	DisableUpdatePosition=true;
	for(UIScrollView *Page in _subScrollViews){
		Page.frame=Frame;
		Page.hidden=false;
		Frame.origin.x+=Frame.size.width;
		if(Page.contentInset!=PageInsets){
			Page.contentOffset=CGPointMake(0, -PageInsets.top);
		};
		Page.contentInset=PageInsets;

		Page.scrollIndicatorInsets=Insets;
		
	}
	DisableUpdatePosition=false;


	[self setupNavigatorViewPosition];
}

-(void)resetSubScrollViewToTop
{
	for(UIScrollView *Page in _subScrollViews){
		auto PageInsets=Page.contentInset;
		CGPoint Offset;
		Offset.x=0;
		Offset.y=-PageInsets.top;
		Page.contentOffset=Offset;
	}
}
#pragma mark sub scroll view

-(void)setSubScrollViews:(NSArray *)subScrollViews
{
	for(UIScrollView *Page in _subScrollViews){
		[Page removeFromSuperview];
	}

	_subScrollViews=[subScrollViews copy];

	for(UIScrollView *Page in _subScrollViews){
		if(Page.delegate==nil)
			Page.delegate=self;
		[self addSubview:Page];
	}
	
	if(PageIndex>=_subScrollViews.count){
		[self setPageIndex:static_cast<unsigned int>(_subScrollViews.count-1)];
	}
	else{
		if(NavigatorInSelf){
			[self.superview addSubview:_headerView];
			[self.superview addSubview:_navigatorView];
		}
		else if(PageIndex<_subScrollViews.count){
			UIScrollView *View=_subScrollViews[PageIndex];
			
			[View addSubview:_headerView];
			[View addSubview:_navigatorView];
		}
		[self setupPage];
	}
}

-(void)setHeaderView:(UIView *)headerView
{
	if(_headerView!=nil){
		[_headerView removeFromSuperview];
	}
	_headerView=headerView;
	if(_headerView!=nil){
		if(NavigatorInSelf){
			[self.superview addSubview:_headerView];
		}
		else if(PageIndex<_subScrollViews.count){
			UIScrollView *View=_subScrollViews[PageIndex];
			
			[View addSubview:_headerView];
		}
	}
}

-(void)setNavigatorView:(UIView *)navigatorView
{
	if(_navigatorView!=nil){
		[_navigatorView removeFromSuperview];
	}
	_navigatorView=navigatorView;
	if(_navigatorView!=nil){
		if(NavigatorInSelf){
			[self.superview addSubview:_navigatorView];
		}
		else if(PageIndex<_subScrollViews.count){
			UIScrollView *View=_subScrollViews[PageIndex];
			
			[View addSubview:_navigatorView];
		}
	}
}

#pragma mark page index

-(NSInteger)pageIndex
{
	return PageIndex;
}

-(void)setPageIndex:(NSInteger)Index
{
	if(PageIndex==Index)
		return;
		
	if(Index<0 || Index>=_subScrollViews.count)
		return;

	[self syncScrollPosition];

	PageIndex=Index;


	// 动画

	MoveView(self.superview,_headerView);
	MoveView(self.superview,_navigatorView);
	NavigatorInSelf=true;

	[UIView animateWithDuration:0.3
		animations:^{
			PageScrollAnimating++;
			auto Insets=self.contentInset;
			
			self.contentOffset=CGPoint{ScrollViewWidth*PageIndex,-Insets.top};
			[self setupPage];
		}
		completion:^(BOOL finished) {
			PageScrollAnimating--;
			if(finished)
				[self setupNavigatorViewPosition];
		}
	];

	
}

-(void)setupPage
{
	// 更新页面状态
	ActiveScrollView=_subScrollViews[PageIndex];
	ActiveLastOffset=ActiveScrollView.contentOffset;

	[self setupNavigatorViewPosition];

	[self callPageChangeEvent];
}

#pragma mark sub scroll position

-(void)setupNavigatorViewPosition
{
	CGRect Frame=_navigatorView.frame;
	auto HeaderFrame=_headerView.frame;
	HeaderFrame.origin.y=-Frame.size.height-HeaderFrame.size.height;

	float ActiveScrollY=ActiveScrollView.contentOffset.y;
	
	float SelfInsetTop=self.contentInset.top;
	
	if(ActiveScrollY<=-SelfInsetTop-Frame.size.height){
		// 导航条已完整显示
		Frame.origin.y=-Frame.size.height;
		NavigatorBottom=NavigatorStayBottom;
	}
	else{
		// 导航条部分显示
		Frame.origin.y=ActiveScrollY+NavigatorBottom+SelfInsetTop-Frame.size.height;
	}

	if(NavigatorInSelf){
		// 在前台
		Frame.origin.x=0;
		Frame.origin.y-=ActiveScrollY;
		HeaderFrame.origin.x=0;
		HeaderFrame.origin.y-=ActiveScrollY;
	}
	else{
		// 在内部ScrollView
		Frame.origin.x=self.contentOffset.x-ActiveScrollView.frame.origin.x;
		HeaderFrame.origin.x=Frame.origin.x;
	}
	_navigatorView.frame=Frame;

	// 标题view
	if(PageScrollAnimating){
		// header 紧贴 bar
		HeaderFrame.origin.y=Frame.origin.y-HeaderFrame.size.height;
	}

	_headerView.frame=HeaderFrame;
}

-(void)updateActiveScrollViewPosition
{
	float Delta=ActiveLastOffset.y-ActiveScrollView.contentOffset.y;
	NavigatorBottom+=Delta;
	if(Delta>0){
		if(NavigatorBottom>NavigatorStayBottom)
			NavigatorBottom=NavigatorStayBottom;
	}
	else{
		if(NavigatorBottom<0)
			NavigatorBottom=0;
	}


	ActiveLastOffset=ActiveScrollView.contentOffset;
	
	[self setupNavigatorViewPosition];
}

-(void)updateSubScrollPosition:(UIScrollView *)sv
{
	if(sv!=ActiveScrollView)
		return;

	[self updateActiveScrollViewPosition];
	[self syncScrollPosition];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	[self updateSubScrollPosition:scrollView];
}

#pragma mark scroll position

-(void)syncScrollPosition
{
	if(DisableUpdatePosition)
		return;
	
	float SyncInset=self.contentInset.top+NavigatorStayBottom;
	CGPoint SyncOffset=ActiveLastOffset;
	if(SyncOffset.y>-SyncInset)
		SyncOffset.y=-SyncInset;

	for(UIScrollView *Page in _subScrollViews){
		if(Page==ActiveScrollView){
			continue;
		}
		auto CurOffset=Page.contentOffset;
		if(CurOffset.y<=-SyncInset){
			CurOffset.y=SyncOffset.y;
		}
		Page.contentOffset=CurOffset;
	}

}

-(void)setContentOffset:(CGPoint)contentOffset
{
	[super setContentOffset:contentOffset];
	
	if(ScrollViewWidth==0)
		return;
		
	if(PageScrollAnimating)
		return;

	auto Offset=self.contentOffset;
	
	int Index=0;
	bool NaviSelf=true;
	if(Offset.x>=0){
		float LastX=0;
		float LastPageX=0;
		// 检测激活的页面
		for(unsigned int i=0,c=static_cast<unsigned int>(_subScrollViews.count);i<c;i++){
			float NextX=LastPageX+ScrollViewWidth/2;
			if(LastPageX==Offset.x){
				NaviSelf=false;
			}
			if(LastX<=Offset.x){
				if(NextX > Offset.x){
					break;
				}
			}
			LastX=LastPageX+ScrollViewWidth/2;
			LastPageX+=ScrollViewWidth;
			Index++;
		}
	}

	// 同步其他scroll
	//[self syncScrollPosition];

	if(Index>=_subScrollViews.count)
		Index=static_cast<int>(_subScrollViews.count-1);
	
	if(NavigatorInSelf!=NaviSelf){
		NavigatorInSelf=NaviSelf;
		if(NavigatorInSelf){
			MoveView(self.superview,_headerView);
			MoveView(self.superview,_navigatorView);
		}
		else{
			UIScrollView *View=_subScrollViews[Index];
			MoveView(View,_headerView);
			MoveView(View,_navigatorView);
		}
	}
		
	// 更新页面Index
	if(PageIndex!=Index){
		PageIndex=Index;

		PageScrollAnimating++;
		[self setupNavigatorViewPosition];
		[UIView animateWithDuration:0.3 animations:^{
			[self setupPage];
		} completion:^(BOOL finished) {
			PageScrollAnimating--;
			if(finished)
				[self setupNavigatorViewPosition];
		}];
	}
	else{
		[self setupNavigatorViewPosition];
	}
}

#pragma mark delegate


-(void)callPageChangeEvent
{

	[_naviDelegate onPageChanged];
}

@end
