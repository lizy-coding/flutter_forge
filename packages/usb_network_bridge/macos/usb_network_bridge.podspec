Pod::Spec.new do |s|
  s.name = 'usb_network_bridge'
  s.version = '0.0.1'
  s.summary = 'CDC-NCM interface enumeration and bound TCP transport.'
  s.description = s.summary
  s.homepage = 'https://github.com/lizy-coding/flutter_forge'
  s.license = { :type => 'Proprietary', :file => '../LICENSE' }
  s.author = 'Flutter Forge contributors'
  s.source = { :path => '.' }
  s.source_files = 'Classes/**/*.{swift,c,h}'
  s.dependency 'FlutterMacOS'
  s.frameworks = 'IOKit'
  s.platform = :osx, '12.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
