# Podfile for GeoHunter: Somaiya Edition
# Target: iOS 17.0+

platform :ios, '17.0'
use_frameworks!

target 'GeoHunterSomaiya' do
  # Google ML Kit Vision & On-Device Image Labeling
  pod 'GoogleMLKit/ImageLabeling', '7.0.0'

  # Target configuration hooks
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        # Enforce modern iOS deployment target
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
        # Enable module stability & Swift concurrency checks
        config.build_settings['SWIFT_STRICT_CONCURRENCY'] = 'complete'
      end
    end
  end
end
