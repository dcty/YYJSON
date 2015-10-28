//
// Created by Ivan Chua on 15/10/26.
// Copyright (c) 2015 MeiYou. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol YYJSONHelper
@optional
+ (NSDictionary *)yyKeyMap;

+ (BOOL)ignoreNullValues;   // default return YES
@end

@interface YYJSONHelper : NSObject

@end

@interface NSObject (YYJSON)

- (instancetype)toModel:(id)clazz;    //class or string

- (NSArray *)toModels:(id)clazz;    //class or string

- (instancetype)toModel:(id)clazz forKeyPath:(NSString *)keyPath;

- (NSArray *)toModels:(id)clazz forKeyPath:(NSString *)keyPath;

+ (instancetype)objectWithInput:(id)input;

+ (instancetype)objectWithInput:(id)input forKeyPath:(NSString *)keyPath;

+ (NSArray *)objectsWithInput:(id)input;

+ (NSArray *)objectsWithInput:(id)input forKeyPath:(NSString *)keyPath;

- (NSString *)YYJSONString;

- (NSDictionary *)YYJSONDict;

- (id)YYValueForKeyPath:(NSString *)keyPath;

@end