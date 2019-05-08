Pod::Spec.new do |s|
  s.name         = 'SJBaseVideoPlayer'
  s.version      = '2.4.4'
  s.summary      = 'video player.'
  s.description  = 'https://github.com/changsanjiang/SJBaseVideoPlayer/blob/master/README.md'
  s.homepage     = 'https://github.com/changsanjiang/SJBaseVideoPlayer'
  s.license      = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author       = { 'SanJiang' => 'changsanjiang@gmail.com' }
  s.platform     = :ios, '8.0'
  s.source       = { :git => 'https://github.com/changsanjiang/SJBaseVideoPlayer.git', :tag => "v#{s.version}" }
  s.frameworks  = "UIKit", "AVFoundation"
  s.requires_arc = true
  s.dependency 'Masonry'
  s.dependency 'SJUIKit/ObserverHelper', '>= 0.0.0.23'
  s.dependency 'SJUIKit/Queues', '>= 0.0.0.23'
  s.dependency 'Reachability'

  s.source_files = 'SJBaseVideoPlayer/*.{h,m}'

  s.subspec 'Header' do |ss|
      ss.source_files = 'SJBaseVideoPlayer/Header/*.{h}'
  end

  s.subspec 'Tool' do |ss|
      ss.source_files = 'SJBaseVideoPlayer/Tool/*.{h,m}'
      ss.dependency 'SJBaseVideoPlayer/Header'
      ss.dependency 'SJBaseVideoPlayer/Model'
  end

  s.subspec 'Model' do |ss|
      ss.source_files = 'SJBaseVideoPlayer/Model/*.{h,m}'
      ss.dependency 'SJBaseVideoPlayer/Header'
  end

  s.subspec 'SJAVMediaPlaybackController' do |ss|
      ss.source_files = 'SJBaseVideoPlayer/SJAVMediaPlaybackController/*.{h,m}'
      ss.subspec 'Core' do |sss|
          sss.source_files = 'SJBaseVideoPlayer/SJAVMediaPlaybackController/Core/*.{h,m}'
      end
      ss.dependency 'SJBaseVideoPlayer/Tool'
  end

  s.subspec 'SJPrompt' do |ss|
      ss.source_files = 'SJBaseVideoPlayer/SJPrompt/*.{h,m}'
  end

  s.subspec 'SJRotationManager' do |ss|
      ss.source_files = 'SJBaseVideoPlayer/SJRotationManager/*.{h,m}'
      ss.dependency 'SJBaseVideoPlayer/Header'
  end

  s.subspec 'SJDeviceVolumeAndBrightnessManager' do |ss|
      ss.dependency 'SJBaseVideoPlayer/Header'
      ss.source_files = 'SJBaseVideoPlayer/SJDeviceVolumeAndBrightnessManager/*.{h,m}'
      ss.subspec 'Core' do |sss|
        sss.source_files = 'SJBaseVideoPlayer/SJDeviceVolumeAndBrightnessManager/Core/*.{h,m}'
        sss.dependency 'SJBaseVideoPlayer/SJDeviceVolumeAndBrightnessManager/ResourceLoader'
      end
      
      ss.subspec 'ResourceLoader' do |sss|
        sss.source_files = 'SJBaseVideoPlayer/SJDeviceVolumeAndBrightnessManager/ResourceLoader/*.{h,m}'
        sss.resources = 'SJBaseVideoPlayer/SJDeviceVolumeAndBrightnessManager/ResourceLoader/SJDeviceVolumeAndBrightnessManager.bundle'
      end
  end
end
