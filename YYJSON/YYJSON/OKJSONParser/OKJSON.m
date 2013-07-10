/*
 * Copyright 2012 - 2013 Kulykov Oleh
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


#import "OKJSON.h"

#ifndef __has_feature
#define __has_feature(x) 0
#endif

#if __has_feature(objc_arc)
#endif


@implementation OKJSON

+ (id) parse:(NSData *)data withError:(NSError **)error
{
	const uint32_t dataSize = [data length];
	const uint8_t * uData = (const uint8_t *)[data bytes];
	return (dataSize && uData) ? [OKJSONParserParse(uData, dataSize, (void **)error) autorelease] : nil;
}

@end
