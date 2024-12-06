#
# Be sure to run `pod lib lint CyweeBleSDK-iOS.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CyweeBleSDK-iOS'
  s.version          = '1.0.0'
  s.summary          = 'A short description of CyweeBleSDK-iOS.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/cyweemotions/CyweeBleSDK-iOS'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Chengang' => 'chengang@mokotechnology.com' }
  s.source           = { :git => 'https://github.com/cyweemotions/CyweeBleSDK-iOS.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'CyweeBleSDK-iOS/Classes/mk_fitpoloCentralGlobalHeader.h'
  
  s.subspec 'header' do |ss|
    ss.source_files = 'CyweeBleSDK-iOS/Classes/header/**'
  end
  
  s.subspec 'adopter' do |ss|
    ss.source_files = 'CyweeBleSDK-iOS/Classes/adopter/**'
    ss.dependency 'CyweeBleSDK-iOS/header'
  end
  
  s.subspec 'log' do |ss|
    ss.source_files = 'CyweeBleSDK-iOS/Classes/log/**'
    ss.dependency 'CyweeBleSDK-iOS/header'
  end
  
  s.subspec 'category' do |ss|
    ss.source_files = 'CyweeBleSDK-iOS/Classes/category/**'
  end
  
  s.subspec 'task' do |ss|
    ss.subspec 'fitpolo701' do |sss|
      sss.source_files = 'CyweeBleSDK-iOS/Classes/task/fitpolo701/**'
      sss.dependency 'CyweeBleSDK-iOS/header'
      sss.dependency 'CyweeBleSDK-iOS/adopter'
      sss.dependency 'CyweeBleSDK-iOS/log'
    end
    ss.subspec 'fitpoloCurrent' do |sss|
      sss.source_files = 'CyweeBleSDK-iOS/Classes/task/fitpoloCurrent/**'
      sss.dependency 'CyweeBleSDK-iOS/header'
      sss.dependency 'CyweeBleSDK-iOS/adopter'
      sss.dependency 'CyweeBleSDK-iOS/log'
    end
    ss.subspec 'operation' do |sss|
      sss.source_files = 'CyweeBleSDK-iOS/Classes/task/operation/**'
      sss.dependency 'CyweeBleSDK-iOS/header'
      sss.dependency 'CyweeBleSDK-iOS/task/fitpolo701'
      sss.dependency 'CyweeBleSDK-iOS/task/fitpoloCurrent'
    end
  end
  
  s.subspec 'centralManager' do |ss|
    ss.source_files = 'CyweeBleSDK-iOS/Classes/centralManager/**'
    ss.dependency 'CyweeBleSDK-iOS/header'
    ss.dependency 'CyweeBleSDK-iOS/adopter'
    ss.dependency 'CyweeBleSDK-iOS/category'
    ss.dependency 'CyweeBleSDK-iOS/log'
    ss.dependency 'CyweeBleSDK-iOS/task/operation'
  end
  
  s.subspec 'interface' do |ss|
    ss.subspec 'device' do |sss|
      sss.source_files = 'CyweeBleSDK-iOS/Classes/interface/device/**'
    end
    ss.subspec 'model' do |sss|
      sss.source_files = 'CyweeBleSDK-iOS/Classes/interface/model/**'
    end
    ss.subspec 'userData' do |sss|
      sss.source_files = 'CyweeBleSDK-iOS/Classes/interface/userData/**'
    end
    
    ss.dependency 'CyweeBleSDK-iOS/header'
    ss.dependency 'CyweeBleSDK-iOS/adopter'
    ss.dependency 'CyweeBleSDK-iOS/category'
    ss.dependency 'CyweeBleSDK-iOS/log'
    ss.dependency 'CyweeBleSDK-iOS/task/operation'
    ss.dependency 'CyweeBleSDK-iOS/centralManager'
  end
  
  s.subspec 'update' do |ss|
    ss.source_files = 'CyweeBleSDK-iOS/Classes/update/**'
    
    ss.dependency 'CyweeBleSDK-iOS/adopter'
    ss.dependency 'CyweeBleSDK-iOS/centralManager'
    ss.dependency 'CyweeBleSDK-iOS/header'
    ss.dependency 'CyweeBleSDK-iOS/interface'
  end
  
end
