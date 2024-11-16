#
# Be sure to run `pod lib lint SwiftSQLiteORM.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SwiftSQLiteORM'
  s.version          = '0.1.20241116'
  s.summary          = 'Swift ORM Protocol build on GRDB.swift/SQLCipher'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Swift ORM Protocol build on GRDB.swift/SQLCipher, will auto create and connect database file, create or alter table schema, mapping value between instance property and table column
                       DESC

  s.homepage         = 'https://github.com/lalawue/SwiftSQLiteORM'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'lalawue' => 'suchaaa@gmail.com' }
  s.source           = { :git => 'https://github.com/lalawue/SwiftSQLiteORM.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'
  s.swift_versions   = '5.0'
  s.source_files = 'SwiftSQLiteORM/Classes/**/*'
  
  # s.resource_bundles = {
  #   'SwiftSQLiteORM' => ['SwiftSQLiteORM/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'Runtime'
  s.dependency 'GRDB.swift/SQLCipher'
  s.dependency 'SQLCipher', '~> 4.0'
end
