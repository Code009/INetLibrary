//
//  INetDataControl.h
//  iNetLibrary
//
//  Created by Code009 on 13-11-30.
//
//

#import <Foundation/Foundation.h>

#import <iNetLibrary/INetDataModel.h>
#import <iNetLibrary/INetRequest.h>

@interface INetDataObject()
// 数据更新时间
@property(nonatomic,retain) NSDate *updateDate;
@end


@interface INetDataModel() <INetRequestDelegate>

@property (nonatomic,retain) NSObject *param;

// 处理中的参数的副本
@property(nonatomic,retain) id processingParam;
// 请求状态，用于多段请求.在此标识不为0时，持续进行请求
@property(nonatomic,assign) int requestState;
// 网络请求对象
@property(nonatomic,retain) INetRequest *netRequest;

// 输出数据 必须在数据线程中调用
-(void)outputData:(INetDataObject*)NewData;
// 调用通知 必须在数据线程中调用
-(void)callUpdate;
// 启动请求 必须在数据线程中调用
-(void)makeRequest:(id)param;
// 清除数据, 必须在数据线程中调用
-(void)clearResult;

// subclass -  需要子类重写的内容,不需要调用super
+(Class)paramClass;		// 返回参数的class，如果不重写，则自动获取param属性的类型
-(void)createRequest;	// 子类创建网络请求并赋值给netRequest属性。在数据线程中执行
-(void)processResponse;	// 网络请求处理完毕，通知子类处理网络返回的数据。在数据线程中执行

@end


@interface INetDataRequest()

@end

@interface INetDataControl()

@end

@interface INetDataPageControl()

// 请求中的页号
@property(nonatomic,assign,readonly) int requestingPage;
// 是否有更多页的标志，用于判断是否加载在更多页面
@property(nonatomic,assign) bool hasMorePage;
// 当前已知的页数，用于整理页面加载标志
@property(nonatomic,assign) int pageCount;

// subclass -  需要子类重写的内容,不需要调用super

-(int)convertItemIndexToPageIndex:(int)ItemIndex;	// 获取项目Index对应的页号

@end
