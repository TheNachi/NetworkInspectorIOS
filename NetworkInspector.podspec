Pod::Spec.new do |s|
  s.name             = 'NetworkInspector'
  s.version          = '1.0.0'
  s.summary          = 'In-app network inspector for iOS (URLSession, diagnostics, export).'
  s.homepage         = 'https://example.com/NetworkInspector'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'NetworkInspector' => 'opensource@example.com' }
  s.source           = { :git => 'https://example.com/NetworkInspector.git', :tag => s.version.to_s }

  s.ios.deployment_target = '16.0'
  s.swift_versions = ['5.9']

  # Use the same source tree as SPM
  s.source_files = 'Sources/**/*.{swift}'
  s.exclude_files = 'Tests/**/*', 'Examples/**/*', 'Docs/**/*', '.github/**/*'
end