//
//  Timer.cpp
//  iNetLibrary
//
//  Created by Code009 on 13-11-30.
//
//

#include "Timer.h"

using namespace iNetLib;

double cTimeMeter::ConvertToTime(uint64_t t){
	return t*TimebaseInfo.numer/TimebaseInfo.denom;
}
void cTimeMeter::Reset(void){
	CheckPoint=mach_absolute_time();
	mach_timebase_info(&TimebaseInfo);
}
uint64_t cTimeMeter::Check(void){
	auto Last=CheckPoint;
	CheckPoint=mach_absolute_time();
	return CheckPoint-Last;
}
double cTimeMeter::CheckTime(void){
	auto Delta=Check();
	return ConvertToTime(Delta)/(1000*1000);
}
