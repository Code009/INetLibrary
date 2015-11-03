//
//  Method.m
//  iNetLibrary
//
//  Created by Code009 on 13-11-30.
//
//

#import "Method.h"

using namespace iNetLib;

#pragma mark -

@implementation INSelectorValue
{
	SEL selector;
}

@synthesize selector;

+(INSelectorValue*)sel:(SEL)sel
{
	auto r=[[INSelectorValue alloc]init];
	r->selector=sel;
	return r;
}


@end


#pragma mark -

ocNotifyListBase::ocNotifyListBase()
{
}
ocNotifyListBase::~ocNotifyListBase()
{
	for(auto p : fPointerList){
		if(p!=nullptr)
			p->Caller=nullptr;
	}
}

void ocNotifyListBase::AddPointer(ocNotifyPointer *Pointer)
{
	auto item=std::find(fPointerList.begin(), fPointerList.end(), Pointer);
	if(item!=fPointerList.end())
		return;	// 已经存在

	if(Pointer->Caller!=nullptr)
		Pointer->Caller->RemovePointer(Pointer);
	Pointer->Caller=this;
	fPointerList.push_back(Pointer);
}

void ocNotifyListBase::RemovePointer(ocNotifyPointer *Pointer)
{
	auto item=std::find(fPointerList.begin(), fPointerList.end(), Pointer);
	if(item==fPointerList.end())
		return;

	fPointerList.erase(item);
	Pointer->Caller=nullptr;
}

ocNotifyPointer::ocNotifyPointer(){
}

ocNotifyPointer::~ocNotifyPointer()
{
	if(Caller!=nullptr){
		Caller->RemovePointer(this);
	}
}
ocNotifyPointer::ocNotifyPointer(const ocNotifyPointer &Src)
{
	fObject=Src.fObject;
	fSelector=Src.fSelector;
	Receive(Src.Caller);
}
ocNotifyPointer& ocNotifyPointer::operator =(const ocNotifyPointer &Src)
{
	fObject=Src.fObject;
	fSelector=Src.fSelector;
	Receive(Src.Caller);
	return *this;
}
void ocNotifyPointer::Assigner::operator = (SEL Selector)
{
	if(Selector==nil){
		Owner->fObject=nil;
		Owner->fSelector=nil;
		return;
	}
	IN_ASSERT([Object respondsToSelector:Selector]);
	Owner->fSelector=Selector;
	Owner->fObject=Object;
}
ocNotifyPointer::Assigner ocNotifyPointer::operator [] (id Object)
{
	Assigner t{this,Object};
	return t;
}
ocNotifyPointer& ocNotifyPointer::operator =(_InvalidPointer *)
{
	fObject=nil;
	fSelector=nil;
	return *this;
}


void ocNotifyPointer::Receive(ocNotifyListBase *List)
{
	if(List!=nullptr){
		List->AddPointer(this);
	}
	else if(Caller!=nullptr){
		Caller->RemovePointer(this);
	}
}

#pragma mark -

@implementation INNotifyReceiver
{
	ocNotifyPointer pt;
}

-(id)initWithTarget:(id)target selector:(SEL)sel
{
	self=[super init];
	if(self!=nil){
		pt[target]=sel;
	}
	return self;
}

-(void)setTarget:(id)target  selector:(SEL)sel
{
	pt[target]=sel;
}

-(void)receive:(INNotifyList*)List
{
	pt.Receive(List);
}

@end
