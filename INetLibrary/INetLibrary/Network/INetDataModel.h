//
//  INetDataModel.h
//  iNetLibrary
//
//  Created by Code009 on 13-11-30.
//
//

#import <Foundation/Foundation.h>

#import <iNetLibrary/Method.h>

@interface INetDataObject : NSObject

@property(nonatomic,retain,readonly) NSDate *updateDate;

@end

#pragma mark -

typedef void (^UpdateBlock)(void);

@interface INetDataModel : NSObject

// 参数
@property(nonatomic,readonly,retain) NSObject *param;
// 数据内容
@property(nonatomic,readonly,retain) INetDataObject *data;

// 上一个请求是否完成
@property(nonatomic,readonly) bool isCompleted;

// 网络错误
@property(nonatomic,readonly) NSError *netError;

// 更新通知
// void (void)
@property(readonly) INNotifyList *onUpdate;

// 更新进度
@property(readonly) INNotifyList *onProgress;
// 是否正在下载中
@property(nonatomic,readonly) bool isInProgress;

// 进度值，从0到1
@property(nonatomic,readonly) float progressValue;

@end


@interface INetDataRequest : INetDataModel

// 启动请求
-(bool)request;

@end

@interface INetDataControl : INetDataModel

// 刷新：清空当前数据，并重新下载
-(void)refresh;

// 更新：下载数据然后替换原内容
-(void)update;

// 加载：如果无数据则下载，否则不做操作
-(void)load;

// 清空：清除所有数据
-(void)clear;

// 加载缓存：只尝试加载缓存数据
-(void)loadCache;

@end

@interface INetDataPageControl : INetDataModel

// 刷新：清空当前数据，并重新下载
-(void)refresh;

// 更新：下载数据然后替换原内容
-(void)update;

// 加载：如果无数据则下载，否则不做操作
-(void)load;

// 清空：清除所有数据
-(void)clear;

// 重置下载标志：让loadPageAtItemIndex方法重新加载内容
-(void)setNeedsUpdate;
// 重新加载特定项目所在页面的内容
-(void)loadPageAtItemIndex:(int)ItemIndex;
// 加载更多页面，如果hasMorePage为真
-(void)loadMore;
// 是否还有更多页面可以加载
@property(nonatomic,assign,readonly) bool hasMorePage;

// 是否正在进行首次加载
@property(nonatomic,assign,readonly) bool isLoadingFirst;


@end



