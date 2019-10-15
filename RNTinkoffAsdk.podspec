
Pod::Spec.new do |s|
  s.name         = "RNTinkoffAsdk"
  s.version      = "0.1.0"
  s.summary      = "RNTinkoffAsdk"
  s.description  = <<-DESC
                  tinkoff acquiring sdk for react natives
                   DESC
  s.homepage     = "https://github.com/rs-pro/react-native-tinkoff-asdk"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "author" => "glebtv@gmail.com" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/author/RNTinkoffAsdk.git", :tag => "master" }
  s.source_files  = "ios/**/*.{h,m}"
  s.requires_arc = true


  s.dependency "React"

  s.dependency 'CardIO'
  s.dependency 'ASDKCore'
  s.dependency 'ASDKUI'

end
