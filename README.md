# SJBaseVideoPlayer

___

### Installation
```ruby
# Player with default control layer.
pod 'SJVideoPlayer'

# The base player, without the control layer, can be used if you need a custom control layer.
pod 'SJBaseVideoPlayer'
```
___

## Contact
* Email: changsanjiang@gmail.com
* QQ: 1779609779
* QQ群: 719616775  

___

## License
SJBaseVideoPlayer is available under the MIT license. See the LICENSE file for more info.

___

## Documents

#### <a href="#1-可在以下视图层次中播放">1. 可在以下视图层次中播放</a>

1.1 在普通 View 上播放
1.2 在 TableViewCell 上播放
1.3 在 TableViewHeaderView 上播放
1.4 在 CollectionViewCell 上播放
1.5 CollectionView 嵌套在 TableViewHeaderView 中, 在 CollectionViewCell 上播放
1.6 CollectionView 嵌套在 TableViewCell 中, 在 CollectionViewCell 上播放
1.7 CollectionView 嵌套在 CollectionViewCell 中, 在 CollectionViewCell 上播放

#### 2. 创建资源进行播放
2.1 通过 URL 创建资源进行播放
2.2 通过 AVAsset 或其子类进行播放
2.3 指定开始播放的时间
2.4 续播. 进入下个页面时, 继续播放
2.5 销毁时的回调. 可在此时做一些记录工作, 如播放时长

#### 3. 播放控制
3.1 当前时间和时长
3.2 时间改变时的回调
3.3 播放结束后的回调
3.4 播放状态 - 未知/准备/准备就绪/播放中/暂停的/不活跃的
3.5 暂停的原因 - 缓冲/跳转/暂停
3.6 不活跃的原因 - 加载失败/播放完毕
3.7 播放状态改变的回调
3.8 是否自动播放 - 当资源初始化完成后
3.9 刷新 
3.10 播放器的声音设置 & 静音
3.11 播放
3.12 暂停
3.13 是否暂停 - 当App进入后台后
3.14 停止播放
3.15 重播
3.16 跳转到指定的时间播放
3.17 调速 & 速率改变时的回调
3.18 自己动手撸一个 SJMediaPlaybackController 或接入别的视频 SDK, 替换作者原始实现

#### 4. 控制层的显示和隐藏
4.1 让控制层显示
4.2 让控制层隐藏
4.3 控制层是否显示中
4.4 是否在暂停时保持控制层显示
4.5 是否自动显示控制层 - 资源初始化完成后
4.6 控制层显示状态改变的回调
4.7 禁止管理控制层的显示和隐藏
4.8 自己动手撸一个 SJControlLayerAppearManager, 替换作者原始实现

#### 5. 设备亮度和音量
5.1 调整设备亮度
5.2 调整设备声音
5.3 亮度 & 声音改变后的回调
5.3 自己动手撸一个 SJDeviceVolumeAndBrightnessManager, 替换作者原始实现

#### 6. 旋转
6.1 自动旋转
6.2 设置自动旋转支持的方向
6.3 禁止自动旋转
6.4 主动调用旋转
6.5 是否全屏
6.6 是否正在旋转
6.7 当前旋转的方向 
6.8 旋转开始和结束的回调
6.9 使 ViewController 一起旋转
6.10 自己动手撸一个 SJRotationManager, 替换作者原始实现

#### 7. 直接全屏而不旋转
7.1 全屏和恢复
7.2 开始和结束的回调
7.3 是否是全屏
7.4 自己动手撸一个 SJFitOnScreenManager, 替换作者原始实现

#### 8. 镜像翻转
8.1 翻转和恢复
8.2 开始和结束的回调
8.3  自己动手撸一个 SJFlipTransitionManager, 替换作者原始实现

#### 9. 网络状态
9.1 当前的网络状态
9.2 网络状态改变的回调
9.3 自己动手撸一个 SJReachability, 替换作者原始实现

#### 10. 手势
10.1 单击手势
10.2 双击手势
10.3 移动手势
10.4 捏合手势
10.5 禁止某些手势
10.6 自定义某个手势的处理
10.7 自己动手撸一个 SJPlayerGestureControl, 替换作者原始实现

#### 11. 占位图
11.1 设置本地占位图
11.2 设置网络占位图

#### 12. 显示提示文本
12.1 显示文本及持续时间 - (NSString or NSAttributedString)
12.2 配置提示文本

#### 13. 一些固定代码
13.1 - (void)vc_viewDidAppear; 
13.2 - (void)vc_viewWillDisappear;
13.3 - (void)vc_viewDidDisappear;
13.4 - (BOOL)vc_prefersStatusBarHidden;
13.5 - (UIStatusBarStyle)vc_preferredStatusBarStyle;
13.6 - 临时显示状态栏
13.7 - 临时隐藏状态栏

