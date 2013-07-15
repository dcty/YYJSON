//
// Created by ivan on 13-7-12.
//
//


#import "NSData+YYJSON.h"
#import "NSObject+YYJSON.h"
#import "JsonLiteConverters.h"
#import "JsonLiteAccumulator.h"
#import "JSONKit.h"
#import "OKJSON.h"


@implementation NSData (YYJSON)

static YYJSONParserType yyjsonParserType = YYNSJSONSerialization;

+ (void)setYYJSONParserType:(YYJSONParserType)type
{
    yyjsonParserType = type;
}


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
            if (NSStringFromClass(obj))
            {
                NSArray *array = [self objectsForModelClass:NSClassFromString(obj) fromArray:dict[key]];
                [model setValue:array forKey:obj];
            }
            else
            {
                [model setValue:obj forKey:obj];
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
            if (![dict[key] isKindOfClass:[NSNull class]])
            {
                [model setValue:dict[key] forKey:obj];
            }
        }
    }];
    return model;
}

- (id)YYJSONObject
{

    switch (yyjsonParserType)
    {
        case YYJSONKit:
        {
            //JSONKit
            return self.objectFromJSONData;
        }
        case YYOKJSONParser:
        {
            //OKJSONParser
            return [OKJSON parse:self withError:nil];
        }
        case YYJsonLiteParser:
        {
            //JsonLiteObjC
            JsonLiteParser *parser = [[JsonLiteParser alloc] initWithDepth:512];
            JsonLiteAccumulator *acc = [[JsonLiteAccumulator alloc] initWithDepth:512];
            parser.delegate = acc;
            [parser parse:self];
            return acc.object;
        }
        case YYNSJSONSerialization:
        {

        }
        default:
        {
            //NSJSONSerialization
            return [NSJSONSerialization JSONObjectWithData:self options:NSJSONReadingAllowFragments error:nil];
        }

    }
}

- (id)YYJSONObjectForKey:(NSString *)key
{
    return key ? ([[self YYJSONObject] objectForKey:key]) : ([self YYJSONObject]);
}


@end