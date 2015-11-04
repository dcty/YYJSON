//
// Created by ivan on 13-7-12.
//
//


#import "Shot.h"


@implementation Shot
+ (void)initialize
{
    [super initialize];
//    [self bindYYJSONKey:@"image_url" toProperty:@"imageURLString"];
//    [self bindYYJSONKey:@"player" toProperty:@"Player"];  因为Player实现了YYJSONHelperProtocal，所以能够自动映射了，不需要手写了
}

+ (NSDictionary *)YYJSON_keyMap {
    return @{@"imageURLString":@"image_url"};
}

@end