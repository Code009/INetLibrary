//
//  INUIPageScrollView.h
//  iNetLibrary
//
//  Created by 韦晓磊 on 14-5-21.
//  Copyright (c) 2014年 . All rights reserved.
//

#import <UIKit/UIKit.h>


@class INUIPageScrollView;
@protocol INUIPageScrollViewDelegate<UIScrollViewDelegate>

@end


@interface INUIPageScrollView : UIScrollView

@property(nonatomic,weak) id<INUIPageScrollViewDelegate> delegate;

-(void)loadPages:(NSArray*)Pages;	// UIView

@end

