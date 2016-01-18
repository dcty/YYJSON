YYJSON
======

##2.0 版本已经上传，由于作者太懒，不做之前版本的兼容，所以一时间不提交了，不然pod 一更新就跪了，建议用2.0版本因为1.x的可能不维护了，当然有问题的话，尽管提，有问题就改，因为2.0我没怎么测试我会乱说。

2.0的实现和1.x是类似的，没啥本质上的区别，但是代码上来说应该还是会比之前的来得少一些。

将JSON数据直接转成NSObject  
支持 NSString，NSNumber，int，float，BOOL，NSArray，OtherModel。 

	2014-07-15 10:44:07 update

	从dict取值改为valueForkeyPath，支持用路径来取值了

	@interface Test1 : NSObject
	@property (assign,nonatomic)int code;
	@property (strong,nonatomic)Data *data;
	@property (copy,nonatomic)NSString *country;
	@property (strong,nonatomic)Data *subdata;
	@end
	@implementation Test1

	+ (void)initialize
	{
    	[super initialize];
	    [self bindYYJSONKey:@"data.country" toProperty:@"country"];
	    //country不是自定义的NSObject所以不需要特殊处理
    	[self bindYYJSONKey:@"data.subdata" toProperty:@"subdata.Data"]; 
    	//对应的是subdata property设置为 subdata.ClassName就可了 一般情况这种蛋疼的写法很少吧，不过还是做一下支持。
	}
	@end
	
	json 数据如下
	{
    "code": 0,
    "data": {
        "subdata": {
            "country": "米国"
        },
        "country": "中国",
        "country_id": "CN",
        "area": "华东",
        "area_id": "300000",
        "region": "安徽省",
        "region_id": "340000",
        "city": "合肥市",
        "city_id": "340100",
        "county": "",
        "county_id": "-1",
        "isp": "电信",
        "isp_id": "100017",
        "ip": "218.22.9.4"
    }


 

	update：2013-07-17
	新增 

	- (NSString *)YYJSONString;

	- (NSData *)YYJSONData;
	

Demo中有体现。

***
支持自己选择JSON解析器

-  NSData (YYJSONHelper)
------
 -(id)YYJSONObject
####	根据苹果官网开发者版块的数据显示，截止到 6 月 29 日，已有 94% 的 iOS 用户已经升级了 iOS 6。仅有 5% 的用户停留在 iOS 5，iOS 5 以下的版本只有 1%。  
所以目前只采用iOS自带的NSJSONSerialization  

***
使用方法
> -(id)toModel:(Class)modelClass;   
传入一个modelClass返回一个modelClass的实例

=

>-(id)toModel:(Class)modelClass forKey:(NSString *)key;   
传入一个modelClass和key(json的key)返回一个modelClass实例

=

> -(NSArray *)toModels:(Class)modelClass;  
传入一个modelClass返回一个modelClass的集合

=

> -(NSArray *)toModels:(Class)modelClass forKey:(NSString *)key;  
传入一个modelClass和key(json的key)返回一个modelClass的集合

	NSURL *url = [NSURL URLWithString:@"http://url.cn/DjjSlB"];  
	NSData *data = [NSData dataWithContentsOfURL:url];  
	NSArray *shots = [data toModels:[Shot class] forKey:@"shots"];  
	Player *player = [shots[0] player];
	

支持自己绑定属性名和JSON对应的key
---------
	@interface NSObject (YYJSON)
	//如果需要获取父类的属性，则重载此方法并且return YES
	+ (BOOL)YYSuper;
	//映射的字典
	+ (NSDictionary *)YYJSONKeyDict;
	//自定义绑定 
	+ (void)bindYYJSONKey:(NSString *)jsonKey toProperty:(NSString *)property;
	@end
	
####具体使用方法看Demo吧