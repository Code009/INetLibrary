//
//  INUIKeyboardEditScroll.h
//  iNetLibrary
//
//  Created by Code009 on 13-11-30.
//
//

#import <UIKit/UIKit.h>

@protocol INUIKeyboardStateDelegate;

// 接入键盘状态通知
@interface INUIKeyboardState : NSObject

@property (nonatomic,readonly) bool isShowing;
@property (nonatomic,weak) id<INUIKeyboardStateDelegate> delegate;

@end

@protocol INUIKeyboardStateDelegate

-(void)keyboardWillShow;
-(void)keyboardWillHide;
-(void)keyboardHide;

@end

#pragma mark -

// reposit view for keyboard

@interface INUI_ViewKeyboardReposit : NSObject

// 需要置于键盘之上的view
@property (nonatomic,retain) UIView *editView;

@end

#pragma mark -
// scroll text field in scroll view for keyboard

@interface INUI_TextEditKeyboardScroll : NSObject

// 挂接随键盘滚动的ScrollView
-(void)attachScrollView:(UIScrollView*)ScrollView;
// 卸载随键盘滚动的ScrollView
-(void)detachScrollView:(UIScrollView*)ScrollView;

// 滚动时不低于这个Y值
@property(nonatomic,assign) float focusBaseContentY;
// 滚动时的焦点View距离键盘的高度
@property(nonatomic,assign) float focusBottomSpace;

// 手动为指定View滚动
-(void)adjustScrollViewForInput:(UIView*)FocusedView animationDuration:(float)AnimationDuration;

@end



#ifdef	__cplusplus
namespace iNetLib{
// 键盘调整公共对象
extern INUI_TextEditKeyboardScroll *gTextEditKeyboardScroll;
}

#endif
