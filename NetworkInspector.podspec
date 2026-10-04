Pod::Spec.new do |s|
  s.name             = 'NetworkInspector'
  s.version          = '1.0.2'
  s.summary          = 'In-app network inspector for iOS (URLSession, diagnostics, export).'
  s.homepage         = 'https://github.com/TheNachi/NetworkInspectorIOS'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'NetworkInspector' => 'opensource@example.com' }
  s.source           = { :git => 'https://github.com/TheNachi/NetworkInspectorIOS.git', :tag => s.version.to_s }

  s.platform     = :ios, '16.0'
  s.swift_versions = ['5.9']

  # Same source tree as SPM. CocoaPods builds a single module named NetworkInspector.
  s.source_files = 'Sources/**/*.{swift}'
  s.exclude_files = 'Tests/**/*', 'Examples/**/*', 'Docs/**/*', '.github/**/*'
end