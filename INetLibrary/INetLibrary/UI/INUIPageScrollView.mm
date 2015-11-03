//
//  INUIPageScrollView.m
//  iNetLibrary
//
//  Created by 韦晓磊 on 14-5-21.
//  Copyright (c) 2014年 . All rights reserved.
//

#include <vector>
#import "INUIPageScrollView.h"

@interface INUIPageScrollView()<UIScrollViewDelegate>
@end

@implementation INUIPageScrollView
{
	std::vector<UIView*> PageList;
	unsigned int PageCount;

	bool DisablePos;
}
@synthesize delegate=pageDelegate;

static void Construct(INUIPageScrollView *self)
{
	self.showsHorizontalScrollIndicator=FALSE;
	self.showsVerticalScrollIndicator=FALSE;
	self.pagingEnabled=TRUE;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
		[super setDelegate:self];
		Construct(self);
    }
    return self;
}

-(void)awakeFromNib
{
	[super awakeFromNib];
	
	[super setDelegate:self];
	Construct(self);
}

-(void)loadPages:(NSArray *)Pages
{
	PageCount=static_cast<unsigned int>(Pages.count);
	PageList.clear();
	PageList.resize(PageCount);

	for(unsigned int i=0;i<PageCount;i++){
		if(PageList[i]==nil){
			PageList[i]=Pages[i];
			[self addSubview:PageList[i]];
		}
	}
	
	[self layoutPage];
}
-(void)reloadPage
{
}

-(void)layoutPage
{
	if(PageList.size()==0)
		return;
		
	auto Bounds=self.bounds;
	auto PageFrame=Bounds;
	auto Offset=self.contentOffset;
	PageFrame.origin.y-=Offset.y;
	auto Inset=self.contentInset;
	PageFrame.origin.y-=Inset.top;

	int OffsetIndex=int(Offset.x)/int(PageFrame.size.width);
	bool pOffset=int(Offset.x)%int(PageFrame.size.width)!=0;


	int pIndex=OffsetIndex;
	if(pIndex<0){
		pIndex+=PageCount;
	}
	else if(pIndex>=PageCount)
		pIndex%=PageCount;

	for(auto View : PageList){
		View.hidden=true;
	}

	PageFrame.origin.x=OffsetIndex*PageFrame.size.width;
	auto Page1=PageList[pIndex];
	if(Page1!=nil){
		Page1.Frame=PageFrame;
		Page1.hidden=false;
//		[Page1 setInsets:Inset.top :Inset.bottom];
	}
	if(pOffset){
		PageFrame.origin.x+=PageFrame.size.width;
		unsigned int pi2;
		if(pIndex==PageCount-1)
			pi2=0;
		else
			pi2=pIndex+1;
		auto Page2=PageList[pi2];
		if(Page2!=nil){
			Page2.hidden=false;
			Page2.Frame=PageFrame;
//			[Page2 setInsets:Inset.top :Inset.bottom];
		}
	}

}

-(void)layoutSubviews
{
	[super layoutSubviews];

	auto ContentSize=self.bounds.size;
	auto Inset=self.contentInset;
	ContentSize.width*=PageCount+4;
//	ContentSize.width*=PageCount;
	ContentSize.height-=Inset.top+Inset.bottom;
	self.contentSize=ContentSize;

	[self layoutPage];
}

static CGPoint LimitPosition(INUIPageScrollView *self,CGPoint Offset)
{
	float PageWidth=self.bounds.size.width;
	float TotalWidth=PageWidth*self->PageCount;
	if(Offset.x<PageWidth*3/2){
		Offset.x+=TotalWidth;
	}
	else if(Offset.x>TotalWidth+PageWidth/2){
		Offset.x-=TotalWidth;
	}
	return Offset;
}


-(void)setContentOffset:(CGPoint)contentOffset
{
	if(DisablePos==false){
		contentOffset=LimitPosition(self,contentOffset);
	}
	[super setContentOffset:contentOffset];
}

-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
	{
		auto contentOffset=LimitPosition(self,self.contentOffset);
		[super setContentOffset:contentOffset];
	}
	DisablePos=true;
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	DisablePos=false;
}


@end
