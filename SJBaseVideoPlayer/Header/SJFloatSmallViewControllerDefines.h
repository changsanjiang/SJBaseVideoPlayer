//
//  SJFloatSmallViewControllerDefines.h
//  Pods
//
//  Created by BlueDancer on 2019/6/6.
//

#ifndef SJFloatSmallViewControllerDefines_h
#define SJFloatSmallViewControllerDefines_h
@protocol SJFloatSmallViewControllerObserverProtocol;
@class SJBaseVideoPlayer;

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol SJFloatSmallViewControllerProtocol 

- (void)floatSmallViewNeedAppear;

- (void)floatSmallViewNeedDisappear;

@property (nonatomic, strong, readonly) UIView *view; ///< 小窗视图, 当需要显示小窗视图时, 播放器将会自动添加到小窗视图中.

- (id<SJFloatSmallViewControllerObserverProtocol>)getObserver;

@property (nonatomic, readonly) BOOL isAppeared;

@property (nonatomic, getter=isDisabled) BOOL disabled; ///< 是否禁止小窗
@end


@protocol SJFloatSmallViewControllerObserverProtocol
@property (nonatomic, copy, nullable) void(^appearStateDidChangeExeBlock)(id<SJFloatSmallViewControllerProtocol> controller);
@property (nonatomic, copy, nullable) void(^disabledControllerExeBlock)(id<SJFloatSmallViewControllerProtocol> controller);
@end
NS_ASSUME_NONNULL_END

#endif /* SJFloatSmallViewControllerDefines_h */
