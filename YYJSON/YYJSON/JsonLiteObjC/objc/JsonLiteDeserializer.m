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
#import "JsonLiteMetaData.h"
#include "jsonlite_token_pool.h"

@interface JsonLiteArrayBinder : NSObject<JsonLiteValueBinder>
@end

static JsonLiteArrayBinder *arrayBinder = nil;

@implementation JsonLiteArrayBinder

- (Class)valueClass {
    return nil;
}

- (void)setValue:(id)value forObject:(id)obj {
    [obj addObject:value == nil ? (id)kCFNull : value];
}

+ (void)load {
   arrayBinder = [[JsonLiteArrayBinder alloc] init];
}

@end

@interface JsonLiteBindingState : NSObject {
@public
    id<JsonLiteValueBinder> binder;
    id obj;
}

@end

@implementation JsonLiteBindingState

- (void)dealloc {
    [obj release];
    [super dealloc];
}

@end

@interface JsonLiteMetaDataState : NSObject {
@public
    id<JsonLiteClassInstanceCreator> creator;
    JsonLiteClassMetaData *metaData;
    NSString *key;
}

@end

@implementation JsonLiteMetaDataState
@end

@interface JsonLiteDeserializer()  {
    jsonlite_token_pool keyPool;
    id object;
    Class rootClass;
    NSMutableArray *bindingStack;
    NSMutableArray *metaDataStack;
    struct {
        BOOL didDeserializeObject : 1;
        BOOL didDeserializeArray : 1;
    } flags;
}

@end

@interface JsonLiteDeserializer() {
    JsonLiteClassMetaDataPool *metaDataPool;
}


@end

@implementation JsonLiteDeserializer

@synthesize delegate;
@synthesize converter;

- (void)setDelegate:(id<JsonLiteDeserializerDelegate>)aDelegate {
    if (delegate == aDelegate) {
        return;
    }
    
    delegate = aDelegate;
    flags.didDeserializeArray = [delegate respondsToSelector:@selector(deserializer:didDeserializeArray:)];
    flags.didDeserializeObject = [delegate respondsToSelector:@selector(deserializer:didDeserializeObject:)];
}

- (void)reset {
    [bindingStack release];
    bindingStack = nil;
    
    [metaDataStack release];
    metaDataStack = nil;
    
    [object release];
    object = nil;
}

- (id)object {
    return [[object retain] autorelease];
}

- (id)initWithRootClass:(Class)cls {
    self = [super init];
    if (self != nil) {
        rootClass = cls;
        metaDataPool = [[JsonLiteClassMetaDataPool alloc] init];
        keyPool = jsonlite_token_pool_create((jsonlite_token_pool_release_value_fn)CFRelease);
    }
    return self;
}

+ (id)deserializerWithRootClass:(Class)cls {
    return [[[JsonLiteDeserializer alloc] initWithRootClass:cls] autorelease];
}

- (void)dealloc {
    self.converter = nil;
    
    jsonlite_token_pool_release(keyPool);
    [bindingStack release];
    [metaDataStack release];
    [object release];
    [metaDataPool release];
    [super dealloc];
}

- (void)bindValue:(id)value {
    JsonLiteBindingState *state = [bindingStack lastObject];
    if (state != nil) {
        [state->binder setValue:value forObject:state->obj];
    }
}

- (void)bindToken:(JsonLiteToken *)token {
    JsonLiteBindingState *state = [bindingStack lastObject];
    if (state != nil) {
        id value = nil;
        if (![converter getValue:&value 
                         ofClass:[state->binder valueClass] 
                        forToken:token
                    deserializer:self]) {
            value = [token value];
        }
        [state->binder setValue:value forObject:state->obj];
    }
}

- (void)parser:(JsonLiteParser *)parser didFinishParsingWithError:(NSError *)error {
    if ([error code] == JsonLiteCodeEndOfStream) {
        jsonlite_token_pool_copy_tokens(keyPool);
    }
}

