Pod::Spec.new do |s|
  s.name             = 'forge_notification_bridge'
  s.version          = '0.1.0'
  s.summary          = 'Forge notification bridge macOS implementation'
  s.description      = 'Typed UNUserNotificationCenter adapter for authorization states and local notifications.'
  s.homepage         = 'https://github.com/lizy-coding/flutter_forge'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'flutter_forge contributors' => '' }
  s.source           = { :path => '.' }
  s.source_files     = 'forge_notification_bridge/Classes/**/*'
  s.public_header_files = 'forge_notification_bridge/Classes/**/*.h'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_VERSION' => '5.0',
  }
  s.swift_version = '5.0'
end
