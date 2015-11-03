//
//  DataEncoding.h
//  iNetLibrary
//
//  Created by Code009 on 13-11-30.
//
//

#import <Foundation/Foundation.h>

#ifdef	__OBJC__
#ifdef	__cplusplus

namespace iNetLib{

bool DecodeBase64Character(int &d,char c);
int DecodeBase64(unsigned char *Dest,const char *Text,unsigned int Length);


id JSONDeserialize(NSData *Data);

}	//	namespace iNetLib

#endif
#endif

