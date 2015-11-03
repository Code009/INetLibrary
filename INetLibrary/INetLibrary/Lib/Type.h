//
//  Type.h
//  iNetLibrary
//
//  Created by Code009 on 13-11-30.
//
//

#ifdef	__OBJC__

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#ifdef  __cplusplus

#include <type_traits>


namespace iNetLib{

// SafeCast
//	安全的转换oc对象类型，转换前先判断类型是否符合
//	无法安全转换则返回nil
template<class TCast,class IDClass>
inline TCast* SafeCast(IDClass *object)
{
	if([object isKindOfClass:[TCast class]])
		return static_cast<TCast*>(object);
	return nil;
}

namespace _ocType_Helper{
    
    // ocType_IsSame
    //	判断ObjectiveC类型编码是否与T相同
    // [T]T			待检查的类型
    // [in]TypeName	ObjectiveC类型编码
    template<class T>
    inline bool ocType_IsSame(const char *TypeName){
		return strncmp(TypeName,@encode(T),sizeof(@encode(T))-1)==0;
	}

	// ocType_MethodVerify_Argument
	//	验证ObjectiveC方法的参数
	template<size_t Index>
	bool ocType_MethodVerify_Argument(NSMethodSignature *ms)
	{	return true;	}
	
	template<size_t Index,class Arg0Type,class...TArgs>
	bool ocType_MethodVerify_Argument(NSMethodSignature *ms)
	{
		if(ocType_IsSame<Arg0Type>([ms getArgumentTypeAtIndex:Index])==false)
			return false;
		return ocType_MethodVerify_Argument<Index+1,TArgs...>(ms);
	}
	
	// ocType_MethodVerify
	//	ocType_MethodVerify 辅助函数, 比较ObjectiveC函数参数信息是否与模版参数匹配s
	template<class FunctionType>	struct ocType_MethodVerify;
	
	template<class TRet,class...TArgs>
	struct ocType_MethodVerify<TRet (TArgs...)>
	{
		static bool Call(NSMethodSignature *ms){
			// test return type
			if(ocType_IsSame<TRet>([ms methodReturnType])==false)
				return false;
			// test argument count
			if(sizeof...(TArgs)+2!=[ms numberOfArguments])
				return false;
			// test hidden arguments
			if(ocType_IsSame<id>([ms getArgumentTypeAtIndex:0])==false)
				return false;
			if(ocType_IsSame<SEL>([ms getArgumentTypeAtIndex:1])==false)
				return false;
			// test arguments
			return ocType_MethodVerify_Argument<2,TArgs...>(ms);
		}
	};
}	// namespace _ocType_Helper

// ocType_MethodVerify
//	验证ObjectiveC的方法参数类型是否正确
// [T]Function	C函数类型
// [in]ms		ObjectiveC函数类型
template<class FunctionType>
inline bool ocType_MethodVerify(NSMethodSignature *ms)
{
	return _ocType_Helper::ocType_MethodVerify<FunctionType>::Call(ms);
}


// 将NS数据转换成C数据
template<class T>
T OCDataCast(id Value);
    
template<>	auto OCDataCast(id Value)	-> int;
template<>	auto OCDataCast(id Value)	-> unsigned int;
template<>	auto OCDataCast(id Value)	-> long long;
template<>	auto OCDataCast(id Value)	-> unsigned long long;
template<>	auto OCDataCast(id Value)	-> float;
template<>	auto OCDataCast(id Value)	-> double;
template<>	auto OCDataCast(id Value)	-> bool;
template<>	auto OCDataCast(id Value)	-> __strong NSNumber*;
template<>	auto OCDataCast(id Value)	-> __strong NSString*;
template<>	auto OCDataCast(id Value)	-> __strong NSArray*;
template<>	auto OCDataCast(id Value)	-> __strong NSDictionary*;
template<>	auto OCDataCast(id Value)	-> __strong NSMutableDictionary*;
    
template<>	auto OCDataCast(id Value)	-> char;
template<>	auto OCDataCast(id Value)	-> short;
template<>	auto OCDataCast(id Value)	-> long;
template<>	auto OCDataCast(id Value)	-> unsigned char;
template<>	auto OCDataCast(id Value)	-> unsigned short;
template<>	auto OCDataCast(id Value)	-> unsigned long;


// 创建
template<class T>
inline void OCAlloc(T* __strong &Pointer){
	Pointer=[[T alloc]init];
}

}	// namespace iNetLib
#endif	// __cplusplus




#endif /* __OBJC__ */
