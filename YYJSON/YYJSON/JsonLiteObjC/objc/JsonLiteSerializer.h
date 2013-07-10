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
#import "jsonlite.h"

@class JsonLiteToken;
@class JsonLiteSerializer;

@protocol JsonLiteSerializerChain <NSObject>

@property (nonatomic, retain) id<JsonLiteSerializerChain> nextSerializerChain;

- (BOOL)getData:(NSData **)data 
       forValue:(id)value 
     serializer:(JsonLiteSerializer *)serializer;

@end

@interface JsonLiteSerializer : NSObject {
    jsonlite_builder bs;
}

@property (nonatomic, retain) id<JsonLiteSerializerChain> converter;
@property (nonatomic, assign) int indentation;

- (NSData *)serializeObject:(id)obj;

- (id)init;
+ (id)serializer;

@end

