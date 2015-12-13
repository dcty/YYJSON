//
// Created by Ivan on 15/10/26.
//
//


#import "objc/runtime.h"

#ifdef DEBUG
#define YYJSONFormat NSJSONWritingPrettyPrinted
#else
#define YYJSONFormat 0
#endif


@interface YYProperty : NSObject
@property(strong, nonatomic) NSString *jsonKeyPath;
@property(strong, nonatomic) NSString *propertyName;
@property(strong, nonatomic) Class bindClass;
@end

@implementation YYProperty
@end

@implementation NSObject (YYJSON_Property)

NSString *property_getTypeString(objc_property_t property) {
    const char *attrs = property_getAttributes(property);
    if (attrs == NULL)
        return (NULL);

    static char buffer[256];
    const char *e = strchr(attrs, ',');
    if (e == NULL)
        return (NULL);

    int len = (int) (e - attrs);
    memcpy(buffer, attrs, len);
    buffer[len] = '\0';
    NSMutableString *sb = [NSMutableString stringWithUTF8String:buffer];
    [sb replaceOccurrencesOfString:@"T@" withString:@"" options:0 range:NSMakeRange(0, sb.length)];
    [sb replaceOccurrencesOfString:@"\"" withString:@"" options:0 range:NSMakeRange(0, sb.length)];
    return sb;
}

static NSMutableDictionary *YYJSONKeyDict = nil;
static NSMapTable *YYJSONMapTable = nil;

+ (void)load {
    YYJSONKeyDict = [[NSMutableDictionary alloc] init];
    YYJSONMapTable = [NSMapTable weakToStrongObjectsMapTable];
}


+ (NSSet *)YYPropertySetOfClass:(Class)class {
    NSString *className = NSStringFromClass(class);
    NSMutableSet *set = YYJSONKeyDict[className];
    if (set) {
        return set;
    }
    set = [[NSMutableSet alloc] init];
    id obj = objc_getClass([className cStringUsingEncoding:4]);
    unsigned int outCount, i;
    NSDictionary *customKeyMap = nil;
    if ([obj respondsToSelector:@selector(yyKeyMap)]) {
        customKeyMap = [obj yyKeyMap];
    }
    objc_property_t *properties = class_copyPropertyList(obj, &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:4];
        YYProperty *yyProperty = [[YYProperty alloc] init];
        NSString *customPropertyName = [customKeyMap valueForKey:propertyName];
        yyProperty.propertyName = propertyName;
        yyProperty.jsonKeyPath = customPropertyName ?: propertyName;
        id propertyClass = [self classOfProperty:property];
        if (propertyClass) {
            yyProperty.bindClass = propertyClass;
        }
        [set addObject:yyProperty];
    }
    free(properties);
    if (class) {
        YYJSONKeyDict[className] = set;
    }
    return set;
}

+ (Class)classOfProperty:(objc_property_t)property {
    NSString *typeName = property_getTypeString(property);
    NSRange range = [typeName rangeOfString:@"Array"];
    if (range.location != NSNotFound) {
        NSRange beginRange = [typeName rangeOfString:@"<"];
        NSRange endRange = [typeName rangeOfString:@">"];
        if (beginRange.location != NSNotFound && endRange.location != NSNotFound) {
            NSString *protocolName = [typeName substringWithRange:NSMakeRange(beginRange.location + beginRange.length, endRange.location - beginRange.location - 1)];
            Class class = NSClassFromString(protocolName);
            if (class) {
                return class;
            }
        }
    }
    id instance = [NSClassFromString(typeName) new];
    if ([instance conformsToProtocol:@protocol(YYJSONHelper)]) {
        return [instance class];
    }
    return nil;
}

@end

@interface YYJSONHelper : NSObject

@end

@implementation YYJSONHelper

+ (id)convertObject:(id)object toModel:(Class)class {
    return [self convertObject:object toModel:class forKeyPath:nil];
}

+ (id)convertObject:(id)object toModel:(Class)class forKeyPath:(NSString *)keyPath {
    if (object == nil || class == nil) {
        return nil;
    }
    NSMutableArray *array = nil;
    id JSON = [self YYJSON:object];
    if (keyPath) {
        JSON = [JSON valueForKeyPath:keyPath];
    }
    if ([JSON isKindOfClass:[NSArray class]]) {
        array = [[NSMutableArray alloc] init];
        for (NSDictionary *dictionary in JSON) {
            [array addObject:[self convertDictionary:dictionary toModel:class]];
        }
    }
    else if ([JSON isKindOfClass:[NSDictionary class]]) {
        return [self convertDictionary:JSON toModel:class];
    }
    return array.count > 0 ? array : nil;
}

+ (id)convertDictionary:(NSDictionary *)dictionary toModel:(Class)class {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    } else {
        if (dictionary.allValues.count == 0) {
            return nil;
        }
    }
    NSSet *set = [self YYPropertySetOfClass:class];
    id returnMe = [class new];
    [set enumerateObjectsUsingBlock:^(YYProperty *yyProperty, BOOL *stop) {
        id value = [dictionary valueForKeyPath:yyProperty.jsonKeyPath];
        if (yyProperty.bindClass) {
            value = [self convertObject:value toModel:yyProperty.bindClass];
        }
        BOOL ignoreNullValues = YES;
        if ([class respondsToSelector:@selector(ignoreNullValues)]) {
            ignoreNullValues = [class ignoreNullValues];
        }
        if (ignoreNullValues) {
            if ([value isKindOfClass:[NSString class]]) {
                NSString *string = (NSString *) value;
                if (string.length > 0 && ![string.lowercaseString isEqualToString:@"null"]) {
                    [returnMe setValue:value forKey:yyProperty.propertyName];
                }
            } else {
                if (value && value != [NSNull null]) {
                    [returnMe setValue:value forKey:yyProperty.propertyName];
                }
            }
        } else {
            if (value) {
                [returnMe setValue:value forKeyPath:yyProperty.propertyName];
            }
        }
    }];
    return returnMe;
}

