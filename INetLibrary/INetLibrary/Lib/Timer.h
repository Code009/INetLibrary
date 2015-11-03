//
//  Timer.h
//  iNetLibrary
//
//  Created by Code009 on 13-11-30.
//
//

#ifndef __iNetLibrary__Lib__Timer__
#define __iNetLibrary__Lib__Timer__



#include <mach/mach.h>
#include <mach/mach_time.h>

#ifdef	__cplusplus

namespace iNetLib{

class cTimeMeter
{
	uint64_t CheckPoint;
	mach_timebase_info_data_t TimebaseInfo;

	double ConvertToTime(uint64_t t);
public:

	// 重置
	void Reset(void);
	// 检查距离上次重置的时间，返回系统定时器间隔
	uint64_t Check(void);

	// 检查距离上次重置的时间，以ms为单位
	double CheckTime(void);

	
};

}	// namespace iNetLib

#endif	// __cplusplus


#endif /* defined(__MTLibrary__Timer__) */
