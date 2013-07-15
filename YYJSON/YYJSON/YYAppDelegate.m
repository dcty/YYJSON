//
//  YYAppDelegate.m
//  YYJSON
//
//  Created by Ivan on 13-7-12.
//  Copyright (c) 2013 Ivan. All rights reserved.
//

#import "YYAppDelegate.h"
#import "YYUtils.h"
#import "NSData+YYJSON.h"
#import "Shot.h"
#import "YYTestViewController.h"


@implementation YYAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = [YYTestViewController new];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)test
{
    __block NSArray *array1 = nil;
    __block NSArray *array2 = nil;
    __block NSArray *array3 = nil;
    __block NSArray *array4 = nil;
    dispatch_sync(dispatch_get_global_queue(0, 0), ^{
        NSURL *url = [NSURL URLWithString:@"http://url.cn/DjjSlB"];
        __block NSData *data = [NSData dataWithContentsOfURL:url];
        CGFloat time1 = YYTimeBlock(^{
            [NSData setYYJSONParserType:YYNSJSONSerialization];
            array1 = [data toModels:[Shot class] forKey:@"shots"];
        });
        CGFloat time2 = YYTimeBlock(^{
            [NSData setYYJSONParserType:YYJSONKit];
            array2 = [data toModels:[Shot class] forKey:@"shots"];
        });
        CGFloat time3 = YYTimeBlock(^{
            [NSData setYYJSONParserType:YYJsonLiteParser];
            array3 = [data toModels:[Shot class] forKey:@"shots"];
        });
        CGFloat time4 = YYTimeBlock(^{
            [NSData setYYJSONParserType:YYOKJSONParser];
            array4 = [data toModels:[Shot class] forKey:@"shots"];
        });

        NSMutableString *text = [[NSMutableString alloc] init];
        [text appendFormat:@"NSJSONSerialization : %f\n", time1];
        [text appendFormat:@"JSONKit : %f\n", time2];
        [text appendFormat:@"JsonLiteParser : %f\n", time3];
        [text appendFormat:@"OKJSONParser : %f\n", time4];
        ALERT(text);
    });
}

@end