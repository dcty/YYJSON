//
// Created by ivan on 13-7-12.
//
//


#import <Foundation/Foundation.h>

typedef enum
{
    YYNSJSONSerialization = 0,
    YYJSONKit,
    YYJsonLiteParser,
    YYOKJSONParser

} YYJSONParserType;

@interface NSData (YYJSON)
- (id)toModel:(Class)modelClass;

- (id)toModel:(Class)modelClass forKey:(NSString *)key;

- (NSArray *)toModels:(Class)modelClass;

- (NSArray *)toModels:(Class)modelClass forKey:(NSString *)key;

+ (void)setYYJSONParserType:(YYJSONParserType)type;
@end