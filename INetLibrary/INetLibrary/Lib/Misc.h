//
//  Misc.h
//  iNetLibrary
//
//  Created by Code009 on 13-11-30.
//
//
#ifndef __iNetLibrary__Lib__Misc__
#define __iNetLibrary__Lib__Misc__

#import <Foundation/Foundation.h>

#ifdef	__cplusplus

namespace iNetLib{
// 常量
extern const float gSystemVersion;


constexpr unsigned long IPv4_ADDR(unsigned int a0,unsigned int a1,unsigned int a2,unsigned int a3)
{
	return a3 + (a2<<8) + (a1<<16) + (a0<<24);
}

constexpr unsigned int RGBColor(unsigned int r,unsigned int g,unsigned int b)
{
	return r+ (g<<8) + (b<<16);
}

constexpr unsigned int BGRColor(unsigned int r,unsigned int g,unsigned int b)
{
	return b+ (g<<8) + (r<<16);
}


constexpr unsigned int RoundUpDiv(unsigned int d,unsigned int n)
{
	return (d+n-1)/n;
}

}	// namespace damai


#endif	// __cplusplus

#endif /* defined(__MTLibrary__Misc__) */
