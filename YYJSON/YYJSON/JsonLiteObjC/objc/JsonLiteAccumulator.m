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

#import "JsonLiteAccumulator.h"
#import "JsonLiteCollections.h"
#import "jsonlite_token_pool.h"

#define CHECK_CAPACITY() if (keys + capacity < current->keys + current->length + 1) [self extendCapacity]

typedef struct JsonLiteAccumulatorState {
    id *keys;
    id *values;
    CFHashCode *hashes;
    size_t length;
    size_t capacity;
} JsonLiteAccumulatorState;

static void ReleaseKeyValues(JsonLiteAccumulatorState *s) {
    for (NSInteger i = 0; i < s->length; i++) {
        CFRelease((CFTypeRef)s->values[i]);
    }
    
    for (NSInteger i = 0; i < s->length; i++) {    
        id key = s->keys[i];
        if (key == nil) {
            break;
        }
        
        CFRelease((CFTypeRef)key);
    }
    
    memset(s->values, 0, s->length * sizeof(id)); // LCOV_EXCL_LINE
    memset(s->keys, 0, s->length * sizeof(id)); // LCOV_EXCL_LINE
    s->length = 0;
}

@interface JsonLiteAccumulator() {
    struct JsonLiteAccumulatorState *current;
    struct JsonLiteAccumulatorState *state;
    id *keys;
    id *values;
    CFHashCode *hashes;
    jsonlite_token_pool keyPool;
    jsonlite_token_pool stringPool;
    jsonlite_token_pool numberPool;
    NSUInteger capacity;
    struct {
        BOOL didAccumulateArray : 1;
        BOOL didAccumulateDictionary : 1;
    } flags;
}
@end

@implementation JsonLiteAccumulator

@synthesize depth;
@synthesize delegate;

- (NSUInteger)currentDepth {
    return current - state;
}

+ (id)accumulatorWithDepth:(NSUInteger)depth {
    return [[[JsonLiteAccumulator alloc] initWithDepth:depth] autorelease];
}

- (id)initWithDepth:(NSUInteger)aDepth {
    self = [super init];
    if (self != nil) {
        keyPool = jsonlite_token_pool_create((jsonlite_token_pool_release_value_fn)CFRelease);
        stringPool = jsonlite_token_pool_create((jsonlite_token_pool_release_value_fn)CFRelease);
        numberPool = jsonlite_token_pool_create((jsonlite_token_pool_release_value_fn)CFRelease);
        capacity = 0x100;
        
        id *buffer = calloc(2 * capacity, sizeof(id));
        values = buffer;
        keys = buffer + capacity;
        hashes = malloc(capacity * sizeof(CFHashCode));
        
        depth = aDepth == 0 ? 16 : aDepth;
        state = malloc(depth * sizeof(JsonLiteAccumulatorState));
        
        state->values = values;
        state->keys = keys;
        state->hashes = hashes;
        state->length = 0;
        state->capacity = capacity;
        
        *state->values = NULL;
        *state->keys = NULL;
        
        current = state;
    }
    return self;
}

- (id)init {
    return [self initWithDepth:32];
}

- (void)dealloc {  
    [self reset];

    jsonlite_token_pool_release(keyPool);
    jsonlite_token_pool_release(stringPool);
    jsonlite_token_pool_release(numberPool);
    
    free(values);
    free(state);
    free(hashes);
    [super dealloc];
}

- (void)setDelegate:(id<JsonLiteAccumulatorDelegate>)aDelegate {
    if (delegate == aDelegate) {
        return;
    }
    
    delegate = aDelegate;
    flags.didAccumulateArray = [delegate respondsToSelector:@selector(accumulator:didAccumulateArray:)];
    flags.didAccumulateDictionary = [delegate respondsToSelector:@selector(accumulator:didAccumulateDictionary:)];
}

- (id)object {
    return [[*values retain] autorelease];
}

- (void)reset {
    while (current >= state) {
        ReleaseKeyValues(current--);
    }
    
    current = state;
}

- (void)extendCapacity {
    size_t newCapacity = capacity * 2;    
    CFHashCode *newHashes = malloc(newCapacity * sizeof(CFHashCode));
    id *buffer = calloc(2 * newCapacity, sizeof(id));
    id *newValues = buffer;
    id *newKeys = buffer + newCapacity;
    
    memcpy(newValues, values, capacity * sizeof(id)); // LCOV_EXCL_LINE
    memcpy(newKeys, keys, capacity * sizeof(id)); // LCOV_EXCL_LINE
    memcpy(newHashes, hashes, capacity * sizeof(CFHashCode)); // LCOV_EXCL_LINE
    
    NSInteger keysOffset = newKeys - keys;
    NSInteger valuesOffset = newValues - values;
    NSInteger hashesOffset = newHashes - hashes;
    for (JsonLiteAccumulatorState *c = state; c <= current; c++) {
        c->keys += keysOffset;
        c->values += valuesOffset;
        c->hashes += hashesOffset;
    }
    free(values);
    free(hashes);
    
    values = newValues;
    keys = newKeys;
    capacity = newCapacity;
    hashes = newHashes;
}