- (void)parserDidStartObject:(JsonLiteParser *)parser {
    if (bindingStack == nil) {
        JsonLiteClassMetaData *metaData = [metaDataPool metaDataForClass:rootClass];
        JsonLiteBindingState *bs = [[JsonLiteBindingState alloc] init];
        JsonLiteMetaDataState *ms = [[JsonLiteMetaDataState alloc] init];
        
        object = [metaData allocClassInstance];
        bs->obj = [object retain];
        ms->metaData = metaData;
        
        bindingStack = [[NSMutableArray alloc] initWithObjects:bs, nil];
        metaDataStack = [[NSMutableArray alloc] initWithObjects:ms, nil];
        
        [bs release];
        [ms release];
        return;
    }
    
    JsonLiteMetaDataState *state = [metaDataStack lastObject];
    JsonLiteBindingState *bs = [[JsonLiteBindingState alloc] init];
    JsonLiteMetaDataState *ms = [[JsonLiteMetaDataState alloc] init];
    bs->obj = [state->creator allocClassInstance];
    ms->metaData = [metaDataPool metaDataForClass:[bs->obj class]];
    [bindingStack addObject:bs];
    [metaDataStack addObject:ms];
    [bs release];
    [ms release];
}

- (void)parserDidEndObject:(JsonLiteParser *)parser {
    JsonLiteBindingState *oldState = [[bindingStack lastObject] retain];
    [bindingStack removeLastObject];
    [metaDataStack removeLastObject];
    [self bindValue:oldState->obj];
    if (flags.didDeserializeObject) {
        [delegate deserializer:self didDeserializeObject:oldState->obj];
    }
    [oldState release];
}

- (void)parserDidStartArray:(JsonLiteParser *)parser {
    if (bindingStack == nil) {
        JsonLiteClassMetaData *metaData = [metaDataPool metaDataForClass:rootClass];
        JsonLiteBindingState *bs = [[JsonLiteBindingState alloc] init];
        JsonLiteMetaDataState *ms = [[JsonLiteMetaDataState alloc] init];
        
        object = [[NSMutableArray alloc] initWithCapacity:13];
        bs->obj = [object retain];
        bs->binder = arrayBinder;
        ms->metaData = metaData;
        ms->creator = metaData;
        
        bindingStack = [[NSMutableArray alloc] initWithObjects:bs, nil];
        metaDataStack = [[NSMutableArray alloc] initWithObjects:ms, nil];
        
        [bs release];
        [ms release];
        return;
    }
    
    JsonLiteMetaDataState *ms = [metaDataStack lastObject];
    ms->creator = [ms->metaData arrayItemMetaDataForKey:ms->key];
    
    JsonLiteBindingState *bs = [[JsonLiteBindingState alloc] init];
    bs->obj = [[NSMutableArray alloc] initWithCapacity:13];
    bs->binder = arrayBinder;
    [bindingStack addObject:bs];
    [bs release];
}

- (void)parserDidEndArray:(JsonLiteParser *)parser {
    JsonLiteBindingState *oldState = [[bindingStack lastObject] retain];
    [bindingStack removeLastObject];
    [self bindValue:oldState->obj];
    if (flags.didDeserializeArray) {
        [delegate deserializer:self didDeserializeArray:oldState->obj];
    }
    [oldState release];
}

- (void)parserFoundTrueToken:(JsonLiteParser *)parser {
    [self bindValue:(id)kCFBooleanTrue];
}

- (void)parserFoundFalseToken:(JsonLiteParser *)parser {
    [self bindValue:(id)kCFBooleanFalse];
}

- (void)parserFoundNullToken:(JsonLiteParser *)parser {
    [self bindValue:nil];
}

- (void)parser:(JsonLiteParser *)parser foundKeyToken:(JsonLiteStringToken *)token {
    jsonlite_token_bucket *item = jsonlite_token_pool_get_bucket(keyPool, (jsonlite_token *)token);
    if (item->value == nil) {
        item->value = [token copyValue];
    }

    JsonLiteMetaDataState *ms = [metaDataStack lastObject];
    JsonLiteClassProperty *p = [ms->metaData propertyToBindKey:item->value];
    ms->creator = p;
    ms->key = item->value;
    
    JsonLiteBindingState *bs = [bindingStack lastObject];
    bs->binder = p;
}

- (void)parser:(JsonLiteParser *)parser foundStringToken:(JsonLiteStringToken *)token {
    [self bindToken:token];
}

- (void)parser:(JsonLiteParser *)parser foundNumberToken:(JsonLiteNumberToken *)token {
    [self bindToken:token];
}

@end
