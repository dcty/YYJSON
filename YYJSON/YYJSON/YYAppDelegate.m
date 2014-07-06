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
#import "AudioModel.h"
#import "Test1.h"


@implementation YYAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    NSData *data = [[NSData alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"test" ofType:@"json"]];
    AudioModel *audioModel = [data toModel:[AudioModel class]];

    NSData *data1 = [[NSData alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"test1" ofType:@"json"]];
    Test1 *test1 = [data1 toModel:[Test1 class]];
    
    YYJSONParser *dataParser = [YYJSONParser objectWithKey:@"data" clazz:[Data class]];
    [data1 parseToObjectWithParsers:@[dataParser]];
    Data *result = dataParser.result;
    
    
    [self testData];
    [self testString];
    [self testParser];
    return YES;
}

- (void)testData
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSURL *url = [NSURL URLWithString:@"http://api.dribbble.com/shots/43424/rebounds"];
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
        NSURL *url = [NSURL URLWithString:@"http://api.dribbble.com/shots/43424/rebounds"];
        NSString *string = [NSString stringWithContentsOfURL:url encoding:4 error:nil];
        NSArray *array = [string toModels:[Shot class] forKey:@"shots"];
        Shot *shot = array[0];
        Player *player = shot.player;
        dispatch_async(dispatch_get_main_queue(), ^{
            ALERT([@"string\n" stringByAppendingString:player.YYJSONString]);
        });
    });
}

- (void)testParser
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSURL *url = [NSURL URLWithString:@"http://api.dribbble.com/shots/43424/rebounds"];
        NSData *data = [NSData dataWithContentsOfURL:url];
        if (data)
        {
            YYJSONParser *shotParser = [YYJSONParser objectWithKey:@"shots" clazz:[Shot class]];
            [data parseToObjectWithParsers:@[shotParser]];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSArray *shots = shotParser.result;
                Shot *shot = shots[0];
                ALERT([@"parser\n" stringByAppendingString:shot.YYJSONString]);
            });
        }
    });
}

@end