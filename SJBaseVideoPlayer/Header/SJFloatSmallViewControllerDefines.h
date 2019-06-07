//
//  SJFloatSmallViewControllerDefines.h
//  Pods
//
//  Created by BlueDancer on 2019/6/6.
//

#ifndef SJFloatSmallViewControllerDefines_h
#define SJFloatSmallViewControllerDefines_h
@protocol SJFloatSmallViewControllerObserverProtocol;
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol SJFloatSmallViewControllerProtocol
- (id<SJFloatSmallViewControllerObserverProtocol>)getObserver;

/// 是否开启小浮窗, 注意: 默认为 不开启
///
/// - default value is NO.
@property (nonatomic, getter=isEnabled) BOOL enabled;

/// 该block将会在`showFloatSmallView`时被调用
///
/// - 如果返回NO, 将不显示小浮窗.
@property (nonatomic, copy, nullable) BOOL(^floatSmallViewShouldAppear)(id<SJFloatSmallViewControllerProtocol> controller);

/// 小浮窗视图是否已显示
///
/// - default value is NO.
@property (nonatomic, readonly) BOOL isAppeared;

/// 显示小浮窗视图
///
/// - 只有`floatSmallViewShouldAppear`返回YES, 小浮窗才会显示.
- (void)showFloatSmallView;

/// 隐藏小浮窗视图
///
/// - 调用该方法将会立刻隐藏小浮窗视图.
- (void)dismissFloatSmallView;

@property (nonatomic, strong, readonly) UIView *view;

@property (nonatomic) CGFloat safeMargin; ///< default value is 12.

/// 以下属性由播放器维护
///
/// - target 为播放器呈现视图
/// - targetSuperview 为播放器视图
/// 当显示小浮窗时, 可以将target添加到小浮窗中
/// 当隐藏小浮窗时, 可以将target恢复到targetSuperview中
@property (nonatomic, weak, nullable) UIView *target;
@property (nonatomic, weak, nullable) UIView *targetSuperview;
@end


@protocol SJFloatSmallViewControllerObserverProtocol
@property (nonatomic, weak, readonly, nullable) id<SJFloatSmallViewControllerProtocol> controller;

@property (nonatomic, copy, nullable) void(^appearStateDidChangeExeBlock)(id<SJFloatSmallViewControllerProtocol> controller);
@property (nonatomic, copy, nullable) void(^enabledControllerExeBlock)(id<SJFloatSmallViewControllerProtocol> controller);
@end
NS_ASSUME_NONNULL_END

#endif /* SJFloatSmallViewControllerDefines_h */
