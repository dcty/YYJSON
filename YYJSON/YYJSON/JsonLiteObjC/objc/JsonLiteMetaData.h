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

#import <Foundation/Foundation.h>

@interface NSObject(JsonLiteBinding)

+ (NSArray *)jsonLiteBindingRules;

@end

@protocol JsonLiteClassInstanceCreator <NSObject>

- (id)allocClassInstance;

@end

@protocol JsonLiteValueBinder <NSObject>

- (Class)valueClass;
- (void)setValue:(id)value forObject:(id)obj;

@end

@interface JsonLiteBindRule : NSObject {
    NSString *key;
    NSString *property;
}

@property (nonatomic, readonly) NSString *key;
@property (nonatomic, readonly) NSString *property;
@property (nonatomic, readonly) Class elementClass;

- (id)initWithKey:(NSString *)aKey 
           bindTo:(NSString *)aProperty 
     elementClass:(Class)cls;

+ (JsonLiteBindRule *)ruleForKey:(NSString *)key bindTo:(NSString *)property;
+ (JsonLiteBindRule *)ruleForKey:(NSString *)key bindTo:(NSString *)property elementClass:(Class)cls;
+ (JsonLiteBindRule *)ruleForKey:(NSString *)key elementClass:(Class)cls;

@end

@interface JsonLiteClassProperty : NSObject<JsonLiteClassInstanceCreator, JsonLiteValueBinder> {
    IMP getterImp;
    IMP setterImp;
    SEL getterSelector;
    SEL setterSelector;
    struct {
        int readonlyAccess : 1;
        int retainOwnership : 1;
        int copyOwnership : 1;
        int assignOwnership : 1;
        int nonatomicAccess : 1;
        int dynamicCreation : 1;
//        int weakReference : 1; Not supported now
//        int garbageCollection : 1;
        int objectType : 1;
        int classObject : 1;
    } propertyFlags;
}

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, readonly) Class objectClass;

- (void)setValue:(id)value forObject:(id)obj;
- (id)valueOfObject:(id)obj;

@end

@interface JsonLiteClassMetaData : NSObject<JsonLiteClassInstanceCreator>

@property (nonatomic, readonly) NSDictionary *properties;
@property (nonatomic, readonly) NSDictionary *binding;
@property (nonatomic, readonly) NSArray *keys;
@property (nonatomic, readonly) Class objectClass;

- (JsonLiteClassProperty *)propertyToBindKey:(NSString *)key;
- (JsonLiteClassMetaData *)arrayItemMetaDataForKey:(NSString *)key;
- (id)initWithClass:(Class)aClass;

+ (JsonLiteClassMetaData *)metaDataForClass:(Class)cls;

@end

@interface JsonLiteClassMetaDataPool : NSObject

- (JsonLiteClassMetaData *)metaDataForClass:(Class)cls;

@end

