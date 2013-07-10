//
// Created by ivan on 13-7-12.
//
//


#import "NSObject+YYJSON.h"
#import <objc/runtime.h>

@implementation NSObject (YYJSON)

static NSMutableDictionary *YY_JSON_OBJECT_KEYDICTS = nil;

+ (BOOL)YYSuper
{
    return NO;
}

+ (void)load
{
    YY_JSON_OBJECT_KEYDICTS = [[NSMutableDictionary alloc] init];
}

+ (NSDictionary *)YYJSONKeyDict
{
    return [[self _YYJSONKeyDict] copy];
}


+ (NSMutableDictionary *)_YYJSONKeyDict
{
    NSString *YYObjectKey = [NSString stringWithFormat:@"YY_JSON_%@", NSStringFromClass([self class])];
    NSMutableDictionary *dictionary = YY_JSON_OBJECT_KEYDICTS[YYObjectKey];
    if (!dictionary)
    {
        dictionary = [[NSMutableDictionary alloc] init];
        if ([self YYSuper])
        {
            [dictionary setValuesForKeysWithDictionary:[[self superclass] YYJSONKeyDict]];
        }
        NSArray *properties = [self yyPropertiesOfClass:[self class]];
        [properties enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [dictionary setObject:obj forKey:obj];
        }];
        [YY_JSON_OBJECT_KEYDICTS setObject:dictionary forKey:YYObjectKey];
    }
    return dictionary;
}

+ (void)bindYYJSONKey:(NSString *)jsonKey toProperty:(NSString *)property
{
    NSMutableDictionary *dictionary = [self _YYJSONKeyDict];
    [dictionary removeObjectForKey:property];
    [dictionary setObject:property forKey:jsonKey];
}

@end

@implementation NSObject (YYProperties)
- (NSArray *)yyPropertiesOfClass:(Class)aClass
{
    NSMutableArray *propertyNames = [[NSMutableArray alloc] init];
    id obj = objc_getClass([NSStringFromClass(aClass) cStringUsingEncoding:4]);
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(obj, &outCount);
    for (i = 0; i < outCount; i++)
    {
        objc_property_t property = properties[i];
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:4];
        [propertyNames addObject:propertyName];
    }
    free(properties);
    return propertyNames;
}

@end