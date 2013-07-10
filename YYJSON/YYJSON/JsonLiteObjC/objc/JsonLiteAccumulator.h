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

struct JsonLiteAccumulatorState;

@class JsonLiteAccumulator;

@protocol JsonLiteAccumulatorDelegate <NSObject>

@optional
- (void)accumulator:(JsonLiteAccumulator *)accumulator didAccumulateArray:(NSArray *)array;
- (void)accumulator:(JsonLiteAccumulator *)accumulator didAccumulateDictionary:(NSDictionary *)dictionary;

@end

@interface JsonLiteAccumulator : NSObject<JsonLiteParserDelegate>

@property (nonatomic, readonly) NSUInteger depth;
@property (nonatomic, readonly) NSUInteger currentDepth;
@property (nonatomic, assign) id<JsonLiteAccumulatorDelegate> delegate;

- (id)object;
- (void)reset;

+ (id)accumulatorWithDepth:(NSUInteger)depth;
- (id)initWithDepth:(NSUInteger)depth;
- (id)init;

+ (id)objectFromData:(NSData *)data withMaxDepth:(NSUInteger)maxDepth;

@end
