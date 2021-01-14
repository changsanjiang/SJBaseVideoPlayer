//
//  SJFloatSmallViewController.h
//  Pods
//
//  Created by 畅三江 on 2019/6/6.
//

#import <UIKit/UIKit.h>
#import "SJFloatSmallViewControllerDefines.h"

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, SJFloatViewLayoutPosition) {
    SJFloatViewLayoutPositionTopLeft,
    SJFloatViewLayoutPositionTopRight,
    SJFloatViewLayoutPositionBottomLeft,
    SJFloatViewLayoutPositionBottomRight,
};

@interface SJFloatSmallViewController : NSObject<SJFloatSmallViewController>
/// default value is SJFloatViewLayoutPositionBottomRight.
@property (nonatomic) SJFloatViewLayoutPosition layoutPosition;
/// default value is UIEdgeInsetsMake(20, 12, 20, 12).
@property (nonatomic) UIEdgeInsets layoutInsets;
@property (nonatomic) CGSize layoutSize;
@property (nonatomic) BOOL ignoreSafeAreaInsets API_AVAILABLE(ios(11.0));
/// 是否将小浮窗添加到window中. (注意: 小浮窗默认会添加到播放器同级的控制器视图上)
///
/// - default value is NO.
@property (nonatomic) BOOL addFloatViewToKeyWindow;
@end
NS_ASSUME_NONNULL_END
