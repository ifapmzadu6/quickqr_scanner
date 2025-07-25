#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint quickqr_scanner.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'quickqr_scanner_plugin'
  s.version          = '1.1.0'
  s.summary          = 'High-performance QR scanner with VisionKit integration'
  s.description      = <<-DESC
QuickQR Scanner Plugin provides high-performance QR code scanning with VisionKit integration and advanced image processing capabilities.
                       DESC
  s.homepage         = 'https://github.com/ifapmzadu6/quickqr_scanner_plugin'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'QuickQR' => 'quickqr@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'quickqr_scanner_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
