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

#import "JsonLiteDeserializer.h"
#import "JsonLiteSerializer.h"

@class JsonLiteToken;
@class JsonLiteDeserializer;
@class JsonLiteSerializer;

@interface JsonLiteConverter : NSObject<JsonLiteDeserializerChain, JsonLiteSerializerChain> {
    id<JsonLiteDeserializerChain> nextDeserializerChain;
    id<JsonLiteSerializerChain> nextSerializerChain;
}

@property (nonatomic, retain) id<JsonLiteDeserializerChain> nextDeserializerChain;
@property (nonatomic, retain) id<JsonLiteSerializerChain> nextSerializerChain;

+ (id<JsonLiteDeserializerChain, JsonLiteSerializerChain>)converters;

@end

@interface JsonLiteDecimal : JsonLiteConverter
@end

@interface JsonLiteURL : JsonLiteConverter
@end

@interface JsonLiteTwitterDate : JsonLiteConverter {
    NSDateFormatter *formatter;
}

@end
