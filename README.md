YYJSON
======

将JSON数据直接转成NSObject  
支持 NSString，NSNumber，int，float，BOOL，NSArray，OtherModel。  

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