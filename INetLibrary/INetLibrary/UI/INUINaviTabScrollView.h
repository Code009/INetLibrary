//
//  INUI_NaviTabScrollView.h
//  iNetLibrary
//
//  Created by Code009 on 14-6-28.
//  Copyright (c) 2014年 Code009. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol INUINaviTabScrollViewDelegate;

// 多页面滚动标签。详情页用
@interface INUINaviTabScrollView : UIScrollView

// delegate, 另起名避免与UIScrollView的delegate冲突
@property(nonatomic,weak) id<INUINaviTabScrollViewDelegate> naviDelegate;

// 标题view
@property(nonatomic) UIView *headerView;
// 导航标签view
@property(nonatomic) UIView *navigatorView;

// 页面
@property(nonatomic) NSInteger pageIndex;

// 子页面，将以横向布局
@property(nonatomic) NSArray *subScrollViews;
// 子页面滚动位置更新
-(void)updateSubScrollPosition:(UIScrollView*)sv;


-(void)hostLayout;
-(void)resetSubScrollViewToTop;

@end


#pragma mark -

@protocol INUINaviTabScrollViewDelegate

-(void)onPageChanged;

@end
