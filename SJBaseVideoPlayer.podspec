Pod::Spec.new do |s|
  s.name         = 'SJBaseVideoPlayer'
  s.version      = '3.1.2'
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
  s.dependency 'SJUIKit/ObserverHelper', '>= 0.0.0.31'
  s.dependency 'SJUIKit/Queues', '>= 0.0.0.31'
  s.dependency 'Reachability'

  s.source_files = 'SJBaseVideoPlayer/*.{h,m}'

  s.default_subspecs = 'Header', 'Const', 'Tool', 'Model', 'SJDeviceVolumeAndBrightnessManager', 'AVPlayer'

  s.subspec 'Header' do |ss|
      ss.source_files = 'SJBaseVideoPlayer/Header/*.{h}'
  end
  
  s.subspec 'Const' do |ss|
      ss.source_files = 'SJBaseVideoPlayer/Const/*.{h,m}'
  end

  s.subspec 'Tool' do |ss|
      ss.source_files = 'SJBaseVideoPlayer/Tool/*.{h,m}'
      ss.dependency 'SJBaseVideoPlayer/Header'
      ss.dependency 'SJBaseVideoPlayer/Model'
      ss.dependency 'SJBaseVideoPlayer/Const'
  end

  s.subspec 'Model' do |ss|
      ss.source_files = 'SJBaseVideoPlayer/Model/*.{h,m}'
      ss.dependency 'SJBaseVideoPlayer/Header'
  end

  s.subspec 'SJDeviceVolumeAndBrightnessManager' do |ss|
      ss.dependency 'SJBaseVideoPlayer/Header'
      ss.dependency 'SJBaseVideoPlayer/Const'
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
  
  s.subspec 'AVPlayer' do |ss|
      ss.source_files = 'SJBaseVideoPlayer/AVPlayer/*.{h,m}'
      ss.subspec 'Core' do |sss|
          sss.source_files = 'SJBaseVideoPlayer/AVPlayer/Core/*.{h,m}'
      end
      ss.dependency 'SJBaseVideoPlayer/Tool'
  end
  
  s.subspec 'IJKPlayer' do |ss|
    ss.source_files = 'SJBaseVideoPlayer/IJKPlayer/*.{h,m}'
    ss.subspec 'Core' do |sss|
        sss.source_files = 'SJBaseVideoPlayer/IJKPlayer/Core/*.{h,m}'
    end
    ss.dependency 'SJBaseVideoPlayer/AVPlayer'
    ss.dependency 'ijkplayerssl'
  end
  
  s.subspec 'AliPlayer' do |ss|
    ss.source_files = 'SJBaseVideoPlayer/AliPlayer/*.{h,m}'
    ss.subspec 'Core' do |sss|
        sss.source_files = 'SJBaseVideoPlayer/AliPlayer/Core/*.{h,m}'
    end
    ss.dependency 'SJBaseVideoPlayer/AVPlayer'
    ss.dependency 'AliPlayerSDK_iOS'
  end
  
  s.subspec 'AliVodPlayer' do |ss|
      ss.source_files = 'SJBaseVideoPlayer/AliVodPlayer/*.{h,m}'
      ss.subspec 'Core' do |sss|
          sss.source_files = 'SJBaseVideoPlayer/AliVodPlayer/Core/*.{h,m}'
      end
      ss.dependency 'SJBaseVideoPlayer/AVPlayer'
      ss.dependency 'AliyunPlayer_iOS/AliyunVodPlayerSDK'
  end
end
