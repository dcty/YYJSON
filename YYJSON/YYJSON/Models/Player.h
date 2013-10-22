//
// Created by ivan on 13-7-12.
//
//



@interface Player : NSObject <YYJSONHelperProtocol>

@property(nonatomic) int rebounds_count;
@property(nonatomic) int likes_received_count;
@property(nonatomic, copy) NSString *created_at;
@property(nonatomic, copy) NSString *webSiteURLString;
@property(nonatomic, copy) NSString *test;
@property(nonatomic, strong) NSArray *testArray;


@end