//
//  Property.m
//  iNetLibrary
//
//  Created by Code009 on 13-11-30.
//
//

#include <map>
#include <string>

#import "Property.h"

#import "Type.h"
#import "Method.h"

using namespace iNetLib;

// Property_GetAttributeDict
//	获取ObjectiveC属性定义字典
//	属性定义详情请参考ObjectiveC Runtime
static void Property_GetAttributeDict(std::map<char,std::string> &dict, objc_property_t pro)
{
	auto attr=property_getAttributes(pro);

	auto astr=[[NSString alloc]initWithUTF8String:attr];
	auto arr=[astr componentsSeparatedByString:@","];

	for(NSString *item in arr){
		auto str=item.UTF8String;
		dict[str[0]]=std::string(str+1);
	}
}

// ocGetTypeClassProtocolName
//	从ObjectiveC类型名中获取协议表
static NSArray* ocGetTypeClassProtocolName(const char *Type,std::string &cls)
{
	if(Type[0]!='@'){
		// 不是OC类型
		cls.clear();
		return nil;
	}
	Type++;
	size_t TypeLen=strlen(Type);
	if(TypeLen<2 || Type[0]!='\"' || Type[TypeLen-1]!='\"'){
		cls.clear();
		return nil;
	}
	Type++;
	TypeLen-=2;

	unsigned int clsIndex;
	for(clsIndex=0;Type[clsIndex]!='<';clsIndex++){
		if(clsIndex>=TypeLen){
			// class name only
			cls=std::string(Type,TypeLen);
			return nil;
		}
	}
	if(clsIndex!=0)
		cls=std::string(Type,clsIndex);
	else
		cls.clear();
	unsigned int proIndex;
	for(proIndex=clsIndex+1;Type[proIndex]!='>';proIndex++){
		if(clsIndex>=TypeLen){
			// error
			return nil;
		}
	}
	std::string prostr(Type+clsIndex+1,proIndex-clsIndex-1);

	return [[[NSString alloc]initWithUTF8String:prostr.c_str()] componentsSeparatedByString:@","];
}

#pragma mark 属性信息 - OCPropertyInfo


OCPropertyInfo::OCPropertyInfo()
{
	name=nullptr;
	type=nullptr;
}
OCPropertyInfo::~OCPropertyInfo()
{
	if(type!=nullptr)
		free(const_cast<char*>(type));
}
static char *alloc_copy_string(const std::string &s)
{
	size_t size=s.length()+1;
	void *dest=malloc(size);
	memcpy(dest,s.c_str(),size);
	return static_cast<char*>(dest);
}
void OCPropertyInfo::Load(objc_property_t p)
{
	name=property_getName(p);

	std::map<char, std::string> pdict;
	Property_GetAttributeDict(pdict,p);

	if(type!=nullptr)
		free(const_cast<char*>(type));
	type=alloc_copy_string(pdict['T']);
	auto &GetterName=pdict['G'];
	auto &SetterName=pdict['S'];
	if(GetterName.length()>0){
		Getter=sel_getUid(GetterName.c_str());
	}
	else{
		Getter=sel_getUid(name);
	}
	if(pdict.find('R')==pdict.end()){
		if(SetterName.length()>0){
			Setter=sel_getUid(SetterName.c_str());
		}
		else{
			auto SetterName=[[NSString alloc]initWithFormat:@"set%c%s:",toupper(name[0]),name+1];
			Setter=sel_getUid(SetterName.UTF8String);
		}
	}
	else{
		Setter=nil;
	}
}

bool OCPropertyInfo::Load(id Object,const char *PropertyName)
{
	// 获取属性
	auto cls=object_getClass(Object);
	return LoadClassProperty(cls,PropertyName);
}

bool OCPropertyInfo::LoadClassProperty(Class cls,const char *PropertyName)
{
	// 获取属性
	auto pro=class_getProperty(cls,PropertyName);
	if(pro!=nullptr){
		Load(pro);
		return true;
	}
	// 属性不存在
	// 尝试直接获取setter
	size_t PropertyNameLength=strlen(PropertyName);
	if(PropertyNameLength==0){
		// 没有名字
		return false;
	}
	//				set+ pname + : + 0
	char method_name[3+PropertyNameLength+1+1];
	// 警告：此处容易出现缓冲区溢出
	sprintf(method_name,"set%c%.*s:",toupper(PropertyName[0]),
		static_cast<int>(PropertyNameLength-1),PropertyName+1);

	SEL setMethod=sel_getUid(method_name);
	return LoadBySetter(cls,setMethod);
}


