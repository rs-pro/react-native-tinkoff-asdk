
Pod::Spec.new do |s|
  s.name         = "RNTinkoffAsdk"
  s.version      = "1.0.0"
  s.summary      = "RNTinkoffAsdk"
  s.description  = <<-DESC
                  RNTinkoffAsdk
                   DESC
  s.homepage     = ""
  s.license      = "MIT"
  s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "author" => "glebtv@gmail.com" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/author/RNTinkoffAsdk.git", :tag => "master" }
  s.source_files  = "RNTinkoffAsdk/**/*.{h,m}"
  s.requires_arc = true


  s.dependency "React"

  s.dependency 'CardIO'
  s.dependency 'ASDKCore', :podspec =>  "https://raw.githubusercontent.com/TinkoffCreditSystems/tinkoff-asdk-ios/master/ASDKCore.podspec"
  s.dependency 'ASDKUI', :podspec =>  "https://raw.githubusercontent.com/TinkoffCreditSystems/tinkoff-asdk-ios/master/ASDKUI"

end

