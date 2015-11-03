//
//  Type.cpp
//  iNetLibrary
//
//  Created by Code009 on 13-11-30.
//
//

#include "Type.h"

using namespace iNetLib;


template<>	auto iNetLib::OCDataCast(id Value)	-> int
{
	if(Value==nil)
		return 0;
	// null
	if(Value==[NSNull null])
		return 0;
	// number
	if([Value isKindOfClass:[NSNumber class]]){
		auto nv=(NSNumber*)Value;
		return [nv intValue];
	}
	// string
	if([Value isKindOfClass:[NSString class]]){
		auto str=(NSString*)Value;
		return [str intValue];
	}
	
	return 0;
}

template<>	auto iNetLib::OCDataCast(id Value)	-> unsigned int
{
	if(Value==nil)
		return 0;
	// null
	if(Value==[NSNull null])
		return 0;
	// number
	if([Value isKindOfClass:[NSNumber class]]){
		auto nv=(NSNumber*)Value;
		return [nv unsignedIntValue];
	}
	// string
	if([Value isKindOfClass:[NSString class]]){
		auto str=(NSString*)Value;
		return static_cast<unsigned int>([str integerValue]);
	}
	
	return 0;
}
template<>	auto iNetLib::OCDataCast(id Value)	-> long long
{
	if(Value==nil)
		return 0;
	// null
	if(Value==[NSNull null])
		return 0;
	// number
	if([Value isKindOfClass:[NSNumber class]]){
		auto nv=(NSNumber*)Value;
		return [nv longLongValue];
	}
	// string
	if([Value isKindOfClass:[NSString class]]){
		auto str=(NSString*)Value;
		return [str longLongValue];
	}
	
	return 0;
}

template<>	auto iNetLib::OCDataCast(id Value)	-> unsigned long long
{
	if(Value==nil)
		return 0;
	// null
	if(Value==[NSNull null])
		return 0;
	// number
	if([Value isKindOfClass:[NSNumber class]]){
		auto nv=(NSNumber*)Value;
		return [nv unsignedLongLongValue];
	}
	// string
	if([Value isKindOfClass:[NSString class]]){
		auto str=(NSString*)Value;
		return static_cast<unsigned long long>([str longLongValue]);
	}
	
	return 0;
}

template<>	auto iNetLib::OCDataCast(id Value)	-> float
{
	if(Value==nil)
		return 0.f;
	// null
	if(Value==[NSNull null])
		return 0.f;
	
	// number
	if([Value isKindOfClass:[NSNumber class]]){
		auto nv=(NSNumber*)Value;
		return [nv floatValue];
	}
	// string
	if([Value isKindOfClass:[NSString class]]){
		auto str=(NSString*)Value;
		return [str floatValue];
	}
	
	return 0.f;
}

template<>	auto iNetLib::OCDataCast(id Value)	-> double
{
	if(Value==nil)
		return 0.;
	// null
	if(Value==[NSNull null])
		return 0.;
	
	// number
	if([Value isKindOfClass:[NSNumber class]]){
		auto nv=(NSNumber*)Value;
		return [nv doubleValue];
	}
	// string
	if([Value isKindOfClass:[NSString class]]){
		auto str=(NSString*)Value;
		return [str doubleValue];
	}
	
	return 0.;
}


template<>	auto iNetLib::OCDataCast(id Value)	-> bool
{
	if(Value==nil)
		return false;
	// null
	if(Value==[NSNull null])
		return false;
	// number
	if([Value isKindOfClass:[NSNumber class]]){
		auto nv=(NSNumber*)Value;
		return [nv boolValue];
	}
	// string
	if([Value isKindOfClass:[NSString class]]){
		auto str=(NSString*)Value;
		if([str isEqualToString:@"true"])
			return true;
		// NSString的bool分析不合适
		return [str intValue];
	}
	
	return false;
}

template<>	auto iNetLib::OCDataCast(id Value)	-> __strong NSNumber*
{
	if(Value==nil)
		return nil;
	// null
	if(Value==[NSNull null])
		return nil;
		
	if([Value isKindOfClass:[NSNumber class]]){
		return (NSNumber*)Value;
	}
	return nil;
}

template<>	auto iNetLib::OCDataCast(id Value)	-> __strong NSString*
{
	if(Value==nil)
		return nil;
	// null
	if(Value==[NSNull null])
		return nil;
		
	if([Value isKindOfClass:[NSNumber class]]){
		auto nv=(NSNumber*)Value;
		return [nv stringValue];
	}
	// string
	if([Value isKindOfClass:[NSString class]]){
		return (NSString*)Value;
	}
	
	return nil;
}

template<>	auto iNetLib::OCDataCast(id Value)	-> __strong NSArray*
{
	if(Value==nil)
		return nil;
	if([Value isKindOfClass:[NSArray class]]){
		return (NSArray*)Value;
	}
	return nil;
}

template<>	auto iNetLib::OCDataCast(id Value)	-> __strong NSDictionary*
{
	if(Value==nil)
		return nil;
	if([Value isKindOfClass:[NSDictionary class]]){
		return (NSDictionary*)Value;
	}
	return nil;
}
template<>	auto iNetLib::OCDataCast(id Value)	-> __strong NSMutableDictionary*
{
	if(Value==nil)
		return nil;
	if([Value isKindOfClass:[NSMutableDictionary class]]){
		return (NSMutableDictionary*)Value;
	}
	return nil;
}

template<>	auto iNetLib::OCDataCast(id Value)	-> char
{
	return OCDataCast<int>(Value);
}

template<>	auto iNetLib::OCDataCast(id Value)	-> short
{
	return OCDataCast<int>(Value);
}

template<>	auto iNetLib::OCDataCast(id Value)	-> long
{
	return OCDataCast<int>(Value);
}

template<>	auto iNetLib::OCDataCast(id Value)	-> unsigned char
{
	return OCDataCast<unsigned int>(Value);
}

template<>	auto iNetLib::OCDataCast(id Value)	-> unsigned short
{
	return OCDataCast<unsigned int>(Value);
}

template<>	auto iNetLib::OCDataCast(id Value)	-> unsigned long
{
	return OCDataCast<unsigned int>(Value);
}


