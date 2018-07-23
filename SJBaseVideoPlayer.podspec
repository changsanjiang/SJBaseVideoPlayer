Pod::Spec.new do |s|
s.name         = 'SJBaseVideoPlayer'
s.version      = '1.3.1.2'
s.summary      = 'video player.'
s.description  = 'https://github.com/changsanjiang/SJBaseVideoPlayer/blob/master/README.md'
s.homepage     = 'https://github.com/changsanjiang/SJBaseVideoPlayer'
s.license      = { :type => 'MIT', :file => 'LICENSE.md' }
s.author       = { 'SanJiang' => 'changsanjiang@gmail.com' }
s.platform     = :ios, '8.0'
s.source       = { :git => 'https://github.com/changsanjiang/SJBaseVideoPlayer.git', :tag => "v#{s.version}" }
s.frameworks  = "UIKit", "AVFoundation"
s.requires_arc = true
s.dependency 'SJUIFactory'
s.dependency 'Masonry'
s.dependency 'SJObserverHelper'
s.dependency 'Reachability'

s.source_files = 'SJBaseVideoPlayer/*.{h,m}'

s.subspec 'Header' do |ss|
    ss.source_files = 'SJBaseVideoPlayer/Header/*.{h}'
end

s.subspec 'Present' do |ss|
    ss.source_files = 'SJBaseVideoPlayer/Present/*.{h,m}'
    ss.dependency 'SJBaseVideoPlayer/Header'
end

s.subspec 'Category' do |ss|
    ss.source_files = 'SJBaseVideoPlayer/Category/*.{h,m}'
end

s.subspec 'Registrar' do |ss|
    ss.source_files = 'SJBaseVideoPlayer/Registrar/*.{h,m}'
end

s.subspec 'GestureControl' do |ss|
    ss.source_files = 'SJBaseVideoPlayer/GestureControl/*.{h,m}'
end

s.subspec 'TimerControl' do |ss|
    ss.source_files = 'SJBaseVideoPlayer/TimerControl/*.{h,m}'
    ss.dependency 'SJBaseVideoPlayer/Category'
end

s.subspec 'Model' do |ss|
    ss.source_files = 'SJBaseVideoPlayer/Model/*.{h,m}'
    ss.dependency 'SJBaseVideoPlayer/Category'
    ss.dependency 'SJBaseVideoPlayer/Header'
end

s.subspec 'Download' do |ss|
    ss.source_files = 'SJBaseVideoPlayer/Download/*.{h,m}'
    ss.ios.library = 'sqlite3'
end

s.subspec 'SJRotationManager' do |ss|
    ss.source_files = 'SJBaseVideoPlayer/SJRotationManager/*.{h,m}'
end

s.subspec 'SJVolBrigControl' do |ss|
    ss.source_files = 'SJBaseVideoPlayer/SJVolBrigControl/*.{h,m}'
    ss.resource  = "SJBaseVideoPlayer/SJVolBrigControl/Resource/SJVolBrigResource.bundle"
    ss.subspec 'Resource' do |sss|
        sss.source_files = "SJBaseVideoPlayer/SJVolBrigControl/Resource/*.{h,m}"
    end
end

s.subspec 'SJPrompt' do |ss|
    ss.source_files = 'SJBaseVideoPlayer/SJPrompt/*.{h,m}'
end

end
