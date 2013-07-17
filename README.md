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

这个方法返回JSON对象，可以选择自己习惯的JSON解析库   
可以自行查看源文件，我写了如下  
>1. iOS自带的NSJSONSerialization  
2.  JSONKit  
3.  OKJSONParser （号称自己是最快的）  
4. JsonLiteParser （也是号称自己是最快的）

速度方面我没有进行测试

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