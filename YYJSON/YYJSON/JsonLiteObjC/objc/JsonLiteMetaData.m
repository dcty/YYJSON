//  Copyright 2012-2013, Andrii Mamchur
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License

#import "JsonLiteMetaData.h"
#import <objc/runtime.h>
#import <objc/objc-sync.h>

@implementation JsonLiteBindRule

@synthesize key;
@synthesize property;
@synthesize elementClass;

- (id)initWithKey:(NSString *)aKey 
           bindTo:(NSString *)aProperty 
   elementClass:(Class)cls {
    self = [super init];
    if (self != nil) {
        key = [aKey copy];
        property = [aProperty copy];
        elementClass = cls;
    }
    return self;
}

- (void)dealloc {
    [key release];
    [property release];
    [super dealloc];
}


+ (JsonLiteBindRule *)ruleForKey:(NSString *)key bindTo:(NSString *)property {
    return [[[JsonLiteBindRule alloc] initWithKey:key
                                           bindTo:property
                                     elementClass:nil] autorelease];
}

+ (JsonLiteBindRule *)ruleForKey:(NSString *)key bindTo:(NSString *)property elementClass:(Class)cls {
    return [[[JsonLiteBindRule alloc] initWithKey:key
                                           bindTo:property
                                     elementClass:cls] autorelease];
}

+ (JsonLiteBindRule *)ruleForKey:(NSString *)key elementClass:(Class)cls {
    return [[[JsonLiteBindRule alloc] initWithKey:key
                                           bindTo:nil
                                     elementClass:cls] autorelease];
}

@end

@implementation JsonLiteClassProperty

@synthesize name;
@synthesize objectClass;

- (Class)valueClass {
    return objectClass;
}

- (void)setValue:(id)value forObject:(id)obj {
//#ifdef DEBUG
//    if (propertyFlags.objectType) {
//        NSParameterAssert(value == nil || [value isKindOfClass:objectClass]);
//    }
//    if (propertyFlags.classObject) {
//        NSParameterAssert(value == nil || class_getName(value) != NULL);
//    }
//#endif
    setterImp(obj, setterSelector, value);
}

- (id)valueOfObject:(id)obj {
    return getterImp(obj, getterSelector);
}

- (const char *)takeAccessor:(const char *)p ofClass:(Class)cls {
    const char *start = p;
    const char *end = NULL;
    int run = 1;
    while (*p && run) {
        if (*p ==  ',') {
            end = p;
            run = 0;
        }
        p++;
    }
    
    end = end ? end : p;
    NSString *str = [[NSString alloc] initWithBytes:start
                                             length:end - start
                                           encoding:NSUTF8StringEncoding];
    
    getterSelector = NSSelectorFromString(str);
    getterImp = class_getMethodImplementation(cls, getterSelector);
    [str release];
    
    return p;
}

- (const char *)takeMutator:(const char *)p ofClass:(Class)cls {
    const char *start = p;
    for (; *p !=  ','; p++);
    
    NSString *str = [[NSString alloc] initWithBytes:start
                                             length:p - start
                                           encoding:NSUTF8StringEncoding];
    
    setterSelector = NSSelectorFromString(str);
    setterImp = class_getMethodImplementation(cls, setterSelector);
    [str release];
    
    return p;
}

- (const char *)takeVariableName:(const char *)p {
    for (; *p != 0; p++);
    return p;
}

- (const char *)takePropertyType:(const char *)p {
    const char *start = NULL;
    const char *end = NULL;
    for (;; p++) {
        if (*p == '@') {
            propertyFlags.objectType = 1;
        } else if (*p == '#') {
            propertyFlags.classObject = 1;
            return p + 1;
        } else if (*p == '\"') {
            if (start == NULL) {
                start = p + 1;
            } else {
                end = p;
                break;
            }
        }
    }
    
    NSString *str = [[NSString alloc] initWithBytes:start
                                             length:end - start
                                           encoding:NSUTF8StringEncoding];    
    objectClass = NSClassFromString(str);
    [str release];
    return p;
}

- (void)collectDataForProperty:(objc_property_t)property ofClass:(Class)cls {
    const char *attr = property_getAttributes(property);
    const char *p = attr;
    while (*p) {
        switch (*p++) {
            case 'R':
                propertyFlags.readonlyAccess = 1;
                break;    
            case 'C':
                propertyFlags.copyOwnership = 1;
                break;    
            case '&':
                propertyFlags.retainOwnership = 1;
                break;    
            case 'N':
                propertyFlags.nonatomicAccess = 1;
                break;
            case 'D': 
                propertyFlags.dynamicCreation = 1;
                break;
// Not supported now
//            case 'W':
//                propertyFlags.weakReference = 1;
//                break;
//            case 'P':
//                propertyFlags.garbageCollection = 1;
//                break;
            case 'T':
                p = [self takePropertyType:p];
                break;
            case 'V':
                p = [self takeVariableName:p];
                break;
            case 'G':
                p = [self takeAccessor:p ofClass:cls];
                break;
            case 'S':
                p = [self takeMutator:p ofClass:cls];
                break;
            default:
                break;
        }
    }    
}

- (void)completeImplementationForClass:(Class)cls {
    if (getterImp == NULL) {
        getterSelector = NSSelectorFromString(name);
        getterImp = class_getMethodImplementation(cls, getterSelector);
    }
    if (setterImp == NULL && !propertyFlags.readonlyAccess) {
        NSString *str = [NSString stringWithFormat:@"set%@%@:",
                                [[name substringToIndex:1] uppercaseString],
                                [name substringFromIndex:1]];
        setterSelector = NSSelectorFromString(str);
        setterImp = class_getMethodImplementation(cls, setterSelector);
    }
}

