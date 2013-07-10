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

#import "JsonLiteParser.h"
#import "jsonlite.h"
#import <objc/runtime.h>

typedef struct JsonLiteInternal {
    jsonlite_parser parser;
    void *parserObj;
    void *delegate;
    IMP parseFinished;
    IMP objectStart;
    IMP objectEnd;
    IMP arrayStart;
    IMP arrayEnd;
    IMP trueFound;
    IMP falseFound;
    IMP nullFound;
    IMP keyFound;
    IMP stringFound;
    IMP numberFound;    
} JsonLiteInternal;

static void parse_finish(jsonlite_callback_context *ctx);
static void object_start_callback(jsonlite_callback_context *ctx);
static void object_end_callback(jsonlite_callback_context *ctx);
static void array_start_callback(jsonlite_callback_context *ctx);
static void array_end_callback(jsonlite_callback_context *ctx);
static void true_found_callback(jsonlite_callback_context *ctx);
static void false_found_callback(jsonlite_callback_context *ctx);
static void null_found_callback(jsonlite_callback_context *ctx);
static void key_found_callback(jsonlite_callback_context *ctx, jsonlite_token *token);
static void string_found_callback(jsonlite_callback_context *ctx, jsonlite_token *token);
static void number_found_callback(jsonlite_callback_context *ctx, jsonlite_token *token);

NSString * const JsonLiteCodeDomain = @"com.github.amamchur.jsonlite";

static const jsonlite_parser_callbacks JsonLiteParserCallbacks = {
    &parse_finish,
    &object_start_callback,
    &object_end_callback,
    &array_start_callback,
    &array_end_callback,
    &true_found_callback,
    &false_found_callback,
    &null_found_callback,
    &key_found_callback,
    &string_found_callback,
    &number_found_callback,
    {NULL, NULL}
};

static Class class_JsonLiteStringToken;
static Class class_JsonLiteNumberToken;

@implementation JsonLiteToken 

- (id)copyValue {
    return nil;
}

- (id)value {
    return [[self copyValue] autorelease];
}

- (oneway void)release {    
}

- (id)retain {
    return self;
}

- (id)autorelease {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;
}

- (NSString *)description {
    return [[self value] description];
}

@end


@implementation JsonLiteStringToken 

- (NSString *)allocEscapedString:(jsonlite_token *)ts {
    void *buffer = NULL;
    size_t size = jsonlite_token_decode_to_uft16(ts, (uint16_t **)&buffer);
    NSString *str = (NSString *)CFStringCreateWithBytesNoCopy(NULL, 
                                                              (const UInt8 *)buffer,
                                                              size,
                                                              kCFStringEncodingUnicode, 
                                                              NO,
                                                              kCFAllocatorDefault);
    return str;
}

- (id)copyValue {
    jsonlite_token *token = (jsonlite_token *)self;
    switch (token->string_type) {
        case jsonlite_string_ascii: {
            NSString *str = (NSString *)CFStringCreateWithBytes(NULL,
                                                                token->start,
                                                                token->end - token->start,
                                                                kCFStringEncodingUTF8,
                                                                NO);
            return str;
        }
        default:
            return [self allocEscapedString:token];
    }
}

- (NSString *)copyStringWithBytesNoCopy {
    jsonlite_token *token = (jsonlite_token *)self;
    switch (token->string_type) {
        case jsonlite_string_ascii: {
            NSString *str = (NSString *)CFStringCreateWithBytesNoCopy(NULL,
                                                                token->start,
                                                                token->end - token->start,
                                                                kCFStringEncodingUTF8,
                                                                NO,
                                                                kCFAllocatorNull);
            return str;
        }
        default:
            return [self allocEscapedString:token];
    }
}

@end

@implementation JsonLiteNumberToken 

- (id)copyValue {
    jsonlite_token *token = (jsonlite_token *)self;
    NSNumber *number = nil;
    if (token->number_type & (jsonlite_number_exp | jsonlite_number_frac)) {
        double d = strtod((const char *)token->start, NULL);
        number = (NSNumber *)CFNumberCreate(NULL, kCFNumberDoubleType, &d);
    } else {
        size_t length = token->end - token->start;
        if (length < (size_t)log10(LONG_MAX)) {
            long i = strtol((const char *)token->start, NULL, 10);
            number = (NSNumber *)CFNumberCreate(NULL, kCFNumberLongType, &i);
        } else {
            long long i = strtoll((const char *)token->start, NULL, 10);
            number = (NSNumber *)CFNumberCreate(NULL, kCFNumberLongLongType, &i);
        }
    }
    return number;
}

- (NSDecimalNumber *)copyDecimal {
    jsonlite_token *token = (jsonlite_token *)self;
    NSString *str = (NSString *)CFStringCreateWithBytes(NULL,
                                                        token->start,
                                                        token->end - token->start,
                                                        kCFStringEncodingUTF8,
                                                        NO);
    NSDecimalNumber *decimal = [[NSDecimalNumber alloc] initWithString:str];
    [str release];
    return decimal;
}

