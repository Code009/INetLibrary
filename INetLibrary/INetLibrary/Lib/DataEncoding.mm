//
//  DataEncoding.cpp
//  iNetLibrary
//
//  Created by Code009 on 13-11-30.
//
//

#import "DataEncoding.h"
#import "Debug.h"

using namespace iNetLib;

bool iNetLib::DecodeBase64Character(int &d,char c)
{
	if(c=='+'){
		d=62;
		return true;
	}
	if(c=='/'){
		d=63;
		return true;
	}
	if(c>'z'){
		return false;
	}
	if(c>='a'){
		d=c-'a'+26;
		return true;
	}
	if(c>'Z'){
		return false;
	}
	if(c>='A'){
		d=c-'A';
		return true;
	}
	if(c>'9'){
		return false;
	}
	if(c>='0'){
		d=c-'0'+52;
		return true;
	}
	return false;
}

int iNetLib::DecodeBase64(unsigned char *Dest,const char *Text,unsigned int Length)
{
	unsigned char B64Index=0;
	union{
		unsigned int Data=0;
		unsigned char bData[3];
	};
	if(Length%4!=0)
		return -1;
	int TextIndex=0;
	for(unsigned int i=0;i<Length;i++){
		int val64;
		if(Text[i]=='='){
			val64=0;
		}
		else if(DecodeBase64Character(val64,Text[i])==false)
			return -1;
		Data<<=6;
		Data|=val64;
		B64Index++;
		if(B64Index>=4){
			Dest[TextIndex]=bData[2];
			Dest[TextIndex+1]=bData[1];
			Dest[TextIndex+2]=bData[0];
			TextIndex+=3;
			B64Index=0;
			Data=0;
		}
	}
	return TextIndex;
}


id iNetLib::JSONDeserialize(NSData *Data)
{
	NSError *ReadError;
	id json=[NSJSONSerialization JSONObjectWithData:Data options:0 error:&ReadError];
#ifdef	DEBUG
	if(ReadError)
		DebugLog(@"JSONDeserialize error : %@\n",ReadError);
#endif
	return json;
}

