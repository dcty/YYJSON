//
// Created by ivan on 13-7-12.
//
//


#import "YYJSONHelper.h"
#import "Player.h"


@implementation Player

+ (void)initialize
{
    [super initialize];
//    [self bindYYJSONKey:@"website_url" toProperty:@"webSiteURLString"];
}

+ (NSDictionary *)yyKeyMap{
    return @{@"webSiteURLString":@"website_url"};
}

@end