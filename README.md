# SJBaseVideoPlayer

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

#### [1 视图层次](#1)
* [1.1 在普通 View 上播放](#1.1)
* [1.2 在 TableViewCell 上播放](#1.2)
* [1.3 在 TableHeaderView 或者 TableFooterView  上播放](#1.3)
* [1.4 在 CollectionViewCell 上播放](#1.4)
* [1.5 CollectionView 嵌套在 TableViewHeaderView 中, 在 CollectionViewCell 上播放](#1.5)
* [1.6 CollectionView 嵌套在 TableViewCell 中, 在 CollectionViewCell 上播放](#1.6)
* [1.7 CollectionView 嵌套在 CollectionViewCell 中, 在 CollectionViewCell 上播放](#1.7)
* [1.8 在 UITableViewHeaderFooterView 上播放](#1.8)

#### [2. 创建资源进行播放](#2)
* [2.1 通过 URL 创建资源进行播放](#2.1)
* [2.2 通过 AVAsset 或其子类进行播放](#2.2)
* [2.3 指定开始播放的时间](#2.3)
* [2.4 续播. 进入下个页面时, 继续播放](#2.4)
* [2.5 销毁时的回调. 可在此时做一些记录工作, 如播放位置](#2.5)

#### 3. 播放控制
* [3.1 当前时间和时长](#3.1)
* [3.2 时间改变时的回调](#3.2)
* [3.3 播放结束后的回调](#3.3)
* [3.4 播放状态 - 未知/准备/准备就绪/播放中/暂停的/不活跃的](#3.4)
* [3.5 暂停的原因 - 缓冲/跳转/暂停](#3.5)
* [3.6 不活跃的原因 - 加载失败/播放完毕](#3.6)
* [3.7 播放状态改变的回调](#3.7)
* [3.8 是否自动播放 - 当资源初始化完成后](#3.8)
* [3.9 刷新 ](#3.9)
* [3.10 播放器的声音设置 & 静音](#3.1)
* [3.11 播放](#3.1)
* [3.12 暂停](#3.1)
* [3.13 是否暂停 - 当App进入后台后](#3.1)
* [3.14 停止播放](#3.1)
* [3.15 重播](#3.1)
* [3.16 跳转到指定的时间播放](#3.1)
* [3.17 调速 & 速率改变时的回调](#3.1)
* [3.18 自己动手撸一个 SJMediaPlaybackController 或接入别的视频 SDK, 替换作者原始实现](#3.1)

#### 4. 控制层的显示和隐藏
* [4.1 让控制层显示](#4.1)
* [4.2 让控制层隐藏](#4.2)
* [4.3 控制层是否显示中](#4.3)
* [4.4 是否在暂停时保持控制层显示](#4.4)
* [4.5 是否自动显示控制层 - 资源初始化完成后](#4.5)
* [4.6 控制层显示状态改变的回调](#4.6)
* [4.7 禁止管理控制层的显示和隐藏](#4.7)
* [4.8 自己动手撸一个 SJControlLayerAppearManager, 替换作者原始实现](#4.8)

#### 5. 设备亮度和音量
* [5.1 调整设备亮度](#5.1)
* [5.2 调整设备声音](#5.2)
* [5.3 亮度 & 声音改变后的回调](#5.3)
* [5.3 自己动手撸一个 SJDeviceVolumeAndBrightnessManager, 替换作者原始实现](#5.3)

#### 6. 旋转<br/>
* [6.1 自动旋转](#6.1)
* [6.2 设置自动旋转支持的方向](#6.2)
* [6.3 禁止自动旋转](#6.3)
* [6.4 主动调用旋转](#6.4)
* [6.5 是否全屏](#6.5)
* [6.6 是否正在旋转](#6.6)
* [6.7 当前旋转的方向 ](#6.7)
* [6.8 旋转开始和结束的回调](#6.8)
* [6.9 使 ViewController 一起旋转](#6.9)
* [6.10 自己动手撸一个 SJRotationManager, 替换作者原始实现](#6.1)

#### 7. 直接全屏而不旋转
* [7.1 全屏和恢复](#7.1)
* [7.2 开始和结束的回调](#7.2)
* [7.3 是否是全屏](#7.3)
* [7.4 自己动手撸一个 SJFitOnScreenManager, 替换作者原始实现](#7.4)

#### 8. 镜像翻转
* [8.1 翻转和恢复](#8.1)
* [8.2 开始和结束的回调](#8.2)
* [8.3  自己动手撸一个 SJFlipTransitionManager, 替换作者原始实现](#8.3)

#### 9. 网络状态
* [9.1 当前的网络状态](#9.1)
* [9.2 网络状态改变的回调](#9.2)
* [9.3 自己动手撸一个 SJReachability, 替换作者原始实现](#9.3)

#### 10. 手势
* [10.1 单击手势](#10.1)
* [10.2 双击手势](#10.2)
* [10.3 移动手势](#10.3)
* [10.4 捏合手势](#10.4)
* [10.5 禁止某些手势](#10.5)
* [10.6 自定义某个手势的处理](#10.6)
* [10.7 自己动手撸一个 SJPlayerGestureControl, 替换作者原始实现](#10.7)

#### 11. 占位图
* [11.1 设置本地占位图](#11.1)
* [11.2 设置网络占位图](#11.2)

#### 12. 显示提示文本
* [12.1 显示文本及持续时间 - (NSString or NSAttributedString)](#12.1)
* [12.2 配置提示文本](#12.2)

#### 13. 一些固定代码
* [13.1 - (void)vc_viewDidAppear; ](#13.1)
* [13.2 - (void)vc_viewWillDisappear;](#13.2)
* [13.3 - (void)vc_viewDidDisappear;](#13.3)
* [13.4 - (BOOL)vc_prefersStatusBarHidden;](#13.4)
* [13.5 - (UIStatusBarStyle)vc_preferredStatusBarStyle;](#13.5)
* [13.6 - 临时显示状态栏](#13.6)
* [13.7 - 临时隐藏状态栏](#13.7)

#### 14. 截屏
* [14.1 当前时间截图](#14.1)
* [14.2 指定时间截图](#14.2)
* [14.3 生成预览视图, 大约20张](#14.3)

#### 15. 导出视频或GIF
* [15.1 导出视频](#15.1)
* [15.2 导出GIF](#15.2)
* [15.3 取消操作](#15.3)

#### 16. 滚动相关
* [16.1 是否在 UICollectionView 或者 UITableView 中播放](#16.1)
* [16.2 是否滚动显示](#16.2)
* [16.3 播放器视图将要滚动显示和消失的回调](#16.3)

#### 17. 自动播放 - 在 UICollectionView 或者 UITableView 中
* [17.1 开启](#17.1)
* [17.2 配置](#17.2)
* [17.3 关闭](#17.3)
* [17.4 主动调用播放下一个资源](#17.4)

#### 18. 控制层数据源, 每个方法介绍
* [18.1 - (UIView *)controlView;](#18.1)
* [18.2 - (BOOL)controlLayerDisappearCondition;](#18.2)
* [18.3 - (BOOL)triggerGesturesCondition:(CGPoint)location;](#18.3)
* [18.4 - (void)installedControlViewToVideoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer;](#18.4)

#### 19. 控制层代理, 每个方法介绍
* [19.1 - (void)controlLayerNeedAppear:(__kindof SJBaseVideoPlayer *)videoPlayer;](#19.1)
* [19.2 - (void)controlLayerNeedDisappear:(__kindof SJBaseVideoPlayer *)videoPlayer;](#19.2)
* [19.3 - (void)videoPlayerWillAppearInScrollView:(__kindof SJBaseVideoPlayer *)videoPlayer;](#19.3)
* [19.4 - (void)videoPlayerWillDisappearInScrollView:(__kindof SJBaseVideoPlayer *)videoPlayer;](#19.4)
* [19.5 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer prepareToPlay:(SJVideoPlayerURLAsset *)asset;](#19.5)
* [19.6 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer statusDidChanged:(SJVideoPlayerPlayStatus)status;](#19.6)
* [19.7 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer](#19.7)
currentTime:(NSTimeInterval)currentTime currentTimeStr:(NSString *)currentTimeStr<br/>
totalTime:(NSTimeInterval)totalTime totalTimeStr:(NSString *)totalTimeStr;<br/>
* [19.8 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer presentationSize:(CGSize)size;](#19.8)
* [19.9 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer muteChanged:(BOOL)mute;](#19.9)
* [19.11 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer volumeChanged:(float)volume;](#19.11)
* [19.12 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer brightnessChanged:(float)brightness;](#19.12)
* [19.13 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer rateChanged:(float)rate;](#19.13)
* [19.14 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer loadedTimeProgress:(float)progress;](#19.14)
* [19.15 - (void)startLoading:(__kindof SJBaseVideoPlayer *)videoPlayer;](#19.15)
* [19.16 - (void)cancelLoading:(__kindof SJBaseVideoPlayer *)videoPlayer;](#19.16)
* [19.17 - (void)loadCompletion:(__kindof SJBaseVideoPlayer *)videoPlayer;](#19.17)
* [19.18 - (BOOL)canTriggerRotationOfVideoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer;](#19.18)
* [19.20 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer willRotateView:(BOOL)isFull;](#19.20)
* [19.21 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer didEndRotation:(BOOL)isFull;](#19.21)
* [19.22 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer willFitOnScreen:(BOOL)isFitOnScreen;](#19.22)
* [19.23 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer didCompleteFitOnScreen:(BOOL)isFitOnScreen;](#19.23)
* [19.24 - (void)horizontalDirectionWillBeginDragging:(__kindof SJBaseVideoPlayer *)videoPlayer;](#19.24)
* [19.25 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer horizontalDirectionDidMove:(CGFloat)progress;](#19.25)
* [19.26 - (void)horizontalDirectionDidEndDragging:(__kindof SJBaseVideoPlayer *)videoPlayer;](#19.26)
* [19.27 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer reachabilityChanged:(SJNetworkStatus)status;](#19.27)
* [19.28 - (void)tappedPlayerOnTheLockedState:(__kindof SJBaseVideoPlayer *)videoPlayer;](#19.28)
* [19.29 - (void)lockedVideoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer;](#19.29)
* [19.30 - (void)unlockedVideoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer;](#19.30)
* [19.31 - (void)videoPlayer:(__kindof SJBaseVideoPlayer *)videoPlayer switchVideoDefinitionByURL:(NSURL *)URL statusDidChange:(SJMediaPlaybackSwitchDefinitionStatus)status;](#19.31)
* [19.32 - (void)appWillResignActive:(__kindof SJBaseVideoPlayer *)videoPlayer;](#19.32)
* [19.33 - (void)appDidBecomeActive:(__kindof SJBaseVideoPlayer *)videoPlayer;](#19.33)
* [19.34 - (void)appWillEnterForeground:(__kindof SJBaseVideoPlayer *)videoPlayer;](#19.34)
* [19.35 - (void)appDidEnterBackground:(__kindof SJBaseVideoPlayer *)videoPlayer;](#19.35)

___

<h2 id="1">1. 视图层次</h2>
我将以下视图层次封装进了 SJPlayModel 中, 使用它初始化对应层次即可. 

___

<h3 id="1.1">1.1 在普通 View 上播放</h3>

在普通视图中播放时, 直接创建PlayModel即可.

```Objective-C
SJPlayModel *playModel = [SJPlayModel new];
```

___

<h3 id="1.2">1.2 在 TableViewCell 上播放</h3>

```Objective-C
--  UITableView
    --  UITableViewCell
        --  Player.superview
            --  Player.view
            
SJPlayModel *playModel = [SJPlayModel UITableViewCellPlayModelWithPlayerSuperviewTag:cell.coverImageView.tag atIndexPath:indexPath tableView:self.tableView];
```

___

<h3 id="1.3">1.3 在 TableHeaderView 或者 TableFooterView  上播放</h3>

```Objective-C
--  UITableView
    --  UITableView.tableHeaderView 或者 UITableView.tableFooterView  
        --  Player.superview
            --  Player.view

SJPlayModel *playModel = [SJPlayModel UITableViewHeaderViewPlayModelWithPlayerSuperview:view.coverImageView tableView:self.tableView];
```

___

<h3 id="1.4">1.4 在 CollectionViewCell 上播放</h3>

```Objective-C
--  UICollectionView
    --  UICollectionViewCell
        --  Player.superview
            --  Player.view

SJPlayModel *playModel = [SJPlayModel UICollectionViewCellPlayModelWithPlayerSuperviewTag:cell.coverImageView.tag atIndexPath:indexPath collectionView:self.collectionView];
```

___

<h3 id="1.5">1.5 CollectionView 嵌套在 TableViewHeaderView 中, 在 CollectionViewCell 上播放</h3>

```Objective-C
--  UITableView
    --  UITableView.tableHeaderView 或者 UITableView.tableFooterView  
        --  tableHeaderView.UICollectionView
            --  UICollectionViewCell
                --  Player.superview
                    --  Player.view

SJPlayModel *playModel = [SJPlayModel UICollectionViewNestedInUITableViewHeaderViewPlayModelWithPlayerSuperviewTag:cell.coverImageView.tag atIndexPath:indexPath collectionView:tableHeaderView.collectionView tableView:self.tableView];
```

___

<h3 id="1.6">1.6 CollectionView 嵌套在 TableViewCell 中, 在 CollectionViewCell 上播放</h3>

```Objective-C
--  UITableView
    --  UITableViewCell
        --  UITableViewCell.UICollectionView
            --  UICollectionViewCell
                --  Player.superview
                    --  Player.view

SJPlayModel *playModel = [SJPlayModel UICollectionViewNestedInUITableViewCellPlayModelWithPlayerSuperviewTag:collectionViewCell.coverImageView.tag atIndexPath:collectionViewCellAtIndexPath collectionViewTag:tableViewCell.collectionView.tag collectionViewAtIndexPath:tableViewCellAtIndexPath tableView:self.tableView];
```

___

<h3 id="1.7">1.7 CollectionView 嵌套在 CollectionViewCell 中, 在 CollectionViewCell 上播放</h3>

```Objective-C
--  UICollectionView
    --  UICollectionViewCell
        --  UICollectionViewCell.UICollectionView
            --  UICollectionViewCell
                --  Player.superview
                    --  Player.view

SJPlayModel *playModel = [SJPlayModel UICollectionViewNestedInUICollectionViewCellPlayModelWithPlayerSuperviewTag:collectionViewCell.coverImageView.tag atIndexPath:collectionViewCellAtIndexPath collectionViewTag:rootCollectionViewCell.collectionView.tag collectionViewAtIndexPath:collectionViewAtIndexPath rootCollectionView:self.collectionView];
```

___

<h3 id="1.8">1.8 在 UITableViewHeaderFooterView 上播放</h3>

```Objective-C
--  UITableView
    --  UITableViewHeaderFooterView 
        --  Player.superview
            --  Player.view            

/// isHeader: 当在header中播放时, 传YES, 在footer时, 传NO.
SJPlayModel *playModel = [SJPlayModel UITableViewHeaderFooterViewPlayModelWithPlayerSuperviewTag:sectionHeaderView.coverImageView.tag inSection:section isHeader:YES tableView:self.tableView];
```

___

<h2 id="2">2. 创建资源进行播放</h2>
<p>
SJBaseVideoPlayer 播放的视频资源是通过 SJVideoPlayerURLAsset 进行初始化的.  SJVideoPlayerURLAsset 由两部分组成: 

- 资源地址 (可以是本地资源/远程URL/AVAsset)
- 视图层次 (第一部分中的SJPlayModel)

默认情况下, 创建了 SJVideoPlayerURLAsset , 赋值给播放器后即可播放. 如下示例:
</p>

```Objective-C
SJVideoPlayerURLAsset *asset = [[SJVideoPlayerURLAsset alloc] initWithURL:URL playModel:playModel];
_player.URLAsset = asset;
```

<h3 id="2.1">2.1 通过 URL 创建资源进行播放</h3>

```Objective-C
_player.URLAsset = [[SJVideoPlayerURLAsset alloc] initWithURL:URL playModel:playModel];
```

<h3 id="2.2">2.2 通过 AVAsset 或其子类进行播放</h3>

```Objective-C
_player.URLAsset = [[SJVideoPlayerURLAsset alloc] initWithAVAsset:avAsset playModel:playModel];
```

<h3 id="2.3">2.3 指定开始播放的时间</h3>

```Objective-C
_player.URLAsset = [[SJVideoPlayerURLAsset alloc] initWithURL:URL playModel:playModel];
_player.URLAsset.specifyStartTime = 25.0; // unit is seconds
```

<h3 id="2.4">2.4 续播. 进入下个页面时, 继续播放</h3>

<p>
在播放时, 我们可能需要切换界面, 而希望视频能够在下一个界面无缝的进行播放. 针对此种情况 SJVideoPlayerURLAsset 提供了便利的初始化方法. 请看片段:
</p>

```Objective-C
/// otherAsset即为上一个页面播放的Asset
/// 除了需要一个otherAsset, 其他方面同以上的示例一模一样
_player.URLAsset = [SJVideoPlayerURLAsset initWithOtherAsset:otherAsset playModel:playModel]; 
```

<h3 id="2.5">2.5 销毁时的回调. 可在此时做一些记录工作, 如播放位置</h3>

<p>
我们有时候想存储某个视频的播放记录, 以便下次, 能够从指定的位置进行播放. 那什么时候存储合适呢? 最好的时机就是资源被释放时. SJBaseVideoPlayer 提供了每个资源在 Dealloc 时的回调, 如下:
</p>

```Objective-C
// 每个资源dealloc时的回调
_player.assetDeallocExeBlock = ^(__kindof SJBaseVideoPlayer * _Nonnull videoPlayer) {
    // .....
};
```

<h2 id="3">3. 播放控制</h2>

<p>
播放控制: 对播放进行的操作. 此部分的内容由 id<SJMediaPlaybackController> playbackController 提供支持.
大多数对播放进行的操作, 均在协议 SJMediaPlaybackController 进行了声明. 正常来说实现了此协议的任何对象, 均可赋值给 player.playbackController 来替换原始实现.
</p>

<h3 id="3.1">3.1 当前时间和时长</h3>

```Objective-C
/// 当前时间
_player.currentTime

/// 时长
_player.totalTime

/// 字符串化, 
/// - 格式为 00:00(小于 1 小时) 或者 00:00:00 (大于 1 小时)
_player.currentTimeStr
_player.totalTimeStr
```

<h3 id="3.2">3.2 时间改变时的回调</h3>

```Objective-C
_player.playTimeDidChangeExeBlok = ^(__kindof SJBaseVideoPlayer * _Nonnull videoPlayer) {
    /// ...
};
```

<h3 id="3.3">3.3 播放结束后的回调</h3>

```Objective-C
_player.playDidToEndExeBlock = ^(__kindof SJBaseVideoPlayer * _Nonnull videoPlayer) {
    /// ...
};
```

<h3 id="3.4">3.4 播放状态 - 未知/准备/准备就绪/播放中/暂停的/不活跃的</h3>

<p>
播放状态有两个状态需要注意一下, 分别是 暂停和不活跃状态

当状态为暂停时, 目前有3种可能: 

- 正在缓冲
- 主动暂停
- 正在跳转

当状态为不活跃时, 目前有2种可能:

- 播放完毕
- 播放失败

</p>

```Objective-C
/**
 当前播放的状态

 - SJVideoPlayerPlayStatusUnknown:      未播放任何资源时的状态
 - SJVideoPlayerPlayStatusPrepare:      准备播放一个资源
 - SJVideoPlayerPlayStatusReadyToPlay:  准备就绪, 可以播放
 - SJVideoPlayerPlayStatusPlaying:      播放中
 - SJVideoPlayerPlayStatusPaused:       暂停状态, 请通过`SJVideoPlayerPausedReason`, 查看暂停原因
 - SJVideoPlayerPlayStatusInactivity:   不活跃状态, 请通过`SJVideoPlayerInactivityReason`, 查看暂停原因
 */
typedef NS_ENUM(NSUInteger, SJVideoPlayerPlayStatus) {
    SJVideoPlayerPlayStatusUnknown,
    SJVideoPlayerPlayStatusPrepare,
    SJVideoPlayerPlayStatusReadyToPlay,
    SJVideoPlayerPlayStatusPlaying,
    SJVideoPlayerPlayStatusPaused,
    SJVideoPlayerPlayStatusInactivity,
};
```

* [3.5 暂停的原因 - 缓冲/跳转/暂停](#3.5)
* [3.6 不活跃的原因 - 加载失败/播放完毕](#3.6)
* [3.7 播放状态改变的回调](#3.7)
* [3.8 是否自动播放 - 当资源初始化完成后](#3.8)
* [3.9 刷新 ](#3.9)
* [3.10 播放器的声音设置 & 静音](#3.1)
* [3.11 播放](#3.1)
* [3.12 暂停](#3.1)
* [3.13 是否暂停 - 当App进入后台后](#3.1)
* [3.14 停止播放](#3.1)
* [3.15 重播](#3.1)
* [3.16 跳转到指定的时间播放](#3.1)
* [3.17 调速 & 速率改变时的回调](#3.1)
* [3.18 自己动手撸一个 SJMediaPlaybackController 或接入别的视频 SDK, 替换作者原始实现](#3.1)