- (void)pushState {
    JsonLiteAccumulatorState *next = current + 1;
    
    NSInteger delta = current->length + 1;
    if (keys + capacity < current->keys + current->length + delta) {
        [self extendCapacity];
    }
    
    next->keys = current->keys + delta;
    next->values = current->values + delta;
    next->hashes = current->hashes + delta;
    next->capacity = capacity - (next->keys - keys);
    next->length = 0;
    current++;
}

- (void)popState {
    memset(current->values, 0, current->length * sizeof(id)); // LCOV_EXCL_LINE
    memset(current->keys, 0, current->length * sizeof(id)); // LCOV_EXCL_LINE
    current->length = 0;
    current--;
}

- (void)parser:(JsonLiteParser *)parser didFinishParsingWithError:(NSError *)error {
    if ([error code] == JsonLiteCodeEndOfStream) {
        jsonlite_token_pool_copy_tokens(keyPool);
        jsonlite_token_pool_copy_tokens(stringPool);
        jsonlite_token_pool_copy_tokens(numberPool);
    }
}

- (void)parserDidStartObject:(JsonLiteParser *)parser {
    [self pushState];
}

- (void)parserDidEndObject:(JsonLiteParser *)parser {
    JsonLiteDictionary *d = JsonLiteCreateDictionary(current->values,
                                                     current->keys,
                                                     current->hashes,
                                                     current->length);
    JsonLiteAccumulatorState *prev = current - 1;
    prev->values[prev->length++] = d;
    
    if (flags.didAccumulateDictionary) {
        [delegate accumulator:self didAccumulateDictionary:d];
    }

    [self popState];
}

- (void)parserDidStartArray:(JsonLiteParser *)parser {
    [self pushState];
}

- (void)parserDidEndArray:(JsonLiteParser *)parser {
    JsonLiteArray *a =JsonLiteCreateArray(current->values, current->length);
    JsonLiteAccumulatorState *prev = current - 1;
    prev->values[prev->length++] = a;
    
    if (flags.didAccumulateArray) {
        [delegate accumulator:self didAccumulateArray:a];
    }
    [self popState];
}

- (void)parserFoundTrueToken:(JsonLiteParser *)parser {
    CHECK_CAPACITY();
    current->values[current->length++] = (id)kCFBooleanTrue;
}

- (void)parserFoundFalseToken:(JsonLiteParser *)parser {
    CHECK_CAPACITY();
    current->values[current->length++] = (id)kCFBooleanFalse;
}

- (void)parserFoundNullToken:(JsonLiteParser *)parser {
    CHECK_CAPACITY();
    current->values[current->length++] = (id)kCFNull;
}

- (void)parser:(JsonLiteParser *)parser foundKeyToken:(JsonLiteStringToken *)token {
    jsonlite_token_bucket *item = jsonlite_token_pool_get_bucket(keyPool, (jsonlite_token *)token);
    if (item->value == nil) {
        item->value = [token copyValue];
        item->value_hash = CFHash((CFTypeRef)item->value);
    }
    
    CHECK_CAPACITY();
    current->hashes[current->length] = (CFHashCode)item->value_hash;
    current->keys[current->length] = (id)CFRetain((CFTypeRef)item->value);
}

- (void)parser:(JsonLiteParser *)parser foundStringToken:(JsonLiteStringToken *)token {
    jsonlite_token_bucket *item = jsonlite_token_pool_get_bucket(stringPool, (jsonlite_token *)token);
    if (item->value == nil) {
        item->value = [token copyValue];
    }
    
    CHECK_CAPACITY();
    current->values[current->length++] = (id)CFRetain((CFTypeRef)item->value);
}

- (void)parser:(JsonLiteParser *)parser foundNumberToken:(JsonLiteNumberToken *)token {
    jsonlite_token_bucket *item = jsonlite_token_pool_get_bucket(numberPool, (jsonlite_token *)token);
    if (item->value == nil) {
        item->value = [token copyValue];
    }
    
    CHECK_CAPACITY();
    current->values[current->length++] = (id)CFRetain((CFTypeRef)item->value);
}

+ (id)objectFromData:(NSData *)data withMaxDepth:(NSUInteger)maxDepth {
    JsonLiteParser *parser = [[JsonLiteParser alloc] initWithDepth:maxDepth];
    JsonLiteAccumulator *acc = [[JsonLiteAccumulator alloc] initWithDepth:maxDepth];
    parser.delegate = acc;
    BOOL success = [parser parse:data];
    id obj = success ? [acc object] : nil;
    [acc release];
    [parser release];
    return obj;
}

@end
