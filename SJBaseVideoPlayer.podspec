Pod::Spec.new do |s|
s.name         = 'SJBaseVideoPlayer'
s.version      = '1.7.7'
s.summary      = 'video player.'
s.description  = 'https://github.com/changsanjiang/SJBaseVideoPlayer/blob/master/README.md'
s.homepage     = 'https://github.com/changsanjiang/SJBaseVideoPlayer'
s.license      = { :type => 'MIT', :file => 'LICENSE.md' }
s.author       = { 'SanJiang' => 'changsanjiang@gmail.com' }
s.platform     = :ios, '8.0'
s.source       = { :git => 'https://gitee.com/changsanjiang/SJBaseVideoPlayer.git', :tag => "v#{s.version}" }
s.frameworks  = "UIKit", "AVFoundation"
s.requires_arc = true
s.dependency 'Masonry'
s.dependency 'SJObserverHelper'
s.dependency 'Reachability'

s.source_files = 'SJBaseVideoPlayer/*.{h,m}'

s.subspec 'Header' do |ss|
    ss.source_files = 'SJBaseVideoPlayer/Header/*.{h}'
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
    ss.dependency 'SJBaseVideoPlayer/Header'
    ss.dependency 'SJBaseVideoPlayer/Model'
end

s.subspec 'SJPrompt' do |ss|
    ss.source_files = 'SJBaseVideoPlayer/SJPrompt/*.{h,m}'
end

s.subspec 'SJRotationManager' do |ss|
    ss.source_files = 'SJBaseVideoPlayer/SJRotationManager/*.{h,m}'
    ss.dependency 'SJBaseVideoPlayer/Header'
end

s.subspec 'SJVolBrigControl' do |ss|
    ss.source_files = 'SJBaseVideoPlayer/SJVolBrigControl/*.{h,m}'
    ss.resource  = "SJBaseVideoPlayer/SJVolBrigControl/Resource/SJVolBrigResource.bundle"
    ss.subspec 'Resource' do |sss|
        sss.source_files = "SJBaseVideoPlayer/SJVolBrigControl/Resource/*.{h,m}"
    end
end

s.subspec 'Tool' do |ss|
    ss.source_files = 'SJBaseVideoPlayer/Tool/*.{h,m}'
    ss.ios.library = 'sqlite3'
end

end
