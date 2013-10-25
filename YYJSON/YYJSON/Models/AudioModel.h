//
//  AudioModel.h
//  YYJSON
//
//  Created by Ivan on 13-10-25.
//  Copyright (c) 2013年 Ivan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioModel : NSObject
@property (copy, nonatomic) NSString	*audioSrc;
@property(strong, nonatomic) NSArray	*audioParts;
@property(strong, nonatomic) NSArray	*wordsOfGame;
@end

