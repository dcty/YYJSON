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
#import "JsonLiteParser.h"

@class JsonLiteToken;
@class JsonLiteDeserializer;

@protocol JsonLiteDeserializerChain <NSObject>

@property (nonatomic, retain) id<JsonLiteDeserializerChain> nextDeserializerChain;

- (BOOL)getValue:(id *)value
         ofClass:(Class)cls
        forToken:(JsonLiteToken *)token 
    deserializer:(JsonLiteDeserializer *)deserializer;

@end

@protocol JsonLiteDeserializerDelegate <NSObject>

@optional
- (void)deserializer:(JsonLiteDeserializer *)deserializer didDeserializeObject:(id)object;
- (void)deserializer:(JsonLiteDeserializer *)deserializer didDeserializeArray:(NSArray *)array;

@end

@interface JsonLiteDeserializer : NSObject<JsonLiteParserDelegate>

@property (nonatomic, assign) id<JsonLiteDeserializerDelegate> delegate;
@property (nonatomic, retain) id<JsonLiteDeserializerChain> converter;

- (void)reset;

- (id)object;
- (id)initWithRootClass:(Class)cls;
+ (id)deserializerWithRootClass:(Class)cls;

@end
