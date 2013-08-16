//
// Created by ivan on 13-7-17.
//
//
#import <objc/runtime.h>


#import "YYJSONHelper.h"


static void YY_swizzleInstanceMethod(Class c, SEL original, SEL replacement);

@implementation NSObject (YYJSONHelper)

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
    return [self _YYJSONKeyDict];
}


+ (NSMutableDictionary *)_YYJSONKeyDict
{
    NSString *YYObjectKey = [NSString stringWithFormat:@"YY_JSON_%@", NSStringFromClass([self class])];
    NSMutableDictionary *dictionary = YY_JSON_OBJECT_KEYDICTS[YYObjectKey];
    if (!dictionary)
    {
        dictionary = [[NSMutableDictionary alloc] init];
        if ([self YYSuper] && ![[self superclass] isMemberOfClass:[NSObject class]])
        {
            [dictionary setValuesForKeysWithDictionary:[[self superclass] YYJSONKeyDict]];
        }
        //因为我们的Model可能已经继承了自己写的BaseModel，如果再让你继承我自己写的一个BaseJsonModel，那么可能会破坏你的设计。
        //由于我不喜欢继承，所以无法重写  valueForUndefinedKey: 和 setValue:forUndefinedKey:
        //所以把有使用YYJsonHelper的类的以上俩方法替换了，如果你需要在这俩方法里面进行其他控制
        //请重写新的两个方法 YY_valueForUndefinedKey:和YY_setValue:forUndefinedKey:
        YY_swizzleInstanceMethod(self, @selector(valueForUndefinedKey:), @selector(YY_valueForUndefinedKey:));
        YY_swizzleInstanceMethod(self, @selector(setValue:forUndefinedKey:), @selector(YY_setValue:forUndefinedKey:));
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

- (NSString *)YYJSONString
{
    return [self YYJSONDictionary].YYJSONString;
}

- (NSData *)YYJSONData
{
    if ([NSJSONSerialization isValidJSONObject:self])
    {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&error];
        if (!error)
        {
            return jsonData;
        }
    }
    return self.YYJSONDictionary.YYJSONData;
}


/**
 *  应该比较脆弱，不支持太复杂的对象。
 */
- (NSDictionary *)YYJSONDictionary
{
    if ([self isKindOfClass:[NSArray class]])
    {
        return nil;
    }
    NSDictionary *keyDict = [self.class YYJSONKeyDict];
    NSMutableDictionary *jsonDict = [[NSMutableDictionary alloc] initWithCapacity:keyDict.count];
    [keyDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id value = nil;
        if (NSClassFromString(obj))
        {
            value = [[self valueForKey:key] YYJSONDictionary];
        }
        else
        {
            value = [self valueForKey:obj];
        }
        if (value)
        {
            [jsonDict setValue:value forKey:key];
        }
    }];
    return jsonDict;
}

static void YY_swizzleInstanceMethod(Class c, SEL original, SEL replacement) {
    Method a = class_getInstanceMethod(c, original);
    Method b = class_getInstanceMethod(c, replacement);
    if (class_addMethod(c, original, method_getImplementation(b), method_getTypeEncoding(b)))
    {
        class_replaceMethod(c, replacement, method_getImplementation(a), method_getTypeEncoding(a));
    }
    else
    {
        method_exchangeImplementations(a, b);
    }
}

- (id)YY_valueForUndefinedKey:(NSString *)key
{
#ifdef DEBUG
    NSLog(@"%@ undefinedKey %@", self.class, key);
#endif
    return nil;
}