- (NSDecimalNumber *)decimal {
    return [[self copyDecimal] autorelease];
}

@end

@interface JsonLiteParser() {
    JsonLiteInternal internal;
}

@property (nonatomic, retain, readwrite) NSError *parseError;

+ (NSError *)errorForCode:(JsonLiteCode)error;

@end

@implementation JsonLiteParser

@synthesize delegate;
@synthesize depth;
@synthesize parseError;

+ (void)load {
    class_JsonLiteStringToken = [JsonLiteStringToken class];
    class_JsonLiteNumberToken = [JsonLiteNumberToken class];
}

- (id)initWithDepth:(NSUInteger)aDepth {
    self = [super init];
    if (self != nil) {        
        depth = aDepth == 0 ? 16 : aDepth;
        internal.parser = NULL;
    }
    return self;
}

- (id)init {
    return [self initWithDepth:32];
}

+ (id)parserWithDepth:(NSUInteger)aDepth {
    return [[[JsonLiteParser alloc] initWithDepth:aDepth] autorelease];
}

+ (id)parser {
    return [[[JsonLiteParser alloc] init] autorelease];
}

- (void)dealloc {
    self.parseError = nil;
    jsonlite_parser_release(internal.parser);
    [super dealloc];
}

- (BOOL)parse:(NSData *)data {
    if (data == nil) {
        self.parseError = [JsonLiteParser errorForCode:JsonLiteCodeInvalidArgument];
        return NO;
    }
    
    jsonlite_parser jp = internal.parser;
    if (jp == NULL) {
        jp = jsonlite_parser_init(depth);
        internal.parser = jp;
        if (delegate != nil) {
            jsonlite_parser_callbacks cbs = JsonLiteParserCallbacks;
            cbs.context.client_state = &internal;
            jsonlite_parser_set_callback(jp, &cbs);
        }
    }

    jsonlite_result result = jsonlite_parser_tokenize(jp, [data bytes], [data length]);

    self.parseError = [JsonLiteParser errorForCode:(JsonLiteCode)result];
    return result == jsonlite_result_ok;
}

- (NSError *)suspend {
    if (internal.parser == NULL) {
        return [JsonLiteParser errorForCode:JsonLiteCodeNotAllowed];
    }

    
    jsonlite_result result = jsonlite_parser_suspend(internal.parser);
    self.parseError = [JsonLiteParser errorForCode:(JsonLiteCode)result];
    return parseError;
}

- (NSError *)resume {
    if (internal.parser == NULL) {
        return [JsonLiteParser errorForCode:JsonLiteCodeNotAllowed];
    }
    
    jsonlite_result result = jsonlite_parser_resume(internal.parser);
    self.parseError = [JsonLiteParser errorForCode:(JsonLiteCode)result];
    return parseError;
}

- (void)reset {
    jsonlite_parser_release(internal.parser);
    internal.parser = NULL;
}

- (void)setDelegate:(id<JsonLiteParserDelegate>)aDelegate {
    delegate = aDelegate;
    if (delegate == nil) {
        return;
    }
    
    internal.parserObj = self;
    internal.delegate = delegate;
    
    Class cls = [delegate class];
    internal.parseFinished = class_getMethodImplementation(cls, @selector(parser:didFinishParsingWithError:));
    internal.objectStart = class_getMethodImplementation(cls, @selector(parserDidStartObject:));
    internal.objectEnd = class_getMethodImplementation(cls, @selector(parserDidEndObject:));
    internal.arrayStart = class_getMethodImplementation(cls, @selector(parserDidStartArray:));
    internal.arrayEnd = class_getMethodImplementation(cls, @selector(parserDidEndArray:));
    internal.trueFound = class_getMethodImplementation(cls, @selector(parserFoundTrueToken:));
    internal.falseFound = class_getMethodImplementation(cls, @selector(parserFoundFalseToken:));
    internal.nullFound = class_getMethodImplementation(cls, @selector(parserFoundNullToken:));
    internal.keyFound = class_getMethodImplementation(cls, @selector(parser:foundKeyToken:));
    internal.stringFound = class_getMethodImplementation(cls, @selector(parser:foundStringToken:));
    internal.numberFound = class_getMethodImplementation(cls, @selector(parser:foundNumberToken:));
}