+ (id)YYJSON:(id)object {
    id JSON = [YYJSONMapTable objectForKey:object];
    if (JSON) {
        NSLog(@"using cache");
        return JSON;
    }
    if ([object isKindOfClass:[NSString class]]) {
        NSData *data = [(NSString *) object dataUsingEncoding:4];
        if (data) {
            JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        }
    }
    else if ([object isKindOfClass:[NSData class]]) {
        if ([(NSData *) object length] > 0) {
            JSON = [NSJSONSerialization JSONObjectWithData:object options:0 error:nil];
        }
    }
    else if ([object isKindOfClass:[NSDictionary class]]) {
        JSON = object;
    }
    else if ([object isKindOfClass:[NSArray class]]) {
        JSON = object;
    }
    [YYJSONMapTable setObject:JSON forKey:object];
    return JSON;
}

+ (NSString *)JSONStringFromModel:(id)model {
    NSDictionary *JSONDict = [self JSONDictFromModel:model];
    if (JSONDict && [NSJSONSerialization isValidJSONObject:JSONDict]) {
        NSError *error = nil;
        NSData *JSONData = [NSJSONSerialization dataWithJSONObject:JSONDict options:YYJSONFormat error:&error];
        if (JSONData.length > 0) {
            return [[NSString alloc] initWithData:JSONData encoding:4];
        }
    }
    return nil;
}

+ (NSString *)JSONStringFromArray:(NSArray *)array {
    NSMutableArray *JSONArray = [NSMutableArray arrayWithCapacity:array.count];
    [array enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSDictionary *JSONDict = [self JSONDictFromModel:obj];
        if (JSONDict.count > 0) {
            [JSONArray addObject:JSONDict];
        }
    }];
    if (![NSJSONSerialization isValidJSONObject:JSONArray]) {
        return nil;
    }
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:JSONArray options:YYJSONFormat error:nil];
    if (JSONData.length > 0) {
        return [[NSString alloc] initWithData:JSONData encoding:4];
    }
    return nil;
}

+ (NSDictionary *)JSONDictFromModel:(id)model {
    NSSet *set = [self YYPropertySetOfClass:[model class]];
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    [set enumerateObjectsUsingBlock:^(YYProperty *yyProperty, BOOL *stop) {
        id value = [model valueForKeyPath:yyProperty.propertyName];
        if (yyProperty.bindClass) {
            [dictionary setValue:[YYJSONHelper JSONDictFromModel:value] forKeyPath:yyProperty.jsonKeyPath];
        } else {
            if ([value respondsToSelector:@selector(description)]) {
                [dictionary setValue:[value description] forKeyPath:yyProperty.jsonKeyPath];
            } else {
                [dictionary setValue:value forKeyPath:yyProperty.jsonKeyPath];
            }
        }
    }];
    return dictionary.count ? dictionary : nil;
}

@end


@implementation NSObject (YYJSON)

- (instancetype)toModel:(id)clazz {
    return [self toModel:clazz forKeyPath:nil];
}

- (NSArray *)toModels:(id)clazz {
    return [self toModels:clazz forKeyPath:nil];
}

- (instancetype)toModel:(id)clazz forKeyPath:(NSString *)keyPath {
    Class class = [self classFromInput:clazz];
    return [YYJSONHelper convertObject:self toModel:class forKeyPath:keyPath];
}

- (NSArray *)toModels:(id)clazz forKeyPath:(NSString *)keyPath {
    Class class = [self classFromInput:clazz];
    return [YYJSONHelper convertObject:self toModel:class forKeyPath:keyPath];
}


+ (instancetype)objectWithInput:(id)input {
    return [self objectWithInput:input forKeyPath:nil];
}

+ (instancetype)objectWithInput:(id)input forKeyPath:(NSString *)keyPath {
    return [input toModel:[self class] forKeyPath:keyPath];
}

+ (NSArray *)objectsWithInput:(id)input {
    return [self objectsWithInput:input forKeyPath:nil];
}

+ (NSArray *)objectsWithInput:(id)input forKeyPath:(NSString *)keyPath {
    return [input toModels:[self class] forKeyPath:keyPath];
}

- (Class)classFromInput:(id)input {
    Class aClass = input;
    if ([input isKindOfClass:[NSString class]]) {
        aClass = NSClassFromString(input);
    }
    return aClass;
}

- (NSString *)YYJSONString {
    if ([self isKindOfClass:[NSArray class]]) {
        return [YYJSONHelper JSONStringFromArray:(id) self];
    }
    if ([self isKindOfClass:[NSDictionary class]]) {
        NSData *JSONData = [NSJSONSerialization dataWithJSONObject:self options:YYJSONFormat error:nil];
        if (JSONData.length > 0) {
            return [[NSString alloc] initWithData:JSONData encoding:4];
        } else {
            return nil;
        }
    }
    return [YYJSONHelper JSONStringFromModel:self];
}

- (NSDictionary *)YYJSONDict {
    if ([self isKindOfClass:[NSArray class]]) {
        return nil;
    }
    if ([self isKindOfClass:[NSDictionary class]]) {
        return (id) self;
    }
    return [YYJSONHelper JSONDictFromModel:self];
}

- (id)YYValueForKeyPath:(NSString *)keyPath {
    id JSON = [YYJSONHelper YYJSON:self];
    return [JSON valueForKeyPath:keyPath];
}

@end
