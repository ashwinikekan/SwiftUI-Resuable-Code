platform :ios, '16.0'

target 'TadaMVL' do
  use_frameworks!

  # Pods for TadaMVL
  pod 'Alamofire'

  target 'TadaMVLTests' do
    inherit! :search_paths
  end

  target 'TadaMVLUITests' do
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    end
  end
end
