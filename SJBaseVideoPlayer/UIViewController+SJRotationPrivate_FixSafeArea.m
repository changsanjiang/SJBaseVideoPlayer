//
//  UIViewController+SJRotationPrivate_FixSafeArea.m
//  Pods
//
//  Created by BlueDancer on 2019/8/6.
//

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000

#import "UIViewController+SJRotationPrivate_FixSafeArea.h"
#import "SJBaseVideoPlayer.h"
#import "SJBaseVideoPlayerConst.h"
#import <objc/message.h>

NS_ASSUME_NONNULL_BEGIN
@protocol _UIViewControllerPrivateMethodsProtocol <NSObject>
- (void)_setContentOverlayInsets:(UIEdgeInsets)insets andLeftMargin:(CGFloat)leftMargin rightMargin:(CGFloat)rightMargin;
@end

@implementation UIViewController (SJRotationPrivate_FixSafeArea)
- (BOOL)sj_containsPlayerView {
    return [self.view viewWithTag:SJBaseVideoPlayerViewTag] != nil;
}

- (void)sj_setContentOverlayInsets:(UIEdgeInsets)insets andLeftMargin:(CGFloat)leftMargin rightMargin:(CGFloat)rightMargin {
    if ( insets.top != 0 || [self sj_containsPlayerView] == NO ) {
        [self sj_setContentOverlayInsets:insets andLeftMargin:leftMargin rightMargin:rightMargin];
    }
}
@end


#pragma mark -

@implementation SJBaseVideoPlayer (SJRotationPrivate_FixSafeArea)
+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = UIViewController.class;
        SEL originalSelector = @selector(_setContentOverlayInsets:andLeftMargin:rightMargin:);
        SEL swizzledSelector = @selector(sj_setContentOverlayInsets:andLeftMargin:rightMargin:);
        
        Method originalMethod = class_getInstanceMethod(cls, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);
        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}
@end

@implementation UINavigationController (SJRotationPrivate_FixSafeArea)
- (BOOL)sj_containsPlayerView {
    return [self.topViewController sj_containsPlayerView];
}
@end

@implementation UITabBarController (SJRotationPrivate_FixSafeArea)
- (BOOL)sj_containsPlayerView {
    UIViewController *vc = self.selectedIndex != NSNotFound ? self.selectedViewController : self.viewControllers.firstObject;
    return [vc sj_containsPlayerView];
}
@end
NS_ASSUME_NONNULL_END

#endif
