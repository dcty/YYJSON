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

#import "JsonLiteCollections.h"

#import <objc/runtime.h>

typedef struct JsonLiteDictionaryBucket {
    CFHashCode hash;
    id key;
    id value;
    struct JsonLiteDictionaryBucket *next;
} JsonLiteDictionaryBucket;

@interface JsonLiteDictionaryEnumerator : NSEnumerator {
    NSInteger index;
    NSInteger count;
    JsonLiteDictionaryBucket *buffer;
}

@end

#define JsonLiteDictionaryFront     0x10
#define JsonLiteDictionaryFrontMask 0x0F

@interface JsonLiteDictionary() {
@public
    NSUInteger count;
    JsonLiteDictionaryBucket *buffer;
    JsonLiteDictionaryBucket *buckets[JsonLiteDictionaryFront];
}

@end

@interface JsonLiteArray() {
@public
    NSUInteger count;
    id *values;
}

@end

@implementation JsonLiteDictionaryEnumerator

- (id)initWithBuffer:(JsonLiteDictionaryBucket *)aBuffer count:(NSUInteger)aCount {
    self = [self init];
    if (self != nil) {
        buffer = aBuffer;
        count = aCount;
        index = 0;
    }
    return self;
}

- (NSArray *)allObjects {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:(NSUInteger)count];
    for (int i = 0; i < count; i++) {
        [array addObject:(buffer + i)->key];
    }
    return array;
}

- (id)nextObject {
    if (index < count) {
        return (buffer + index++)->key;
    }
    return nil;
}

@end

@implementation JsonLiteDictionary

- (void)dealloc {
    for (int i = 0; i < count; i++) {
        CFRelease(buffer[i].key);
        CFRelease(buffer[i].value);
    }
    [super dealloc];
}

- (NSUInteger)count {
    return count;
}

- (id)objectForKey:(id)aKey {
    CFHashCode hash = CFHash((CFTypeRef)aKey);
    int index = hash & JsonLiteDictionaryFrontMask;
    for (JsonLiteDictionaryBucket *b = buckets[index]; b != NULL; b = b->next) {
        if (b->hash == hash && [b->key isEqual:aKey]) {
            return b->value;
        }
    }
    return nil;
}

- (NSEnumerator *)keyEnumerator {
    JsonLiteDictionaryEnumerator *e = [[JsonLiteDictionaryEnumerator alloc] initWithBuffer:buffer
                                                                                     count:count];
    return [e autorelease];
}

@end

@implementation JsonLiteArray

- (NSUInteger)count  {
    return count;
}

- (id)objectAtIndex:(NSUInteger)index {
    NSException *exc = nil;
    if (index >= count) {
        id cls = NSStringFromClass([self class]);
        id sel = NSStringFromSelector(_cmd);
        NSString *str = [NSString stringWithFormat:@"*** -[%@ %@]: index (%d) beyond bounds (%d)", cls, sel, (int)index,(int)count];
        exc = [NSException exceptionWithName:NSRangeException
                                      reason:str
                                    userInfo:nil];
    }
    [exc raise];
    return values[index];
}

- (void)dealloc {
    for (int i = 0; i < count; i++) {
        CFRelease(values[i]);
    }
    [super dealloc];
}

@end

id JsonLiteCreateDictionary(const id *values, const id *keys, const CFHashCode *hashes, NSUInteger count) {
    static Class cls = nil;
    static size_t size = 0;
    if (cls == nil) {
        cls = [JsonLiteDictionary class];
        size = class_getInstanceSize(cls);
    }

    JsonLiteDictionary *dict = class_createInstance(cls, count * sizeof(JsonLiteDictionaryBucket));
    dict->buffer = (JsonLiteDictionaryBucket *)((uint8_t *)dict  + size);
    dict->count = count;
    
    JsonLiteDictionaryBucket *b = dict->buffer;
    for (int i = 0; i < count; i++, b++) {
        CFHashCode hash = hashes[i];
        int index = hash & JsonLiteDictionaryFrontMask;
        b->hash = hash;
        b->key = keys[i];
        b->value = values[i];
        b->next = dict->buckets[index];
        dict->buckets[index] = b;
    }
    
    return dict;
}

id JsonLiteCreateArray(const id *objects, NSUInteger count) {
    static Class cls = nil;
    static size_t size = 0;
    if (cls == nil) {
        cls = [JsonLiteArray class];
        size = class_getInstanceSize(cls);
    }

    JsonLiteArray *array = class_createInstance(cls, count * sizeof(id));
    array = [array init];
    array->values = (id *)((uint8_t *)array + size);
    array->count = count;
    if (count > 0) {
        array->values = (id *)((uint8_t *)array + size);
        memcpy(array->values, objects, sizeof(id) * count); // LCOV_EXCL_LINE
    }
    return array;
}
