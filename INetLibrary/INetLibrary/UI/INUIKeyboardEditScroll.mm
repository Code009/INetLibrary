//
//  INUIKeyboardEditScroll.m
//  iNetLibrary
//
//  Created by Code009 on 13-11-30.
//
//

#import "INUIKeyboardEditScroll.h"



using namespace iNetLib;


@implementation INUIKeyboardState

-(id)init
{
	self=[super init];
	if(self){
		NSNotificationCenter *NC=[NSNotificationCenter defaultCenter];
		[NC addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
		[NC addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
		[NC addObserver:self selector:@selector(keyboardHide:) name:UIKeyboardDidHideNotification object:nil];
	}
	
	return self;
}
-(void)dealloc
{
	NSNotificationCenter *NC=[NSNotificationCenter defaultCenter];
	[NC removeObserver:self];
}


-(void)keyboardWillShow:(NSNotification*)notification
{
	_isShowing=true;

	[_delegate keyboardWillShow];
}
-(void)keyboardWillHide:(NSNotification*)notification
{
	[_delegate keyboardWillHide];
}

-(void)keyboardHide:(NSNotification*)notification
{
	_isShowing=false;

	[_delegate keyboardHide];
}


@end

#pragma mark -

// 注册键盘通知
static void RegisterKeyboardNotification(NSObject *self);
// 注销键盘通知
static void UnregisterKeyboardNotification(NSObject *self);


// 搜索当前焦点
static UIView* FindFirstResponsder(UIView *view)
{
	for(UIView *v in view.subviews){
		if(v.isFirstResponder){
			return v;
		}
	}
	for(UIView *v in view.subviews){
		auto sv=(FindFirstResponsder(v));
		if(sv!=nil)
			return sv;
	}
	return nil;
}


#pragma mark -


@implementation INUI_ViewKeyboardReposit
{
	UIView *editView;
	bool editFrameChanged;
	CGRect editOrgFrame;
}

-(void)dealloc
{
	if(editView!=nil){
		NSNotificationCenter *NC=[NSNotificationCenter defaultCenter];
		[NC removeObserver:self];
	}
}


-(UIView *)editView
{
	return editView;
}
-(void)setEditView:(UIView *)view
{
	if(editView==view)
		return;
	
	if(editFrameChanged){
		// restore frame
		editView.frame=editOrgFrame;
	}
	editFrameChanged=false;
	editView=view;
	if(editView!=nil){
		RegisterKeyboardNotification(self);
	}
	else{
		UnregisterKeyboardNotification(self);
	}
	editOrgFrame=editView.frame;
}


-(void)keyboardFrameWillChange:(NSNotification*)notification
{
	if(editView==nil)
		return;
	UIView *TopView=editView.window.rootViewController.view;

	NSDictionary *uinfo=notification.userInfo;
	NSNumber *KBAnimationDurartionValue=uinfo[UIKeyboardAnimationDurationUserInfoKey];
	NSValue *KBRectValue=uinfo[UIKeyboardFrameEndUserInfoKey];
	CGRect KBRect=[TopView convertRect:KBRectValue.CGRectValue fromView:nil];

	CGRect NewFrame;
	// calculate frame
	auto editViewFrame=[TopView convertRect:editView.bounds fromView:editView];
	float EditViewBottom=editViewFrame.origin.y+editViewFrame.size.height;
	if(EditViewBottom>KBRect.origin.y){
		if(editFrameChanged==false){
			editOrgFrame=editView.frame;
		}
		// reposit edit view
		NewFrame=editViewFrame;
		NewFrame.origin.y=KBRect.origin.y-editViewFrame.size.height;
		NewFrame=[editView.superview convertRect:NewFrame fromView:TopView];
		editFrameChanged=true;
	}
	else{
		NewFrame=editOrgFrame;
		editFrameChanged=false;
	}
	// 动画
	[UIView animateWithDuration:KBAnimationDurartionValue.floatValue
		animations:^{
			editView.frame=NewFrame;
		}
	];

}
@end


#pragma mark -

@implementation INUI_TextEditKeyboardScroll
{
	float ScrollInsetBottom;
	UIScrollView *scrollView;
	CGRect KeyboardRect;
}

auto *iNetLib::gTextEditKeyboardScroll=[[INUI_TextEditKeyboardScroll alloc]init];

-(void)dealloc
{
	if(scrollView!=nil){
		NSNotificationCenter *NC=[NSNotificationCenter defaultCenter];
		[NC removeObserver:self];
	}
}

-(void)attachScrollView:(UIScrollView*)ScrollView
{
	if(scrollView!=nil){
		[self cleanupScrollView];
	}
	scrollView=ScrollView;
	RegisterKeyboardNotification(self);
	_focusBottomSpace=0;
	_focusBaseContentY=0;

}

-(void)cleanupScrollView
{
	// restore edge
	UIEdgeInsets OrgEdge=scrollView.contentInset;
	OrgEdge.bottom-=ScrollInsetBottom;
	ScrollInsetBottom=0;
	scrollView.contentInset=OrgEdge;
	UnregisterKeyboardNotification(self);
}
-(void)detachScrollView:(UIScrollView*)ScrollView
{
	if(scrollView!=ScrollView)
		return;

	[self cleanupScrollView];
	scrollView=nil;

}

-(UIScrollView *)scrollView
{
	return scrollView;
}
-(void)setScrollView:(UIScrollView *)view
{
	if(scrollView!=nil){
	}
	scrollView=view;
	if(scrollView!=nil){
	}
	else{
	}
}

-(void)keyboardFrameWillChange:(NSNotification*)notification
{
	NSDictionary *uinfo=notification.userInfo;
	NSNumber *KBAnimationDurartionValue=uinfo[UIKeyboardAnimationDurationUserInfoKey];
	NSValue *KBRectValue=uinfo[UIKeyboardFrameEndUserInfoKey];

	// find currently focused view
	UIView *FocusedView=FindFirstResponsder(scrollView);
	KeyboardRect=KBRectValue.CGRectValue;
	
	[self adjustScrollViewForInput:FocusedView animationDuration:KBAnimationDurartionValue.floatValue];
}

-(void)adjustScrollViewForInput:(UIView*)FocusedView animationDuration:(float)AnimationDuration
{
	auto ScrollView=scrollView;
	if(ScrollView==nil)
		return;

	UIViewController *TopVC=ScrollView.window.rootViewController;
	UIView *TopView=TopVC.presentedViewController.view;
	if(TopView==nil)
	{
		TopView=TopVC.view;
	}
	CGRect KBRect=[TopView convertRect:KeyboardRect fromView:nil];

	auto ScrollViewBounds=ScrollView.bounds;

	bool NeedScroll=false;	// flag scroll view needs to scroll to NewContentOffset
	CGPoint NewContentOffset=ScrollView.contentOffset;

	// calculate scroll inset
	CGRect ScrollViewFrameInTop=[TopView convertRect:ScrollViewBounds fromView:ScrollView];
	float NewScrollInsetBottom;
	{
		float ScrollViewBotttom=ScrollViewFrameInTop.origin.y+ScrollViewFrameInTop.size.height;
		NewScrollInsetBottom=ScrollViewBotttom-KBRect.origin.y;
		if(NewScrollInsetBottom<0){
			NewScrollInsetBottom=0;
		}
	}
	// test if inset changed
	float DeltaScrollInsetBottom=NewScrollInsetBottom-ScrollInsetBottom;
	UIEdgeInsets NewEdge=ScrollView.contentInset;
	if(DeltaScrollInsetBottom!=0){
		NewEdge.bottom+=DeltaScrollInsetBottom;
		// make sure offset not beyond new content size
		float ContentHeight=ScrollView.contentSize.height;
		ContentHeight+=NewEdge.bottom+NewEdge.top;
		float ScrollViewHeight=ScrollViewBounds.size.height;
		float OffsetBottom=ContentHeight-ScrollViewHeight;
		if(OffsetBottom<0)
			OffsetBottom=0;
		if(NewContentOffset.y>OffsetBottom){
			//  new content offset
			NewContentOffset.y=OffsetBottom;
			// scroll needs to scroll back
			NeedScroll=true;
		}
	}

	if(FocusedView!=nil){
		// test if view is covered by keyboard
		CGRect FocusedFrame=[ScrollView convertRect:FocusedView.bounds fromView:FocusedView];
		float FocusedBottom=FocusedFrame.origin.y+FocusedFrame.size.height;
		FocusedBottom+=_focusBottomSpace;

		float KBY=KBRect.origin.y-ScrollViewFrameInTop.origin.y;

		if(FocusedBottom>KBY+NewContentOffset.y){
			// need scroll
			NeedScroll=true;
			// calculate new offset
			NewContentOffset.y=FocusedBottom-KBY;
		}
		auto BaseY=_focusBaseContentY;
		BaseY-=NewEdge.top;
		if(NewContentOffset.y<BaseY){
			NewContentOffset.y=BaseY;
			NeedScroll=true;
		}
	}

	[UIView animateWithDuration:AnimationDuration
		animations:^{
			if(DeltaScrollInsetBottom>0){
				ScrollView.contentInset=NewEdge;
			}
			if(NeedScroll){
				ScrollView.contentOffset=NewContentOffset;
			}
			if(DeltaScrollInsetBottom<0){
				ScrollView.contentInset=NewEdge;
			}
		}
	];


	// save ident
	ScrollInsetBottom=NewScrollInsetBottom;
}

-(void)setKeyboardClosedState
{
	UIView *TopView=scrollView.window.rootViewController.view;
	auto rect=TopView.bounds;
	KeyboardRect.origin.y=rect.size.height;
}

@end


static void RegisterKeyboardNotification(NSObject *self)
{
	NSNotificationCenter *NC=[NSNotificationCenter defaultCenter];
	[NC addObserver:self selector:@selector(keyboardFrameWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
}
static void UnregisterKeyboardNotification(NSObject *self)
{
	// unregister notification
	NSNotificationCenter *NC=[NSNotificationCenter defaultCenter];
	[NC removeObserver:self];
}
