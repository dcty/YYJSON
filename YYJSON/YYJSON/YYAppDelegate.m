//
//  YYAppDelegate.m
//  YYJSON
//
//  Created by Ivan on 13-7-12.
//  Copyright (c) 2013 Ivan. All rights reserved.
//

#import "YYAppDelegate.h"
#import "YYUtils.h"
#import "Shot.h"
#import "Player.h"
#import "YYJSONHelper.h"
#import "AudioModel.h"


@implementation YYAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    NSData *data = [[NSData alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"test" ofType:@"json"]];
    AudioModel *audioModel = [data toModel:[AudioModel class]];
    
    [self testData];
    [self testString];
    return YES;
}

- (void)testData
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSURL *url = [NSURL URLWithString:@"http://url.cn/DjjSlB"];
        NSData *data = [NSData dataWithContentsOfURL:url];
        NSArray *array = [data toModels:[Shot class] forKey:@"shots"];
        Shot *shot = array[0];
        Player *player = shot.player;
        dispatch_async(dispatch_get_main_queue(), ^{
            ALERT([@"data\n" stringByAppendingString:player.YYJSONString]);
        });
    });
}

- (void)testString
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSURL *url = [NSURL URLWithString:@"http://url.cn/DjjSlB"];
        NSString *string = [NSString stringWithContentsOfURL:url encoding:4 error:nil];
        NSArray *array = [string toModels:[Shot class] forKey:@"shots"];
        Shot *shot = array[0];
        Player *player = shot.player;
        dispatch_async(dispatch_get_main_queue(), ^{
            ALERT([@"string\n" stringByAppendingString:player.YYJSONString]);
        });
    });
}

@end