bool OCPropertyInfo::LoadBySetter(Class cls,SEL setMethod)
{
	auto ms=[cls instanceMethodSignatureForSelector:setMethod];
	if(ms==nil){
		// 找不到方法
		return false;
	}
	if([ms numberOfArguments]!=3)
		return false;
	const char *ts=[ms getArgumentTypeAtIndex:2];
	if(type!=nullptr)
		free(const_cast<char*>(type));
	type=alloc_copy_string(ts);

	Setter=setMethod;

	// 尝试直接获取getter

	return true;
}


#pragma mark 属性类型
Class iNetLib::OCGetClassByTypeName(const char *type)
{
	std::string cls;
	ocGetTypeClassProtocolName(type,cls);
	return objc_getClass(cls.c_str());
}

#pragma mark 属性

template<class T>
inline void SetPropertyT(id Object,SEL Sel,id Value)
{

	typedef cSelector<void (T)> tSelector;
	IN_ASSERT(tSelector::Check(Object,Sel));

	auto v=OCDataCast<T>(Value);
	tSelector::Call(Object,Sel,v);
}
inline void SetProperty(id Object,SEL Sel,id Value)
{

	typedef cSelector<void (id)> tSelector;


	IN_ASSERT(tSelector::Check(Object,Sel));

	tSelector::Call(Object,Sel,Value);
}
///
namespace{	namespace OCDataTransferFunc{

static id SafeCreateObject(Class cls)
{
	if(class_respondsToSelector(cls,@selector(init))==false){
		return nil;
	}
	return [[cls alloc]init];
}

static bool SetField(id Object,const OCPropertyInfo &PInfo,id Value)
{
	auto ts=PInfo.type;
	auto setMethod=PInfo.Setter;

	switch(ts[0]){
	default:	// 不支持的类型
		return false;
	case 'c':	// char
		SetPropertyT<char>(Object,setMethod,Value);
		break;
	case 'i':	// int
		SetPropertyT<int>(Object,setMethod,Value);
		break;
	case 's':	// short
		SetPropertyT<short>(Object,setMethod,Value);
		break;
	case 'l':	// long
		SetPropertyT<long>(Object,setMethod,Value);
		break;
	case 'q':	// long long
		SetPropertyT<long long>(Object,setMethod,Value);
		break;
	case 'C':	// unsigned char
		SetPropertyT<unsigned char>(Object,setMethod,Value);
		break;
	case 'I':	// unsigned int
		SetPropertyT<unsigned int>(Object,setMethod,Value);
		break;
	case 'S':	// unsigned short
		SetPropertyT<unsigned short>(Object,setMethod,Value);
		break;
	case 'L':	// unsigned long
		SetPropertyT<unsigned long>(Object,setMethod,Value);
		break;
	case 'Q':	// unsigned long long
		SetPropertyT<unsigned long long>(Object,setMethod,Value);
		break;
	case 'f':	// float
		SetPropertyT<float>(Object,setMethod,Value);
		break;
	case 'd':	// double
		SetPropertyT<double>(Object,setMethod,Value);
		break;
	case 'B':	// bool
		SetPropertyT<bool>(Object,setMethod,Value);
		break;
	case '@':	// Object
		{
			std::string ClsName;
			ocGetTypeClassProtocolName(ts,ClsName);
			Class cls;
			if(ClsName.length()==0){
				cls=nil;
			}
			else{
				cls=objc_getClass(ClsName.c_str());
			}
			if(cls!=nullptr){
				// 检查类型
				if([Value isKindOfClass:[NSNull class]]){
					Value=nil;
				}
				else if([Value isKindOfClass:cls]==false){
					// 类型不对
					if(cls==[NSString class]){
						Value=[[NSString alloc]initWithFormat:@"%@",Value];
					}
					else{
						return false;
					}
				}
			}
			SetProperty(Object,setMethod,Value);
		}
		break;
	}

	return true;
}

// FieldSetter
//	用setter方法将Value赋值给Object
static bool FieldSetter(id Object,id PropertySetterName,id Value)
{
	SEL setter;
	if([PropertySetterName isKindOfClass:[NSString class]]){
		setter=sel_getUid(static_cast<NSString*>(PropertySetterName).UTF8String);
	}
	else if([PropertySetterName isKindOfClass:[INSelectorValue class]]){
		setter=static_cast<INSelectorValue*>(PropertySetterName).selector;
	}
	else{
		DebugLog(@"OCDataTransfer错误：不支持的setter:%@\n",PropertySetterName);
		return false;
	}
	OCPropertyInfo PInfo;
	if(PInfo.LoadBySetter([Object class],setter)==false){
		DebugLog(@"OCDataTransfer错误：对象%@找不到方法%@\n",[Object class],PropertySetterName);
		return false;
	}
	PInfo.name=sel_getName(setter);
	return OCDataTransferFunc::SetField(Object,PInfo,Value);
}

// Dictionary
//	将ObjC数据字典赋值给Object
static bool Dictionary(id Object,NSDictionary *MapDict,NSDictionary *OCData){
	if(OCData==nil)
		return false;
		
	if([OCData isKindOfClass:[NSArray class]]){
		// 数组取第一个元素
		auto Array=static_cast<NSArray*>(OCData);
		if(Array.count==0)
			return false;
		OCData=Array[0];
	}
	if([OCData isKindOfClass:[NSDictionary class]]==false){
		DebugLog(@"OCDataTransfer错误：对象%@不是NSDictionary\n",OCData);
		return false;
	}
	for(NSString *DataName in OCData){
		id Value=OCData[DataName];

		id DestPropertyInfo=MapDict[DataName];
		if(DestPropertyInfo==nil){
			// 直接对应
			OCDataSetProperty(Object,DataName,Value);
		}
		else{
			if([DestPropertyInfo isKindOfClass:[NSString class]]){
				// 以名字对应
				NSString *DestPropertyName=DestPropertyInfo;
				OCDataSetProperty(Object,DestPropertyName,Value);
			}
			else if([DestPropertyInfo isKindOfClass:[NSDictionary class]]){
				// 字典
				OCDataTransfer(Object,DestPropertyInfo,Value);
			}
		}
	}
#ifdef	DEBUG
	for(NSString *SrcPropertyName in MapDict){
		id Value=OCData[SrcPropertyName];
		if(Value==nil){
			DebugLog(@"OCDataSetProperty错误：数据字段%@未找到\n",SrcPropertyName);
		}
	}
#endif
	return true;
}

// CreateDictionary
//	创建ObjectClass的对象并赋值
static id CreateDictionary(id Value,Class ObjectClass,NSDictionary *ObjectDict)
{
	if(Value==nil)
		return nil;
	id DestObject=SafeCreateObject(ObjectClass);
	if(Dictionary(DestObject,ObjectDict,Value)==false)
		return nil;
	return DestObject;
}

// CreateSingleObjectArray
//	创建多纬度数组
static NSArray* CreateSingleObjectArray(id Value,Class ElementClass,NSDictionary *ElementDict,unsigned int Dim)
{
	if(Dim<=1)
		return @[CreateDictionary(Value,ElementClass,ElementDict)];
	return @[CreateSingleObjectArray(Value,ElementClass,ElementDict,Dim-1)];
}

// CreateArray
//	创建数组
static NSArray* CreateArray(id Value,Class ElementClass,NSDictionary *ElementDict,unsigned int Dim)
{
	if(Value==nil)
		return @[];
	if([Value isKindOfClass:[NSArray class]]==false){
		if([Value isKindOfClass:[NSDictionary class]]){
			// 对象型
			return CreateSingleObjectArray(Value,ElementClass,ElementDict,Dim);
		}
		// 返回空数组
		return @[];
	}
	NSArray *SrcArray=Value;
	auto *Array=[[NSMutableArray alloc]initWithCapacity:SrcArray.count];
	for(id SrcElement in SrcArray){
		if(Dim>1){
			auto NewObject=CreateArray(SrcElement,ElementClass,ElementDict,Dim-1);
			[Array addObject:NewObject];
		}
		else{
			if([SrcElement isKindOfClass:ElementClass]){
				// 直接复制
				[Array addObject:SrcElement];
			}
			else{
				// 建立对象
				id DestObject=CreateDictionary(SrcElement,ElementClass,ElementDict);
				if(DestObject!=nil){
					[Array addObject:DestObject];
				}
			}
		}
	}
	return Array;
}

}}

