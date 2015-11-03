//
//  INUIProgressControl.h
//  iNetLibrary
//
//  Created by mtour on 13-12-31.
//
//

#import <UIKit/UIKit.h>
#import <iNetLibrary/INetDataModel.h>

// 进度条view接口
@protocol INUI_ProgressView

// 设置是否显示进度动画
@property(nonatomic,assign) bool animating;

// 设置现在是否有数据
-(void)setHasData:(bool)value;

// 设置进度，从0到1
-(void)setProgressValue:(float)value;

@end

// 错误view接口
@protocol INUI_ProgressErrorView

// 注册重试操作回调
-(void)addOnRetry:(id)obj sel:(SEL)sel;
// 注销重试操作回调
-(void)removeOnRetry:(id)obj sel:(SEL)sel;

@end

#pragma mark 进度控制

@interface INUIProgressControl : NSObject

// 更新进度
-(void)updateProgress;

// progressView
//	显示进度的view
@property(nonatomic,retain) UIView<INUI_ProgressView> *progressView;
// errorView
//	显示错误的view
@property(nonatomic,retain) UIView<INUI_ProgressErrorView> *errorView;

@end

#pragma mark 系统进度条

@interface INUISysProgressView : UIView<INUI_ProgressView>

@end


#pragma mark 网络数据进度控制

@interface INUINetProgressControl : INUIProgressControl

// 如果不为空，则此数据对象用于影响<是否有数据>的判断，否则以任意数据判断
@property(nonatomic) INetDataModel *majorData;


// 增加删除数据对象
-(void)addDataControl:(INetDataControl*)DataControl;
-(void)removeDataControl:(INetDataControl*)DataControl;

-(void)addDataRequest:(INetDataRequest*)DataRequest;
-(void)removeDataRequest:(INetDataRequest*)DataRequest;

-(void)addDataPageControl:(INetDataPageControl*)DataControl;
-(void)removeDataPageControl:(INetDataPageControl*)DataControl;

@end