#### 14. 截屏
14.1 当前时间截图
14.2 指定时间截图
14.3 生成预览视图, 大约20张

#### 15. 导出视频或GIF
15.1 导出视频
15.2 导出GIF
15.3 取消操作

#### 16. 滚动相关
16.1 是否在 UICollectionView 或者 UITableView 中播放
16.2 是否滚动显示
16.3 播放器视图将要滚动显示和消失的回调

#### 17. 自动播放 - 在 UICollectionView 或者 UITableView 中
17.1 开启
17.2 配置
17.3 关闭
17.4 主动调用播放下一个资源

#### 18. 控制层数据源, 每个方法介绍
18.1 - (UIView *)controlView;
18.2 - (BOOL)controlLayerDisappearCondition;
18.3 - (BOOL)triggerGesturesCondition:(CGPoint)location;
18.4 - (void)installedControlViewToVideoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer;

#### 19. 控制层代理, 每个方法介绍
19.1 - (void)controlLayerNeedAppear:(__kindof SJBaseVideoPlayer *)videoPlayer;
19.2 - (void)controlLayerNeedDisappear:(__kindof SJBaseVideoPlayer *)videoPlayer;
19.3 - (void)videoPlayerWillAppearInScrollView:(__kindof SJBaseVideoPlayer *)videoPlayer;
19.4 - (void)videoPlayerWillDisappearInScrollView:(__kindof SJBaseVideoPlayer *)videoPlayer;
19.5 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer prepareToPlay:(SJVideoPlayerURLAsset *)asset;
19.6 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer statusDidChanged:(SJVideoPlayerPlayStatus)status;
19.7 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer
currentTime:(NSTimeInterval)currentTime currentTimeStr:(NSString *)currentTimeStr
totalTime:(NSTimeInterval)totalTime totalTimeStr:(NSString *)totalTimeStr;
19.8 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer presentationSize:(CGSize)size;
19.9 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer muteChanged:(BOOL)mute;
19.11 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer volumeChanged:(float)volume;
19.12 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer brightnessChanged:(float)brightness;
19.13 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer rateChanged:(float)rate;
19.14 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer loadedTimeProgress:(float)progress;
19.15 - (void)startLoading:(__kindof SJBaseVideoPlayer *)videoPlayer;
19.16 - (void)cancelLoading:(__kindof SJBaseVideoPlayer *)videoPlayer;
19.17 - (void)loadCompletion:(__kindof SJBaseVideoPlayer *)videoPlayer;
19.18 - (BOOL)canTriggerRotationOfVideoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer;
19.20 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer willRotateView:(BOOL)isFull;
19.21 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer didEndRotation:(BOOL)isFull;
19.22 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer willFitOnScreen:(BOOL)isFitOnScreen;
19.23 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer didCompleteFitOnScreen:(BOOL)isFitOnScreen;
19.24 - (void)horizontalDirectionWillBeginDragging:(__kindof SJBaseVideoPlayer *)videoPlayer;
19.25 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer horizontalDirectionDidMove:(CGFloat)progress;
19.26 - (void)horizontalDirectionDidEndDragging:(__kindof SJBaseVideoPlayer *)videoPlayer;
19.27 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer reachabilityChanged:(SJNetworkStatus)status;
19.28 - (void)tappedPlayerOnTheLockedState:(__kindof SJBaseVideoPlayer *)videoPlayer;
19.29 - (void)lockedVideoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer;
19.30 - (void)unlockedVideoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer;
19.31 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer switchVideoDefinitionByURL:(NSURL *)URL statusDidChange:(SJMediaPlaybackSwitchDefinitionStatus)status;
19.32 - (void)appWillResignActive:(__kindof SJBaseVideoPlayer *)videoPlayer;
19.33 - (void)appDidBecomeActive:(__kindof SJBaseVideoPlayer *)videoPlayer;
19.34 - (void)appWillEnterForeground:(__kindof SJBaseVideoPlayer *)videoPlayer;
19.35 - (void)appDidEnterBackground:(__kindof SJBaseVideoPlayer *)videoPlayer;

___

# 1. 可在以下视图层次中播放
1.1 在普通 View 上播放
1.2 在 TableViewCell 上播放
1.3 在 TableViewHeaderView 上播放
1.4 在 CollectionViewCell 上播放
1.5 CollectionView 嵌套在 TableViewHeaderView 中, 在 CollectionViewCell 上播放
1.6 CollectionView 嵌套在 TableViewCell 中, 在 CollectionViewCell 上播放
1.7 CollectionView 嵌套在 CollectionViewCell 中, 在 CollectionViewCell 上播放
