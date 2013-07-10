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

#import "JsonLiteSerializer.h"
#import "JsonLiteMetaData.h"

@interface JsonLiteSerializer()

- (void)serializeProperties:(NSObject *)obj;
- (void)serializeDictionary:(NSDictionary *)dict;
- (void)serializeArray:(NSArray *)array;
- (void)serializeValue:(id)obj;

@end

static int is_float(CFNumberRef number) {
    CFNumberType t = CFNumberGetType(number);
    int res = t == kCFNumberFloatType;
    res |= t == kCFNumberDoubleType;
    res |= t == kCFNumberFloat32Type;
    res |= t == kCFNumberFloat64Type;
    res |= t == kCFNumberCGFloatType;
    return res;
}

@implementation JsonLiteSerializer

@synthesize indentation;
@synthesize converter;

- (id)init {
    self = [super init];
    if (self != nil) {
        bs = NULL;
    }
    return self;
}

+ (id)serializer {
    return [[[JsonLiteSerializer alloc] init] autorelease];
}

- (void)dealloc {
    self.converter = nil;
    if (bs != NULL) {
        jsonlite_builder_release(bs);        
    }
    [super dealloc];
}

- (void)serializeProperties:(NSObject *)obj {
    jsonlite_builder_object_begin(bs);
    
    JsonLiteClassMetaData *metaData = [JsonLiteClassMetaData metaDataForClass:[obj class]];
    NSArray *keys = metaData.keys;
    NSUInteger count = [keys count];
    for (NSUInteger i = 0; i < count; i++) {
        id key = [keys objectAtIndex:i];
        JsonLiteClassProperty *property = [metaData propertyToBindKey:key];
        id value = [property valueOfObject:obj];
        char *buffer = (char *)[key cStringUsingEncoding:NSUTF8StringEncoding];
        jsonlite_builder_key(bs, buffer, strlen(buffer));
        [self serializeValue:value];
    }

    jsonlite_builder_object_end(bs);
}

- (void)serializeDictionary:(NSDictionary *)dict {
    jsonlite_builder_object_begin(bs);
    
    NSArray *keys = [dict allKeys];
    NSUInteger count = [keys count];
    for (NSUInteger i = 0; i < count; i++) {
        id key = [keys objectAtIndex:i];
        char *buffer = (char *)[key cStringUsingEncoding:NSUTF8StringEncoding];
        jsonlite_builder_key(bs, buffer, strlen(buffer));
        [self serializeValue:[dict objectForKey:key]];
    }
    
    jsonlite_builder_object_end(bs);
}

- (void)serializeArray:(NSArray *)array {
    jsonlite_builder_array_begin(bs);

    NSUInteger count = [array count];
    for (NSUInteger i = 0; i < count; i++) {
        [self serializeValue:[array objectAtIndex:i]];
    }

    jsonlite_builder_array_end(bs);
}

- (void)serializeValue:(id)obj {
    if (obj == nil || [obj isKindOfClass:[NSNull class]]) {
        jsonlite_builder_null(bs);
        return;
    }
    
    NSData *data = nil;
    if ([converter getData:&data forValue:obj serializer:self]) {
        jsonlite_builder_raw_value(bs, [data bytes], [data length]);
        return;
    }
    
    if ([obj isKindOfClass:[NSString class]]) {
        char *buffer = (char *)[obj cStringUsingEncoding:NSUTF8StringEncoding];
        jsonlite_builder_string(bs, buffer, strlen(buffer));
        return;
    }
    
    if ([obj isKindOfClass:[NSNumber class]]) {
        if ((CFBooleanRef)obj == kCFBooleanTrue) {
            jsonlite_builder_true(bs);
            return;
        }
        
        if ((CFBooleanRef)obj == kCFBooleanFalse) {
            jsonlite_builder_false(bs);
            return;
        }
        
        if (is_float((CFNumberRef)obj)) {
            jsonlite_builder_double(bs, [obj doubleValue]);
        } else {
            jsonlite_builder_int(bs, [obj longLongValue]);
        }
        return;
    }
    
    if ([obj isKindOfClass:[NSArray class]]) {
        [self serializeArray:obj];
        return;
    }
    
    if ([obj isKindOfClass:[NSDictionary class]]) {
        [self serializeDictionary:obj];
        return;
    }
    
    [self serializeProperties:obj];
}

- (NSData *)serializeObject:(id)obj {
    if (bs != NULL) {
        jsonlite_builder_release(bs);        
    }    
    
    bs = jsonlite_builder_init(16);
    jsonlite_builder_set_indentation(bs, indentation > 0 ? (size_t)indentation : 0);
    
    if ([obj isKindOfClass:[NSArray class]]) {
        [self serializeArray:obj];
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
        [self serializeDictionary:obj];
    } else {
        [self serializeProperties:obj];
    }

    char *data = NULL;
    size_t size = 0;
    jsonlite_builder_data(bs, &data, &size);    
    NSData *result = [[NSData alloc] initWithBytesNoCopy:data length:size freeWhenDone:YES];
    return [result autorelease];
}

@end
