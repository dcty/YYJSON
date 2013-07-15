//
// Created by ivan on 13-7-15.
//
//


#import <mach/mach_time.h>
#import "YYUtils.h"


@implementation YYUtils
CGFloat YYTimeBlock(void (^block)(void)) {
    mach_timebase_info_data_t info;
    if (mach_timebase_info(&info) != KERN_SUCCESS) return -1.0;
    uint64_t start = mach_absolute_time();    //开始时间
    block();
    uint64_t end = mach_absolute_time();     //结束时间
    uint64_t elapsed = end - start;
    uint64_t nanos = elapsed * info.numer / info.denom;
    return (CGFloat) nanos / NSEC_PER_SEC;
}

void ALERT(NSString *msg) {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"YYDEBUG" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

@end