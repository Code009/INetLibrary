//
//  INetHTTPRequest.h
//  iNetLibrary
//
//  Created by Code009 on 13-11-30.
//
//

#import <Foundation/Foundation.h>

#import <iNetLibrary/INetRequestQueue.h>

// HTTP POST multiple part 数据字段
@interface INetHTTPMutipartDataFormItem : NSObject

@property(nonatomic,retain) NSString *fileName;
@property(nonatomic,retain) id content;	// 数据内容，NSString或NSData
@property(nonatomic,retain) NSString *contentType;

+(INetHTTPMutipartDataFormItem*)string:(NSString*)String;
+(INetHTTPMutipartDataFormItem*)data:(NSData*)data;
+(INetHTTPMutipartDataFormItem*)file:(NSString*)filename data:(NSData*)data;
@end

// http 请求
@interface INetHTTPRequest : INetQueuedRequest

// url
@property(nonatomic,retain) NSURL *destURL;

// URLRequest对象
@property(nonatomic,readonly) NSMutableURLRequest *request;

// POST multiple part 数据
@property(nonatomic,retain) NSDictionary *multipartDict;

// 网络错误
@property(nonatomic,readonly) NSError *error;

// http返回对象
@property(nonatomic,readonly) NSHTTPURLResponse *response;

// 是否有缓存
@property(nonatomic,readonly) bool cached;

@end
