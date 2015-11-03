//
//  Method.h
//  iNetLibrary
//
//  Created by Code009 on 13-11-30.
//
//

#ifdef	__OBJC__
#import <Foundation/Foundation.h>

@interface INSelectorValue : NSObject

+(INSelectorValue*)sel:(SEL)sel;
@property(nonatomic,assign) SEL selector;

@end


#ifdef  __cplusplus
#include <vector>
#import <objc/runtime.h>

#import "Type.h"
#import "Debug.h"


namespace iNetLib{

inline INSelectorValue* INSelector(SEL sel)
{
	return [INSelectorValue sel:sel];
}

#pragma mark selector
template<class MethodType>
struct cSelector;

template<class TRet,class...TArgs>
struct cSelector<TRet (TArgs...)>
{

	static bool Check(id self,SEL sel){
		auto ms=[self methodSignatureForSelector:sel];
		if(ms==nullptr)
			return false;
		return ocType_MethodVerify<TRet (TArgs...)>(ms);
	}
	static bool Check(Class cls,SEL sel){
		auto ms=[cls instanceMethodSignatureForSelector:sel];
		if(ms==nullptr)
			return false;
		return ocType_MethodVerify<TRet (TArgs...)>(ms);
	}

	static TRet Call(id self,SEL sel,TArgs...Args){
		IN_ASSERT([self respondsToSelector:sel]);
		IN_ASSERT(Check(self,sel));


		typedef TRet (*tMethod)(id,SEL,TArgs...);
		tMethod MethodIMP=reinterpret_cast<tMethod>([self methodForSelector:sel]);
		return MethodIMP(self,sel,Args...);
	}
	
	static TRet CallForClass(Class cls,id self,SEL sel,TArgs...Args){
		IN_ASSERT([self isKindOfClass:cls]);
		IN_ASSERT([self respondsToSelector:sel]);
		IN_ASSERT(Check(cls));
	
		typedef TRet (*tMethod)(id Self,SEL Selector,TArgs...);
		tMethod MethodIMP=reinterpret_cast<tMethod>([cls instanceMethodForSelector:sel]);
		return MethodIMP(self,sel,Args...);
	}
};

#pragma mark event
// oEvent
//	objective-c类方法回调
// 例:
//	oEvent<void (int)> e;	// 定义回调指针，调用的类型为 void (int)
// 设定回调的目标为SomeObject的SomeFunction,调用相当于[SomeObject SomeFunction:...];
//	e[SomeObject]=@selector(SomeFunction:);
// 调用
//  if(e!=nil)			// 测试是否为空
//		e(IntParameter);	// 调用,参数为IntParameter

template<class MethodType>
class oEvent;

template<class TRet,class...TArgs>
class oEvent<TRet (TArgs...)>
{
	typedef cSelector<TRet (TArgs...)> tSelector;
	iWeakPointer fObject;
	SEL fSelector;

	struct _InvalidPointer;

	struct Assigner
	{
		oEvent *Owner;
		id Object;

		void operator = (SEL selector){
			if(selector==nil){
				Owner->fObject=nil;
				Owner->fSelector=nil;
				return;
			}
			if([Object respondsToSelector:selector]==false){
				IN_ASSERT(0); // 无效的selector
				return;
			}
			// veryfy selector existence
			if(tSelector::Check(Object,selector)==false){
				IN_ASSERT(0);	// 方法参数不匹配
				return;
			}
			Owner->fSelector=selector;
			Owner->fObject=Object;
		}
	};
public:
	oEvent()=default;
	oEvent(const oEvent &Src)=default;
	oEvent& operator =(const oEvent &Src)=default;

	//	set to null
	oEvent& operator =(_InvalidPointer *){
		fSelector=nil;
		return *this;
	}

	// operator []
	//	get object for assigning class method
	Assigner operator [] (id Object){
		return Assigner{this,Object};
	}

	TRet operator () (TArgs...Args)const{
		typedef cSelector<TRet (TArgs...)> cSel;
		return cSel::Call(fObject,fSelector,Args...);
	}

	// operator pointer
	//	return wether the callback is null
	operator _InvalidPointer* ()const {return (__bridge _InvalidPointer*)fObject;}


};


#pragma mark notify

// Notify list
class ocNotifyPointer;
class ocNotifyListBase
{
protected:
	friend ocNotifyPointer;

	std::vector<ocNotifyPointer*> fPointerList;

	ocNotifyListBase();
	~ocNotifyListBase();

	void AddPointer(ocNotifyPointer *Pointer);
	void RemovePointer(ocNotifyPointer *Pointer);

};

class ocNotifyPointer
{
	iWeakPointer fObject=nil;
	SEL fSelector=nullptr;
	ocNotifyListBase *Caller=nullptr;

	friend ocNotifyListBase;
	template<class T> friend class ocNotifyList;
	template<class T> friend class ocHandlerList;

	struct _InvalidPointer;
public:
	// oEvent
	//	set to null
	ocNotifyPointer();
	~ocNotifyPointer();

	ocNotifyPointer(const ocNotifyPointer &Src);
	ocNotifyPointer& operator =(const ocNotifyPointer &Src);

	struct Assigner{
		ocNotifyPointer *Owner;
		iWeakPointer Object;

		void operator = (SEL Selector);

	};
	// operator []
	//	get object for assigning class method
	Assigner operator [] (id Object);

	//	set to null
	ocNotifyPointer& operator =(_InvalidPointer *);

	// set
	void Receive(ocNotifyListBase *List);
};

template<class MethodType>
class ocNotifyList;

template<class...TArgs>
class ocNotifyList<void (TArgs...)> : protected ocNotifyListBase
{
	typedef id __unsafe_unretained tObject;

 
public:
	// oEvent
	//	set to null
	ocNotifyList()=default;
	~ocNotifyList(){}

	ocNotifyList(const ocNotifyList &Src)=delete;
	ocNotifyList& operator =(const ocNotifyList &Src)=delete;


	void operator () (TArgs...Args)const{
		auto pList=this->fPointerList;
		for(auto p : pList){
			typedef cSelector<void (TArgs...)> tSelector;
			if(p->fObject!=nil && p->fSelector!=nil){
				tSelector::Call(p->fObject,p->fSelector,Args...);
			}
		}
	}

	operator ocNotifyListBase* (){	return this;	}
};

template<class MethodType>
class ocHandlerList;

template<class...TArgs>
class ocHandlerList<bool (TArgs...)> : protected ocNotifyListBase
{
	typedef id __unsafe_unretained tObject;

 
public:
	// oEvent
	//	set to null
	ocHandlerList()=default;
	~ocHandlerList(){}

	ocHandlerList(const ocHandlerList &Src)=delete;
	ocHandlerList& operator =(const ocHandlerList &Src)=delete;


	bool operator () (TArgs...Args)const{
		auto pList=this->fPointerList;
		for(auto p : pList){
			typedef cSelector<bool (TArgs...)> tSelector;
			if(p->fSelector!=nil){
				if(tSelector::Call(p->fObject,p->fSelector,Args...))
					return true;
			}
		}
		return false;
	}

	operator ocNotifyListBase* (){	return this;	}
};




}	//namespace iNetLib

typedef iNetLib::ocNotifyListBase INNotifyList;

#else

typedef void INNotifyList;

#endif	/* __cplusplus */

@interface INNotifyReceiver : NSObject

-(id)initWithTarget:(id)target selector:(SEL)sel;


-(void)setTarget:(id)target  selector:(SEL)sel;
-(void)receive:(INNotifyList*)List;

@end


#endif	// __OBJC__

