//
//  INInternetReachability.m
//  iNetLibrary
//
//  Created by Code009 on 13-11-30.
//
//

#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import "INInternetReachability.h"


using namespace iNetLib;

@implementation INInternetReachability
{
	SCNetworkReachabilityRef reachabilityRef;
	struct{
		ocNotifyList<void (void)> Handler;
	}Notifier;
}

-(INNotifyList *)onReachabilityChanged
{
	return Notifier.Handler;
}

static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
	#pragma unused (target, flags)
	// in case someon uses the Reachablity object in a different thread.
	auto* pNotifier = static_cast<decltype(&((INInternetReachability*)nullptr)->Notifier)>(info);
	// Post a notification to notify the client that the network reachability changed.
	pNotifier->Handler();
}

-(id)init
{
	self =[super init];
	if(self==nil)
		return nil;
	sockaddr_in zeroAddress;
	bzero(&zeroAddress, sizeof(zeroAddress));
	zeroAddress.sin_len = sizeof(zeroAddress);
	zeroAddress.sin_family = AF_INET;
//	zeroAddress.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);


	SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const sockaddr*)&zeroAddress);
	if(reachability==NULL)
		return nil;
	SCNetworkReachabilityContext	context = {0, &Notifier, NULL, NULL, NULL};
	if(SCNetworkReachabilitySetCallback(reachability, ReachabilityCallback, &context)==false){
		CFRelease(reachability);
		return nil;
	}
	reachabilityRef=reachability;
	return self;
}
- (void) dealloc
{
	if(reachabilityRef!=nil){
		[self stopNotifier];
		CFRelease(reachabilityRef);
	}
}

- (BOOL) startNotifier
{
	BOOL retVal = NO;
	if(SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode)){
		retVal = YES;
	}
	return retVal;
}

- (void) stopNotifier
{
	SCNetworkReachabilityUnscheduleFromRunLoop(reachabilityRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
}

-(bool)internetReachable
{
	SCNetworkReachabilityFlags flags;
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags))
	{
		if((flags & kSCNetworkReachabilityFlagsReachable) == 0){
			// if target host is not reachable
			return false;
		}
		if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0){
			// if target host is reachable and no connection is required
			//  then we'll assume (for now) that your on Wi-Fi
			return true;
		}
	

		if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
			(flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
		{
			// ... and the connection is on-demand (or on-traffic) if the
			//     calling application is using the CFSocketStream or higher APIs

			if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0){
				// ... and no [user] intervention is needed
				return true;
			}
		}
	
		if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN){
			// ... but WWAN connections are OK if the calling application
			//     is using the CFNetwork (CFSocketStream?) APIs.
			return true;
		}
	}
	return false;
}


@end

