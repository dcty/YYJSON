//
// Created by ivan on 13-7-12.
//
//


#import <Foundation/Foundation.h>

@interface NSObject (YYJSON)

+ (BOOL)YYSuper;

+ (NSDictionary *)YYJSONKeyDict;

+ (void)bindYYJSONKey:(NSString *)jsonKey toProperty:(NSString *)property;
@end

@interface NSObject (YYProperties)
- (NSArray *)yyPropertiesOfClass:(Class)aClass;
@end