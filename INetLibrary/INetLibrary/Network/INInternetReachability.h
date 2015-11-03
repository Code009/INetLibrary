//
//  INInternetReachability.h
//  iNetLibrary
//
//  Created by Code009 on 13-11-30.
//
//

#import <Foundation/Foundation.h>

#import <iNetLibrary/Method.h>

@interface INInternetReachability : NSObject

//Start listening for reachability notifications on the current run loop
- (BOOL) startNotifier;
- (void) stopNotifier;

// 通知网络连接状况变化
@property (readonly) INNotifyList *onReachabilityChanged;	// void (void)
// 网络是否可用
@property(nonatomic,readonly) bool internetReachable;

@end
