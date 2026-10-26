Pod::Spec.new do |s|
  s.name             = 'flutter_biometric'
  s.version          = '0.1.0'
  s.summary          = 'Forge biometric bridge macOS implementation'
  s.description      = 'Typed LocalAuthentication adapter for biometric capability queries and prompts.'
  s.homepage         = 'https://github.com/lizy-coding/flutter_forge'
  s.author           = { 'flutter_forge contributors' => '' }
  s.source           = { :path => '.' }
  s.source_files     = 'flutter_biometric/Classes/**/*'
  s.public_header_files = 'flutter_biometric/Classes/**/*.h'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.15'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_VERSION' => '5.0',
  }
  s.swift_version = '5.0'
end
