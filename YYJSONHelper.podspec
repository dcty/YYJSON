Pod::Spec.new do |s|
  s.name         = 'YYJSONHelper'
  s.version      = '1.0.2'
  s.summary      = '将JSON数据直接转成NSObject,将NSObject转为JSONString或JSONData'
  s.homepage     = 'https://github.com/dcty/YYJSON'
  s.license      = 'MIT'
  s.author       = { "Ivan" => "dcty@qq.com" }
  s.source       = { :git => 'https://github.com/dcty/YYJSON.git'}
  s.platform     = :ios,'5.0'
  s.source_files = 'YYJSON/YYJSON/YYJSON/YYJSONHelper.{h,m}'
  s.requires_arc = true
end