// OCDataSetProperty
//	将Value赋值给Object的PropertyName属性
bool iNetLib::OCDataSetProperty(id Object,NSString *PropertyName,id Value)
{
	OCPropertyInfo PInfo;
	if(PInfo.Load(Object,PropertyName.UTF8String)==false){
		DebugLog(@"OCDataSetProperty错误：对象%@找不到属性%@\n",[Object class],PropertyName);
		return false;
	}
	if(PInfo.Setter==nil){
		DebugLog(@"OCDataSetProperty错误：对象%@的属性%@是readonly\n",[Object class],PropertyName);
		return false;
	}
	return OCDataTransferFunc::SetField(Object,PInfo,Value);
}

// OCDataTransfer
//	将ObjC数据根据ObjectPropertyName传送至Object
void iNetLib::OCDataTransfer(id Object,NSDictionary *ObjectPropertyMap,id OCData)
{
	if(OCData==nil)
		return;
	NSString *PName=ObjectPropertyMap[@"name"];
	Class PClass=ObjectPropertyMap[@"class"];
	NSDictionary *PMap=ObjectPropertyMap[@"dict"];
	id PSetter=ObjectPropertyMap[@"setter"];

	// 建立数据对象
	id SrcDataObject;
	if(PClass==nil){
		// 不转换
		SrcDataObject=OCData;
	}
	else if(PClass==[NSArray class]){
		// 建立数组
		Class ElementClass=ObjectPropertyMap[@"elementclass"];
		auto Dim=OCDataCast<unsigned int>(ObjectPropertyMap[@"arraydim"]);
		if(Dim==0)
			Dim=1;
		SrcDataObject=OCDataTransferFunc::CreateArray(OCData,ElementClass,PMap,Dim);
	}
	else{
		// 建立对象
		SrcDataObject=OCDataTransferFunc::CreateDictionary(OCData,PClass,PMap);
	}
	// 赋值
	if(PSetter!=nil){
		if(OCDataTransferFunc::FieldSetter(Object,PSetter,SrcDataObject)==false){
			DebugLog(@"OCDataTransfer错误：%@属性类型不支持\n",PSetter);
		}
	}
	else{
		if(PName==nil || PName.length==0){
			// 对应到自身
			OCDataTransferFunc::Dictionary(Object,PMap,SrcDataObject);
		}
		else if(PClass==nil){
			// 错误
			DebugLog(@"OCDataTransfer:属性对应字典错误:%@ 没有class\n",PName);
		}
		else{
			if(OCDataSetProperty(Object,PName,SrcDataObject)==false)
				DebugLog(@"OCDataTransfer错误：%@属性类型不支持\n",PName);
		}
	}
}

