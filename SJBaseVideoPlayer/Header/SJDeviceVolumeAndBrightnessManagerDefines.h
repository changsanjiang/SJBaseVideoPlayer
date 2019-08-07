//
//  SJDeviceVolumeAndBrightnessManagerProtocol.h
//  Pods
//
//  Created by 畅三江 on 2019/1/5.
//

#ifndef SJDeviceVolumeAndBrightnessManagerProtocol_h
#define SJDeviceVolumeAndBrightnessManagerProtocol_h
#import <UIKit/UIKit.h>
@protocol SJDeviceVolumeAndBrightnessManagerObserver;

NS_ASSUME_NONNULL_BEGIN
@protocol SJDeviceVolumeAndBrightnessManager
- (id<SJDeviceVolumeAndBrightnessManagerObserver>)getObserver;
@property (nonatomic) float volume; // device volume
@property (nonatomic) float brightness; // device brightness

/// 以下属性由播放器自动维护
///
/// - target 为播放器呈现视图, 将来可以将自定义的调整音量或亮度视图添加到此视图中
@property (nonatomic, weak, nullable) UIView *targetView;
@property (nonatomic, getter=isVolumeTracking) BOOL volumeTracking;
@property (nonatomic, getter=isBrightnessTracking) BOOL brightnessTracking;
- (void)targetViewWillMoveToWindow:(nullable UIWindow *)newWindow;
@end


@protocol SJDeviceVolumeAndBrightnessManagerObserver
@property (nonatomic, copy, nullable) void(^volumeDidChangeExeBlock)(id<SJDeviceVolumeAndBrightnessManager> mgr, float volume);
@property (nonatomic, copy, nullable) void(^brightnessDidChangeExeBlock)(id<SJDeviceVolumeAndBrightnessManager> mgr, float brightness);
@end
NS_ASSUME_NONNULL_END

#endif /* SJDeviceVolumeAndBrightnessManagerProtocol_h */
