//
//  UIViewController+SJRotationPrivate_FixSafeArea.h
//  Pods
//
//  Created by BlueDancer on 2019/8/6.
//

#import <UIKit/UIKit.h>

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000

NS_ASSUME_NONNULL_BEGIN
/// 适配 iOS 13.0
@interface UIViewController (SJRotationPrivate_FixSafeArea)

@end
NS_ASSUME_NONNULL_END

#endif