static id CreateField(id Value)
{
	if(Value==nil)
		return nil;
	if([Value isKindOfClass:[NSNull class]]){
		return nil;
	}
	if([Value isKindOfClass:[NSNumber class]]){
		return Value;
	}
	if([Value isKindOfClass:[NSString class]]){
		return Value;
	}
	if([Value isKindOfClass:[NSDictionary class]]){
		return Value;
	}
	if([Value isKindOfClass:[NSArray class]]){
		auto *NewArray=[[NSMutableArray alloc]init];
		for(id AValue in Value){
			id Field=CreateField(AValue);
			[NewArray addObject:Field];
		}
		return NewArray;
	}
	return OCDataCreate(Value);
}
id iNetLib::OCDataCreate(id Object)
{
	unsigned int PropCount;
	auto PropList=class_copyPropertyList([Object class], &PropCount);
	if(PropList==nil)
		return @{};
	
	auto Dict=[[NSMutableDictionary alloc]init];
	
	for(unsigned int i=0;i<PropCount;i++){
//		OCPropertyInfo PInfo;
//		PInfo.Load(PropList[i]);
		
		auto *Name=[[NSString alloc]initWithUTF8String:property_getName(PropList[i])];
		id Value=[Object valueForKey:Name];
		Value=CreateField(Value);
		if(Value==nil)
			continue;
		
		[Dict setValue:Value forKey:Name];
	}
	
	free(PropList);
	return Dict;
}

