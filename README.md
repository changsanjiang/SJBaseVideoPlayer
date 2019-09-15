![readme](https://user-images.githubusercontent.com/37614260/43947531-922a0712-9cb2-11e8-8f8d-4823a21308d3.png)

[![Build Status](https://travis-ci.org/changsanjiang/SJVideoPlayer.svg?branch=master)](https://travis-ci.org/changsanjiang/SJVideoPlayer)
[![Version](https://img.shields.io/cocoapods/v/SJVideoPlayer.svg?style=flat)](https://cocoapods.org/pods/SJVideoPlayer)
[![Platform](https://img.shields.io/badge/platform-iOS-blue.svg)](https://github.com/changsanjiang)
[![License](https://img.shields.io/github/license/changsanjiang/SJVideoPlayer.svg)](https://github.com/changsanjiang/SJVideoPlayer/blob/master/LICENSE.md)

### Installation
```ruby
# Player with default control layer.
pod 'SJVideoPlayer'

# The base player, without the control layer, can be used if you need a custom control layer.
pod 'SJBaseVideoPlayer'

# 天朝
# 如果网络不行安装不了, 可改成以下方式进行安装
pod 'SJBaseVideoPlayer', :git => 'https://gitee.com/changsanjiang/SJBaseVideoPlayer.git'
pod 'SJVideoPlayer', :git => 'https://gitee.com/changsanjiang/SJVideoPlayer.git'
pod 'SJUIKit/AttributesFactory', :git => 'https://gitee.com/changsanjiang/SJUIKit.git'
pod 'SJUIKit/ObserverHelper', :git => 'https://gitee.com/changsanjiang/SJUIKit.git'
pod 'SJUIKit/Queues', :git => 'https://gitee.com/changsanjiang/SJUIKit.git'
$ pod update --no-repo-update   (不要用 pod install 了, 用这个命令安装)
```
- [Base Video Player](https://github.com/changsanjiang/SJBaseVideoPlayer)

___

## Contact
* Email: changsanjiang@gmail.com

___

## License
SJVideoPlayer is available under the MIT license. See the LICENSE file for more info.

___

## Example

```Objective-C
_player = [SJVideoPlayer player];
_player.view.frame = CGRectMake(0, 0, 200, 200);
[self.view addSubview:_player.view];

// 设置资源进行播放
_player.URLAsset = [[SJVideoPlayerURLAsset alloc] initWithURL:URL];

// 修改自动旋转支持的方向
_player.rotationManager.autorotationSupportedOrientations = SJOrientationMaskLandscapeLeft | SJOrientationMaskPortrait;

// 修改支持的手势类型
_player.gestureControl.supportedGestureTypes = SJPlayerGestureTypeMask_SingleTap | SJPlayerGestureTypeMask_DoubleTap;

// 开启左右边缘双击快进快退
_player.fastForwardViewController.enabled = YES;

// 开启小浮窗模式
_player.floatSmallViewController.enabled = YES;

... 等等, 更多设置, 请查看头文件. 相应功能均为懒加载, 用到时才会创建. 
```

___

## Documents

#### [1. 视图层次结构](#1)

* [1.1 UIView](#1.1)
* [1.2 UITableView 中的层次结构](#1.2)
    * [1.2.1 UITableViewCell](#1.2.1)
    * [1.2.2 UITableView.tableHeaderView](#1.2.2)
    * [1.2.3 UITableView.tableFooterView](#1.2.3)
    * [1.2.4 UITableViewHeaderFooterView](#1.2.4)
* [1.3 UICollectionView 中的层次结构](#1.3)
    * [1.3.1 UICollectionViewCell](#1.3.1)
* [1.4  嵌套时的层次结构](#1.4)
    * [1.4.1 UICollectionView 嵌套在 UITableViewCell 中](#1.4.1)
    * [1.4.2 UICollectionView 嵌套在 UITableViewHeaderView 中](#1.4.2)
    * [1.4.3 UICollectionView 嵌套在 UICollectionViewCell 中](#1.4.3)

<p>

由于 UITableView 及 UICollectionView 的复用机制, 会导致播放器视图显示在错误的位置上, 通过指定视图层次结构, 使得播放器能够定位具体的父视图, 依此来控制隐藏与显示. 

</p>

___

#### [2. URLAsset](#2)

* [2.1 播放 URL(本地文件或远程资源)](#2.1)
* [2.2 播放 AVAsset 或其子类](#2.2)
* [2.3 从指定的位置开始播放](#2.3)
* [2.4 续播(进入下个页面时, 继续播放)](#2.4)
* [2.5 销毁时的回调. 可在此做一些记录工作, 如播放记录](#2.5)

<p>

播放器 播放的资源是通过 SJVideoPlayerURLAsset 进行创建的. 默认情况下, 创建了 SJVideoPlayerURLAsset , 赋值给播放器后即可播放.  

```Objective-C
SJVideoPlayerURLAsset *asset = [[SJVideoPlayerURLAsset alloc] initWithURL:URL];
_player.URLAsset = asset;
```

</p>

___


## 以下为详细介绍: 


<h3 id="1.1">1.1 UIView</h3>  

```Objective-C
_player = [SJVideoPlayer player];
_player.view.frame = ...;
[self.view addSubview:_player.view];

// 设置资源进行播放
SJVideoPlayerURLAsset *asset = [[SJVideoPlayerURLAsset alloc] initWithURL:URL];
_player.URLAsset = asset;
```

<p>

在普通视图中播放时, 不需要指定视图层次, 直接创建资源进行播放即可.  

</p>

___

<h3 id="1.2">1.2 UITableView 中的层次结构</h3>

<p>

在 UITableView 中播放时, 需指定视图层次, 使得播放器能够定位具体的父视图, 依此来控制隐藏与显示.

</p>

___


<h3 id="1.2.1">1.2.1 UITableViewCell</h3>

```Objective-C
--  UITableView
    --  UITableViewCell
        --  Player.superview
            --  Player.view


_player = [SJVideoPlayer player];

UIView *playerSuperview = cell.coverImageView;
SJPlayModel *playModel = [SJPlayModel UITableViewCellPlayModelWithPlayerSuperviewTag:playerSuperview.tag atIndexPath:indexPath tableView:self.tableView];

_player.URLAsset = [[SJVideoPlayerURLAsset alloc] initWithURL:URL playModel:playModel];
```

<p>

在 UITableViewCell 中播放时, 需指定 Cell 所处的 indexPath 以及播放器父视图的 tag. 

在滑动时, 管理类将会通过这两个参数控制播放器父视图的显示与隐藏.

</p>

___


<h3 id="1.2.2">1.2.2 UITableView.tableHeaderView</h3>

```Objective-C
--  UITableView
    --  UITableView.tableHeaderView 或者 UITableView.tableFooterView  
        --  Player.superview
            --  Player.view

UIView *playerSuperview = self.tableView.tableHeaderView;
// 也可以设置子视图
// playerSuperview = self.tableView.tableHeaderView.coverImageView;
SJPlayModel *playModel = [SJPlayModel UITableViewHeaderViewPlayModelWithPlayerSuperview:playerSuperview tableView:self.tableView];
```

___


<h3 id="1.2.3">1.2.3 UITableView.tableFooterView</h3>

```Objective-C
--  UITableView
    --  UITableView.tableHeaderView 或者 UITableView.tableFooterView  
        --  Player.superview
            --  Player.view

UIView *playerSuperview = self.tableView.tableFooterView;
// 也可以设置子视图
// playerSuperview = self.tableView.tableFooterView.coverImageView;
SJPlayModel *playModel = [SJPlayModel UITableViewHeaderViewPlayModelWithPlayerSuperview:playerSuperview tableView:self.tableView];
```

___


<h3 id="1.2.4">1.2.4 UITableViewHeaderFooterView</h3>

```Objective-C
--  UITableView
    --  UITableViewHeaderFooterView 
        --  Player.superview
            --  Player.view            

/// isHeader: 当在header中播放时, 传YES, 在footer时, 传NO.
SJPlayModel *playModel = [SJPlayModel UITableViewHeaderFooterViewPlayModelWithPlayerSuperviewTag:sectionHeaderView.coverImageView.tag inSection:section isHeader:YES tableView:self.tableView];
```

___


<h3 id="1.3">1.3 UICollectionView 中的层次结构</h3>

<p>

在 UICollectionView 中播放时, 同 [UITableView](#1.2) 中一样, 需指定视图层次, 使得播放器能够定位具体的父视图, 依此来控制隐藏与显示.

</p>

___


<h3 id="1.3.1">1.3.1 UICollectionViewCell</h3>

```Objective-C
--  UICollectionView
    --  UICollectionViewCell
        --  Player.superview
            --  Player.view

SJPlayModel *playModel = [SJPlayModel UICollectionViewCellPlayModelWithPlayerSuperviewTag:cell.coverImageView.tag atIndexPath:indexPath collectionView:self.collectionView];
```

___


<h3 id="1.4">1.4 嵌套时的视图层次</h3>

<p>

嵌套的情况下, 传递的参数比较多, 不过熟悉了前面的套路, 下面的这些也不成问题.  (会被复用的视图, 传 tag. 如果不会被复用, 则直接传视图)

</p>

___


<h3 id="1.4.1">1.4.1 UICollectionView 嵌套在 UITableViewCell 中</h3>

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


<h3 id="1.4.2">1.4.2 UICollectionView 嵌套在 UITableViewHeaderView 中</h3>

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


<h3 id="1.4.3">1.4.3 UICollectionView 嵌套在 UICollectionViewCell 中</h3>

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


<h3 id="2">2. URLAsset</h3>

<p>

播放器 播放的资源是通过 SJVideoPlayerURLAsset 创建的. SJVideoPlayerURLAsset 由两部分组成:

视图层次 (第一部分中的SJPlayModel)
资源地址 (可以是本地资源/URL/AVAsset)

默认情况下, 创建了 SJVideoPlayerURLAsset , 赋值给播放器后即可播放.

</p>

___

<h3 id="2.1">2.1 播放 URL(本地文件或远程资源)</h3>

```Objective-C
NSURL *URL = [NSURL URLWithString:@"https://...example.mp4"];
_player.URLAsset = [[SJVideoPlayerURLAsset alloc] initWithURL:URL];
```

<h3 id="2.2">2.2 播放 AVAsset 或其子类</h3>

```Objective-C
_player.URLAsset = [[SJVideoPlayerURLAsset alloc] initWithAVAsset:avAsset];
```

<h3 id="2.3">2.3 从指定的位置开始播放</h3>

```Objective-C
NSTimeInterval secs = 20.0;
_player.URLAsset = [[SJVideoPlayerURLAsset alloc] initWithURL:URL specifyStartTime:secs]; // 直接从20秒处开始播放
```

<h3 id="2.4">2.4 续播(进入下个页面时, 继续播放)</h3>

<p>

我们可能需要切换界面时, 希望视频能够在下一个界面无缝的进行播放. 使用如下方法, 传入正在播放的资源, 将新的资源赋值给播放器播放即可. 

</p>

```Objective-C
// otherAsset 即为上一个页面播放的Asset
// 除了需要一个otherAsset, 其他方面同以上的示例一模一样
_player.URLAsset = [SJVideoPlayerURLAsset.alloc initWithOtherAsset:otherAsset]; 
```

<h3 id="2.5">2.5 销毁时的回调. 可在此做一些记录工作, 如播放记录</h3>

```Objective-C
// 每个资源dealloc时的回调
_player.assetDeallocExeBlock = ^(__kindof SJBaseVideoPlayer * _Nonnull videoPlayer) {
    // .....
};
```

当资源销毁时, 播放器将会回调该 block. 

___

