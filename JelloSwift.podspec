#
# Be sure to run `pod lib lint JelloSwift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'JelloSwift'
  s.version          = '0.11.0'
  s.summary          = 'Swift soft body physics engine.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
JelloSwift is a soft body physics engine written in Swift, ported from Walaber's JelloPhysics engine.

The intention is to write a fast and concise physics engine to be used in games on iOS.
                       DESC

  s.homepage         = 'https://github.com/LuizZak/JelloSwift'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'LuizZak' => 'luizinho_mack@yahoo.com.br' }
  s.source           = { :git => 'https://github.com/LuizZak/JelloSwift.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/LuizZak'

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'

  s.source_files = 'Sources/**/*'
end
