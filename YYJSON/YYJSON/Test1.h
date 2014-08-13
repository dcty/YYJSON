//
//  Test1.h
//  YYJSON
//
//  Created by Ivan Chua on 14-7-6.
//  Copyright (c) 2014年 Ivan Chua. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YYJSONHelper.h"

@protocol Data <NSObject>

@end

@interface Data : NSObject<YYJSONHelperProtocol>
@property (copy,nonatomic)NSString *country;
@property (assign,nonatomic)int country_id;
@property (copy,nonatomic)NSString *area;
@property (assign,nonatomic)int area_id;
@property (copy,nonatomic)NSString *region;
@property (assign,nonatomic)int region_id;
@property (copy,nonatomic)NSString *city;
@property (assign,nonatomic)int city_id;
@property (copy,nonatomic)NSString *county;
@property (assign,nonatomic)int county_id;
@property (copy,nonatomic)NSString *isp;
@property (assign,nonatomic)int isp_id;
@property (copy,nonatomic)NSString *ip;
@end

@interface Test1 : NSObject
@property (assign,nonatomic)int code;
@property (strong,nonatomic)Data *data;
@property (copy,nonatomic)NSString *country;
@property (strong,nonatomic)Data *subdata;
@property (copy,nonatomic)NSString *miguo;
@end