- (id)allocClassInstance {
    return [class_createInstance(objectClass, 0) init];
}

- (id)initWithObjCProperty:(objc_property_t)property ofClass:(Class)cls {
    self = [super init];
    if (self != nil) {
        name = [[NSString alloc] initWithCString:property_getName(property)
                                        encoding:NSUTF8StringEncoding];
        [self collectDataForProperty:property ofClass:cls];
        [self completeImplementationForClass:cls];
    }
    return self;
}

- (void)dealloc {
    [name release];
    [super dealloc];
}

@end

@interface JsonLiteClassMetaData() {
    NSDictionary *binding;
    NSArray *keys;
}
@end

@implementation JsonLiteClassMetaData

@synthesize properties;
@synthesize objectClass;

- (NSDictionary *)binding {
    if (binding == NULL) {
        [self collectBinding];
    }
    return binding;
}

- (NSArray *)keys {
    if (keys == nil) {
        [self collectKeys];
    }
    return keys;
}

- (void)inspectClassMetaData {
    Class cls = objectClass;
    Class baseCls = [NSObject class];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    while (cls != baseCls && cls != NULL) {
        unsigned int count = 0;
        objc_property_t *list = class_copyPropertyList(cls, &count);
        for (unsigned int i = 0; i < count; i++) {
            JsonLiteClassProperty *p = [[JsonLiteClassProperty alloc] initWithObjCProperty:list[i] 
                                                                                   ofClass:cls];
            [dict setObject:p forKey:p.name];
            [p release];
        }
        free(list);
        cls = [cls superclass];
    }
    properties = [dict copy];
}

- (void)collectBinding {
    Class cls = objectClass;
    Class baseCls = [NSObject class];
    NSMutableArray *rules = [NSMutableArray array];
    while (cls != baseCls) {
        if ([cls respondsToSelector:@selector(jsonLiteBindingRules)]) {
            [rules addObjectsFromArray:[cls jsonLiteBindingRules]];
        }
        cls = [cls superclass];
    }
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:[rules count]];
    for (JsonLiteBindRule *rule = [rules lastObject]; rule != nil; rule = [rules lastObject]) {
        [dict setObject:rule forKey:rule.key];
        [rules removeLastObject];
    }
    
    [binding release];
    binding = [dict copy];
    [dict release];
}

- (JsonLiteClassProperty *)propertyToBindKey:(NSString *)key  {
    JsonLiteClassProperty *property = [properties objectForKey:key];
    if (property != nil) {
        return property;
    }

    JsonLiteBindRule *rule = [self.binding objectForKey:key];
    if (rule != nil) {
        return [properties objectForKey:rule.property];
    }
    return nil;
}

- (void)collectKeys {
    NSMutableArray *array = [[NSMutableArray alloc] initWithArray:[binding allKeys]];
    NSMutableArray *propertiesKeys = [NSMutableArray arrayWithArray:[properties allKeys]];
    NSUInteger count = [array count];
    for (NSUInteger i = 0; i < count; i++) {
        id key = [array objectAtIndex:i];
        JsonLiteBindRule *rule = [binding objectForKey:key];
        [propertiesKeys removeObject:rule.property];
    }
    [array addObjectsFromArray:propertiesKeys];
    
    keys = [[array sortedArrayUsingSelector:@selector(compare:)] retain];
    [array release];
}

- (JsonLiteClassMetaData *)arrayItemMetaDataForKey:(NSString *)key {
    JsonLiteBindRule *rule = [self.binding objectForKey:key];
    if (rule != nil && rule.elementClass != nil) {
        return [JsonLiteClassMetaData metaDataForClass:rule.elementClass];
    }
    return nil;
}

- (id)allocClassInstance {
    return [class_createInstance(objectClass, 0) init];
}

- (id)initWithClass:(Class)aClass {
    self = [super init];
    if (self != nil) {
        objectClass = aClass;
        [self inspectClassMetaData];
    }
    return self;
}

- (void)dealloc {
    [properties release];
    [binding release];
    [keys release];
    [super dealloc];
}

+ (JsonLiteClassMetaData *)metaDataForClass:(Class)cls {
    if (cls == nil) {
        return nil;
    }
    
    static NSMutableDictionary *cache = nil;
    JsonLiteClassMetaData *metaData = nil;
    objc_sync_enter(self);
        if (cache == nil) {
            cache = [[NSMutableDictionary alloc] init];
        }
        metaData = [cache objectForKey:cls];
        if (metaData == nil) {
            metaData = [[JsonLiteClassMetaData alloc] initWithClass:cls];
            [cache setObject:metaData forKey:(id<NSCopying>)cls];
            [metaData release];
        }
    objc_sync_exit(self);
    return metaData;
}

@end

@interface JsonLiteClassMetaDataPool() {
    NSMutableDictionary *dict;
}

@end

@implementation JsonLiteClassMetaDataPool

- (id)init {
    self = [super init];
    if (self != nil) {
        dict = [[NSMutableDictionary alloc] initWithCapacity:13];
    }
    return self;
}

- (void)dealloc {
    [dict release];
    [super dealloc];
}

- (JsonLiteClassMetaData *)metaDataForClass:(Class)cls {
    if (cls == nil) {
        return nil;
    }
    
    JsonLiteClassMetaData *metaData = [dict objectForKey:cls];
    if (metaData == nil) {
        metaData = [[JsonLiteClassMetaData alloc] initWithClass:cls];
        [dict setObject:metaData forKey:(id<NSCopying>)cls];
        [metaData release];
    }
    return metaData;
}


@end
