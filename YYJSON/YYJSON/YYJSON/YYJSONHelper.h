//
// Created by Ivan Chua on 15/10/26.
// Copyright (c) 2015 MeiYou. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol YYJSONHelper
@optional
+ (NSDictionary *)YYJSON_keyMap;

+ (NSArray *)YYJSON_ignoreProperties;

+ (BOOL)YYJSON_ignoreNullValues;   // default return YES

+ (BOOL)YYJSON_customSetValue:(id)value forKey:(NSString *)key atInstance:(id)instance;

+ (BOOL)YYJSON_Super;

@end

@interface NSObject (YYJSON)

- (id)toModel:(id)clazz;    //class or string

- (NSArray *)toModels:(id)clazz;    //class or string

- (id)toModel:(id)clazz forKeyPath:(NSString *)keyPath;

- (NSArray *)toModels:(id)clazz forKeyPath:(NSString *)keyPath;

+ (instancetype)objectWithInput:(id)input;

+ (instancetype)objectWithInput:(id)input forKeyPath:(NSString *)keyPath;

+ (NSArray *)objectsWithInput:(id)input;

+ (NSArray *)objectsWithInput:(id)input forKeyPath:(NSString *)keyPath;

- (NSString *)YYJSONString;

- (NSDictionary *)YYJSONDict;

- (id)YYValueForKeyPath:(NSString *)keyPath;

@end