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

typedef enum {
    JsonLiteCodeUnknown = -1,
    JsonLiteCodeOk,
    JsonLiteCodeEndOfStream,
    JsonLiteCodeDepthLimit,
    JsonLiteCodeInvalidArgument,
    JsonLiteCodeExpectedObjectOrArray,
    JsonLiteCodeExpectedValue,
    JsonLiteCodeExpectedKeyOrEnd,
    JsonLiteCodeExpectedKey,
    JsonLiteCodeExpectedColon,
    JsonLiteCodeExpectedCommaOrEnd,
    JsonLiteCodeInvalidEscape,
    JsonLiteCodeInvalidNumber,
    JsonLiteCodeInvalidToken,
    JsonLiteCodeInvalidUTF8,
    JsonLiteCodeSuspended,    
    JsonLiteCodeNotAllowed
}  JsonLiteCode;

extern NSString * const JsonLiteCodeDomain;

@class JsonLiteParser;

@interface JsonLiteToken : NSObject

- (id)copyValue;
- (id)value;

@end

@interface JsonLiteStringToken : JsonLiteToken

- (NSString *)copyStringWithBytesNoCopy;

@end

@interface JsonLiteNumberToken : JsonLiteToken

- (NSDecimalNumber *)copyDecimal;
- (NSDecimalNumber *)decimal;

@end

@protocol JsonLiteParserDelegate <NSObject>

- (void)parserDidStartObject:(JsonLiteParser *)parser;
- (void)parserDidEndObject:(JsonLiteParser *)parser;
- (void)parserDidStartArray:(JsonLiteParser *)parser;
- (void)parserDidEndArray:(JsonLiteParser *)parser;

- (void)parser:(JsonLiteParser *)parser foundKeyToken:(JsonLiteStringToken *)token;
- (void)parser:(JsonLiteParser *)parser foundStringToken:(JsonLiteStringToken *)token;
- (void)parser:(JsonLiteParser *)parser foundNumberToken:(JsonLiteNumberToken *)token;

- (void)parserFoundTrueToken:(JsonLiteParser *)parser;
- (void)parserFoundFalseToken:(JsonLiteParser *)parser;
- (void)parserFoundNullToken:(JsonLiteParser *)parser;

- (void)parser:(JsonLiteParser *)parser didFinishParsingWithError:(NSError *)error;

@end

@interface JsonLiteParser : NSObject

@property (nonatomic, assign) id<JsonLiteParserDelegate> delegate;
@property (nonatomic, assign, readonly) NSUInteger depth;
@property (nonatomic, retain, readonly) NSError *parseError;

- (BOOL)parse:(NSData *)data;

- (NSError *)suspend;
- (NSError *)resume;
- (void)reset;

- (id)init;
- (id)initWithDepth:(NSUInteger)aDepth;

+ (id)parser;
+ (id)parserWithDepth:(NSUInteger)aDepth;

@end

