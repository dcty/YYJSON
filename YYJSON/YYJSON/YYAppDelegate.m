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
#import "YYTestViewController.h"
#import "Player.h"
#import "YYJSONHelper.h"


@implementation YYAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = [YYTestViewController new];
    [self.window makeKeyAndVisible];
//    [self test];
    return YES;
}

- (void)test
{
    NSURL *url = [NSURL URLWithString:@"http://url.cn/DjjSlB"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSArray *array = [data toModels:[Shot class] forKey:@"shots"];
    Shot *shot = array[0];
    Player *player = shot.player;
    ALERT(player.YYJSONString);
}

@end