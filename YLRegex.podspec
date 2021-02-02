Pod::Spec.new do |s|
  s.name         = "YLRegex"
  s.version      = "1.0.2"
  s.summary      = "一个简单易用的正则表达式库."
  s.homepage     = "https://github.com/YuLeiFuYun/YLRegex"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "YuLeiFuYun" => "yuleifuyunn@gmail.com" }
  s.swift_version = "5.1"
  s.platform     = :ios, "10.0"	
  s.source       = { :git => "https://github.com/YuLeiFuYun/YLRegex.git", :tag => s.version }
  s.source_files = "Sources/YLRegex/*.swift"
end
