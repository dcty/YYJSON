//
// Created by ivan on 13-7-12.
//
//


#import <Foundation/Foundation.h>

@interface NSData (YYJSON)
- (id)toModel:(Class)modelClass;

- (id)toModel:(Class)modelClass forKey:(NSString *)key;

- (NSArray *)toModels:(Class)modelClass;

- (NSArray *)toModels:(Class)modelClass forKey:(NSString *)key;
@end