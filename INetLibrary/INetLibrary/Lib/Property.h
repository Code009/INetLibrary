//
//  Property.h
//  iNetLibrary
//
//  Created by Code009 on 13-11-30.
//
//

#ifdef	__OBJC__

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#ifdef	__cplusplus

namespace iNetLib{

// 属性信息
struct OCPropertyInfo{
	const char *name;
	const char *type;
	SEL Getter;
	SEL Setter;

	OCPropertyInfo();
	~OCPropertyInfo();
	void Load(objc_property_t Property);
	bool LoadClassProperty(Class Object,const char *PropertyName);
	bool Load(id Object,const char *PropertyName);
	bool LoadBySetter(Class cls,SEL Setter);
};

Class OCGetClassByTypeName(const char *type);
// OCDataSetProperty
//	把OC数据赋值到OC对象的属性
bool OCDataSetProperty(id Object,NSString *PropertyName,id Value);
// OCDataTransfer
//	从OC数据赋值到OC对象
//	Object		目标对象
//	PropertyMap	属性对应字典
//	OCData		数据
void OCDataTransfer(id Object,NSDictionary *PropertyMap,id OCData);
/*
PropertyMap定义：
	字段名			类型					说明
	name			NSString			对应的属性名。为空时表示直接对应本身对象(<Object>)
	setter			INSelectorValue		属性setter方法
	class			Class				数据类型
	elementclass	Class				如果数据类型为NSArray,此字段说明数组元素的类型
	arraydim		NSNumber			如果数据类型为NSArray,此字段说明数组元素的维度
	dict			NSDictionary		子属性表

子属性表基本条目格式:
	@"网络层字段名":@{PropertyMap}
	@"网络层字段名":@"对应属性名"	相当于	@"网络层字段名":@{@"name":@"对应属性名"}


例子
@{
	@"name":@"array",	// <OCData>赋值到<Object>	对象的array属性
	@"class":[NSArray class],	// 类型为数组
	@"elementclass":[DataObject_abc class],
	@"dict":@{
		@"json1":@"dm1",	// 数据的数组中json1字段对应DataObject_abc.dm1
		@"json2":@"dm2",	// 数据的数组中json2字段对应DataObject_abc.dm2
		@"data":@{			// 数据的数组中data对象
			@"name":@"data",	//	对应DataObject_abc.data
			@"class":[DataObject_def class],	// data数据的类型
			@"dict":@{	...	}
		}
		@"imageurl":@{		// 数据的数组中imageurl字段
			@"setter":INSelector(@selector(setImageURL:)),	// 调用setImageURL方法
			@"class":[NSString class],
		}
	}
}
*/

id OCDataCreate(id Object);
}	// namespace iNetLib

#endif

#endif

