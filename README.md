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

## 最近更新

* 适配 iOS 13.0.

* v2.6.0 开始 旋转的配置已从播放器内部移出, 现在需开发者自己添加配置, 代码如下: 
```Objective-C
static BOOL _iPhone_shouldAutorotate(UIViewController *vc) {
    NSString *class = NSStringFromClass(vc.class);
    
    // 禁止哪些控制器旋转.
    // - 如果返回 NO, 则只旋转`播放器`.  
    // - 如果返回 YES, 则`所有控制器`同`播放器`一起旋转.
    //
    // return NO;
    
    // - 为了避免控制器同播放器一起旋转, 此处禁止Demo中SJ前缀的控制器旋转.
    if ( [class hasPrefix:@"SJ"] ) {
        return NO;
    }
    
    // 其余情况 return YES. 此时系统的播放器(如在网页播放全屏后)可以触发旋转.  
    return YES;
}

@implementation UIViewController (RotationControl)
/// 该控制器是否可以旋转
- (BOOL)shouldAutorotate {
    // 此处为设置 iPhone 哪些控制器可以旋转
    if ( UIUserInterfaceIdiomPhone == UI_USER_INTERFACE_IDIOM() )
        return _iPhone_shouldAutorotate(self);
    
    return NO;
}

/// 旋转支持的方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    // 此处为设置 iPhone 某个控制器旋转支持的方向
    // - 请根据实际情况进行修改.
    if ( UIUserInterfaceIdiomPhone == UI_USER_INTERFACE_IDIOM() ) {
        // 如果self不支持旋转, 返回仅支持竖屏
        if ( _iPhone_shouldAutorotate(self) == NO )
            return UIInterfaceOrientationMaskPortrait;
    }

    return UIInterfaceOrientationMaskAllButUpsideDown;
}

@end


@implementation UITabBarController (RotationControl)
- (UIViewController *)sj_topViewController {
    if ( self.selectedIndex == NSNotFound )
        return self.viewControllers.firstObject;
    return self.selectedViewController;
}

- (BOOL)shouldAutorotate {
    return [[self sj_topViewController] shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [[self sj_topViewController] supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [[self sj_topViewController] preferredInterfaceOrientationForPresentation];
}
@end

@implementation UINavigationController (RotationControl)
- (BOOL)shouldAutorotate {
    return self.topViewController.shouldAutorotate;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return self.topViewController.supportedInterfaceOrientations;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return self.topViewController.preferredInterfaceOrientationForPresentation;
}

- (nullable UIViewController *)childViewControllerForStatusBarStyle {
    return self.topViewController;
}

- (nullable UIViewController *)childViewControllerForStatusBarHidden {
    return self.topViewController;
}
@end
```

* 新增 切换清晰度的控制层. 开启如下:
```Objective-C
    SJVideoPlayerURLAsset *asset1 = [[SJVideoPlayerURLAsset alloc] initWithURL:VideoURL_Level4];
    asset1.definition_fullName = @"超清 1080P";
    asset1.definition_lastName = @"超清";
    
    SJVideoPlayerURLAsset *asset2 = [[SJVideoPlayerURLAsset alloc] initWithURL:VideoURL_Level3];
    asset2.definition_fullName = @"高清 720P";
    asset2.definition_lastName = @"AAAAAAA";
    
    SJVideoPlayerURLAsset *asset3 = [[SJVideoPlayerURLAsset alloc] initWithURL:VideoURL_Level2];
    asset3.definition_fullName = @"清晰 480P";
    asset3.definition_lastName = @"480P";
    _player.definitionURLAssets = @[asset1, asset2, asset3];
    
    // 先播放asset1. (asset2 和 asset3 将会在用户选择后进行切换)
    _player.URLAsset = asset1;
```

* 新增 左右边缘快进快退. 开启如下:
```Objective-C
    // 开启左右边缘快进快退. 如需进行更多配置, 请查看`fastForwardViewController`
    _player.fastForwardViewController.enabled = YES;
```

* 新增 小浮窗播放. 开启如下:
```Objective-C
    // 开启小浮窗. 如需进行更多配置, 请查看`floatSmallViewController`
    _player.floatSmallViewController.enabled = YES;
```

___

## Documents

#### [1. 视图层次](#1)

* [1.1 UIView](#1.1)
* [1.2 UITableView](#1.2)
    * [1.2.1 UITableViewCell](#1.2.1)
    * [1.2.2 UITableViewHeaderView](#1.2.2)
    * [1.2.3 UITableViewFooterView](#1.2.3)
    * [1.2.4 UITableViewHeaderFooterView](#1.2.4)
* [1.3 UICollectionView](#1.3)
    * [1.3.1 UICollectionViewCell](#1.3.1)
* [1.4  嵌套时的视图层次](#1.4)
    * [1.4.1 UICollectionView 嵌套在 UITableViewCell 中](#1.4.1)
    * [1.4.2 UICollectionView 嵌套在 UITableViewHeaderView 中](#1.4.2)
    * [1.4.3 UICollectionView 嵌套在 UICollectionViewCell 中](#1.4.3)