- (void)YY_setValue:(id)value forUndefinedKey:(NSString *)key
{
#ifdef DEBUG
    NSLog(@"%@ undefinedKey %@ and value is %@", self.class, key, value);
#endif
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

@implementation NSString (YYJSONHelper)
- (id)toModel:(Class)modelClass
{
    return [self.toYYData toModel:modelClass];
}

- (id)toModel:(Class)modelClass forKey:(NSString *)jsonKey
{
    return [self.toYYData toModel:modelClass forKey:jsonKey];
}

- (NSArray *)toModels:(Class)modelClass
{
    return [self.toYYData toModels:modelClass];
}

- (NSArray *)toModels:(Class)modelClass forKey:(NSString *)jsonKey
{
    return [self.toYYData toModels:modelClass forKey:jsonKey];
}

- (NSData *)toYYData
{
    return [self dataUsingEncoding:NSUTF8StringEncoding];
}

@end

@implementation NSDictionary (YYJSONHelper)
- (NSString *)YYJSONString
{
    NSData *jsonData = self.YYJSONData;
    if (jsonData)
    {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return nil;
}

@end

@implementation NSData (YYJSONHelper)

- (id)toModel:(Class)modelClass
{
    return [self toModel:modelClass forKey:nil];
}

- (id)toModel:(Class)modelClass forKey:(NSString *)key
{
    if (modelClass == nil)return nil;
    id YYJSONObject = [self YYJSONObjectForKey:key];
    if (YYJSONObject == nil)return nil;
    NSDictionary *YYJSONKeyDict = [modelClass YYJSONKeyDict];
    id model = [self objectForModelClass:modelClass fromDict:YYJSONObject withJSONKeyDict:YYJSONKeyDict];
    return model;
}

- (NSArray *)toModels:(Class)modelClass
{
    return [self toModels:modelClass forKey:nil];
}

- (NSArray *)toModels:(Class)modelClass forKey:(NSString *)key
{
    if (modelClass == nil)return nil;
    id YYJSONObject = [self YYJSONObjectForKey:key];
    if (YYJSONObject == nil)return nil;
    NSDictionary *YYJSONKeyDict = [modelClass YYJSONKeyDict];
    if ([YYJSONObject isKindOfClass:[NSArray class]])
    {
        NSMutableArray *models = [[NSMutableArray alloc] initWithCapacity:[YYJSONObject count]];
        [YYJSONObject enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            id model = [self objectForModelClass:modelClass fromDict:obj withJSONKeyDict:YYJSONKeyDict];
            [models addObject:model];
        }];
        return models;
    }
    else if ([YYJSONObject isKindOfClass:[NSDictionary class]])
    {
        return [self objectForModelClass:modelClass fromDict:YYJSONObject withJSONKeyDict:YYJSONKeyDict];
    }
    return nil;
}

- (id)objectsForModelClass:(Class)modelClass fromArray:(NSArray *)array
{
    NSMutableArray *models = [[NSMutableArray alloc] initWithCapacity:array.count];
    NSDictionary *YYJSONKeyDict = [modelClass YYJSONKeyDict];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [models addObject:[self objectForModelClass:modelClass fromDict:obj withJSONKeyDict:YYJSONKeyDict]];
    }];
    return models;
}

- (id)objectForModelClass:(Class)modelClass fromDict:(NSDictionary *)dict withJSONKeyDict:(NSDictionary *)YYJSONKeyDict
{
    id model = [[modelClass alloc] init];
    [YYJSONKeyDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([dict[key] isKindOfClass:[NSArray class]])
        {
            if (NSClassFromString(obj))
            {
                NSArray *array = [self objectsForModelClass:NSClassFromString(obj) fromArray:dict[key]];
                [model setValue:array forKey:obj];
            }
            else
            {
                [model setValue:dict[key] forKey:obj];
            }
        }
        else if ([dict[key] isKindOfClass:[NSDictionary class]])
        {
            
            Class otherClass = NSClassFromString(obj);
            id object = [self objectForModelClass:otherClass fromDict:dict[key] withJSONKeyDict:[otherClass YYJSONKeyDict]];
            [model setValue:object forKey:obj];
        }
        else
        {
            id value = dict[key];
            if (![value isKindOfClass:[NSNull class]] && value != nil)
            {
                [model setValue:dict[key] forKey:obj];
            }
        }
    }];
    return model;
}

- (NSString *)YYJSONString
{
    return [[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding];
}


- (id)YYJSONObject
{
    return [NSJSONSerialization JSONObjectWithData:self options:NSJSONReadingAllowFragments error:nil];
}

- (id)YYJSONObjectForKey:(NSString *)key
{
    return key ? ([[self YYJSONObject] objectForKey:key]) : ([self YYJSONObject]);
}


@end

@implementation NSArray (YYJSONHelper)

- (NSString *)YYJSONString
{
    return self.YYJSONData.YYJSONString;
}

/**
 *   循环集合将每个对象转为字典，得到字典集合，然后转为jsonData
 */
- (NSData *)YYJSONData
{
    NSMutableArray *jsonDictionaries = [[NSMutableArray alloc] init];
    [self enumerateObjectsUsingBlock:^(NSObject *obj, NSUInteger idx, BOOL *stop) {
        [jsonDictionaries addObject:obj.YYJSONDictionary];
    }];
    if ([NSJSONSerialization isValidJSONObject:jsonDictionaries])
    {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionaries options:NSJSONWritingPrettyPrinted error:&error];
        if (!error)
        {
            return jsonData;
        }
    }
    return nil;
}

@end