+ (NSError *)errorForCode:(JsonLiteCode)error {
    NSString *str = @"";
    switch (error) {
        case JsonLiteCodeUnknown:
        case JsonLiteCodeOk:
        case JsonLiteCodeSuspended:
            return nil;
        case JsonLiteCodeEndOfStream:
            str = @"Reached end of stream.";
            break;
        case JsonLiteCodeDepthLimit:
            str = @"Depth limit reached.";
            break;
        case JsonLiteCodeInvalidArgument:
            str = @"Invalid argument.";
            break;
        case JsonLiteCodeExpectedObjectOrArray:
            str = @"Expected object or array.";
            break;
        case JsonLiteCodeExpectedValue:
            str = @"Expected value.";
            break;
        case JsonLiteCodeExpectedKeyOrEnd:
            str = @"Expected key or object end.";
            break;
        case JsonLiteCodeExpectedKey:
            str = @"Expected key.";
            break;
        case JsonLiteCodeExpectedColon:
            str = @"Expected key or object end.";
            break;
        case JsonLiteCodeExpectedCommaOrEnd:
            str = @"Expected comma or array end.";
            break;
        case JsonLiteCodeInvalidEscape:
            str = @"Invalid escape character.";
            break;
        case JsonLiteCodeInvalidNumber:
            str = @"Invalid number format.";
            break;
        case JsonLiteCodeInvalidToken:
            str = @"Invalid token found.";
            break;
        case JsonLiteCodeInvalidUTF8:
            str = @"Invalid UTF 8";
            break;
        case JsonLiteCodeNotAllowed:
            str = @"Operation not allowed";
            break;
    }
    
    NSDictionary *dict = [NSDictionary dictionaryWithObject:str
                                                     forKey:NSLocalizedDescriptionKey];
    NSError *e = [NSError errorWithDomain:JsonLiteCodeDomain
                                     code:error
                                 userInfo:dict];
    return e;
}

@end

static void parse_finish(jsonlite_callback_context *ctx) {
    JsonLiteInternal *jli = (JsonLiteInternal *)ctx->client_state;
    jsonlite_result res = jsonlite_parser_get_result(jli->parser);
    JsonLiteParser *p = (JsonLiteParser *)jli->parserObj;
    NSError *error = [JsonLiteParser errorForCode:(JsonLiteCode)res];
    p.parseError = error;
        
    jli->parseFinished(jli->delegate, @selector(parser:didFinishParsingWithError:), jli->parserObj, error);
}

static void object_start_callback(jsonlite_callback_context *ctx) {
    JsonLiteInternal *jli = (JsonLiteInternal *)ctx->client_state;
    jli->objectStart(jli->delegate, @selector(parserDidStartObject:), jli->parserObj);
}

static void object_end_callback(jsonlite_callback_context *ctx) {
    JsonLiteInternal *jli = (JsonLiteInternal *)ctx->client_state;
    jli->objectEnd(jli->delegate, @selector(parserDidEndObject:), jli->parserObj);
}

static void array_start_callback(jsonlite_callback_context *ctx) {
    JsonLiteInternal *jli = (JsonLiteInternal *)ctx->client_state;
    jli->arrayStart(jli->delegate, @selector(parserDidStartArray:), jli->parserObj);
}

static void array_end_callback(jsonlite_callback_context *ctx) {
    JsonLiteInternal *jli = (JsonLiteInternal *)ctx->client_state;
    jli->arrayEnd(jli->delegate, @selector(parserDidEndArray:), jli->parserObj);
}

static void true_found_callback(jsonlite_callback_context *ctx) {
    JsonLiteInternal *jli = (JsonLiteInternal *)ctx->client_state;
    jli->trueFound(jli->delegate, @selector(parserFoundTrueToken:), jli->parserObj);
}

static void false_found_callback(jsonlite_callback_context *ctx) {
    JsonLiteInternal *jli = (JsonLiteInternal *)ctx->client_state;
    jli->falseFound(jli->delegate, @selector(parserFoundFalseToken:), jli->parserObj);
}

static void null_found_callback(jsonlite_callback_context *ctx) {
    JsonLiteInternal *jli = (JsonLiteInternal *)ctx->client_state;
    jli->nullFound(jli->delegate, @selector(parserFoundNullToken:), jli->parserObj);
}

static void key_found_callback(jsonlite_callback_context *ctx, jsonlite_token *token) {
    JsonLiteInternal *jli = (JsonLiteInternal *)ctx->client_state;
    token->ext = class_JsonLiteStringToken;
    jli->keyFound(jli->delegate, @selector(parser:foundKeyToken:), jli->parserObj, token);
}

static void string_found_callback(jsonlite_callback_context *ctx, jsonlite_token *token) {
    JsonLiteInternal *jli = (JsonLiteInternal *)ctx->client_state;
    token->ext = class_JsonLiteStringToken;
    jli->stringFound(jli->delegate, @selector(parser:foundStringToken:), jli->parserObj, token);
}

static void number_found_callback(jsonlite_callback_context *ctx, jsonlite_token *token) {
    JsonLiteInternal *jli = (JsonLiteInternal *)ctx->client_state;
    token->ext = class_JsonLiteNumberToken;
    jli->numberFound(jli->delegate, @selector(parser:foundNumberToken:), jli->parserObj, token);
}
