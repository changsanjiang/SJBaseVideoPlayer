//
//  SJRotationManager_iOS_9_15.m
//  SJVideoPlayer_Example
//
//  Created by 畅三江 on 2022/8/13.
//  Copyright © 2022 changsanjiang. All rights reserved.
//

#import "SJRotationManager_iOS_9_15.h"
#import "SJBaseVideoPlayerConst.h"
#import "UIView+SJBaseVideoPlayerExtended.h"
#import "SJRotationFullscreenViewController.h"
#import "SJRotationManagerInternal.h"
#import "SJRotationDefines.h"
@class SJRotationFullscreenViewController_iOS_9_15;

API_DEPRECATED("deprecated!", ios(9.0, 16.0)) @protocol SJRotationFullscreenViewControllerDelegate_iOS_9_15 <SJRotationFullscreenViewControllerDelegate>
- (BOOL)shouldAutorotateForRotationFullscreenViewController:(SJRotationFullscreenViewController_iOS_9_15 *)viewController;
- (void)rotationFullscreenViewController:(SJRotationFullscreenViewController_iOS_9_15 *)viewController viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator;
@end

API_DEPRECATED("deprecated!", ios(9.0, 16.0)) @interface SJRotationFullscreenViewController_iOS_9_15 : SJRotationFullscreenViewController
@property (nonatomic, strong, readonly) UIView *playerSuperview;
@property (nonatomic, weak, nullable) id<SJRotationFullscreenViewControllerDelegate_iOS_9_15> delegate;
@end

@implementation SJRotationFullscreenViewController_iOS_9_15
@dynamic delegate;
 
- (void)viewDidLoad {
    [super viewDidLoad];
    _playerSuperview = [UIView.alloc initWithFrame:CGRectZero];
    _playerSuperview.backgroundColor = UIColor.clearColor;
    [self.view addSubview:_playerSuperview];
}

- (BOOL)shouldAutorotate {
    return [self.delegate shouldAutorotateForRotationFullscreenViewController:self];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationNone;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self.delegate rotationFullscreenViewController:self viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}
@end

@interface SJRotationManager_iOS_9_15 ()<SJRotationFullscreenViewControllerDelegate_iOS_9_15> {
    void(^_completionHandler)(SJRotationManager *mgr);
}
@property (nonatomic, strong, readonly) SJRotationFullscreenViewController_iOS_9_15 *rotationFullscreenViewController;
@end

@implementation SJRotationManager_iOS_9_15

@synthesize rotationFullscreenViewController = _rotationFullscreenViewController;
- (SJRotationFullscreenViewController_iOS_9_15 *)rotationFullscreenViewController {
    if ( _rotationFullscreenViewController == nil ) {
        _rotationFullscreenViewController = [SJRotationFullscreenViewController_iOS_9_15.alloc init];
    }
    return _rotationFullscreenViewController;
}
 
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return (self.target.superview == self.rotationFullscreenViewController.playerSuperview) &&
          [self.rotationFullscreenViewController.playerSuperview pointInside:[self.window convertPoint:point toView:self.rotationFullscreenViewController.playerSuperview] withEvent:event];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)rotateToOrientation:(SJOrientation)orientation animated:(BOOL)animated complete:(void (^)(SJRotationManager * _Nonnull))completionHandler {
#ifdef DEBUG
    if ( !animated ) {
        NSAssert(false, @"暂不支持关闭动画!");
    }
#endif
    _completionHandler = completionHandler;
    [UIDevice.currentDevice setValue:@(UIDeviceOrientationUnknown) forKey:@"orientation"];
    [UIDevice.currentDevice setValue:@(orientation) forKey:@"orientation"];
}

- (void)rotationBegin {
    if ( self.window.isHidden ) [self.window makeKeyAndVisible];
    [super rotationBegin];
    self.currentOrientation = self.deviceOrientation;
    [UIView animateWithDuration:0.0 animations:^{ } completion:^(BOOL finished) {
        [self.window.rootViewController setNeedsStatusBarAppearanceUpdate];
    }];
}

- (void)rotationEnd {
    if ( !self.window.isHidden && ![self isFullscreen] ) {
        [self.superview.window makeKeyAndVisible];
        self.window.hidden = YES;
    }
    [super rotationEnd];
    if ( _completionHandler != nil ) {
        _completionHandler(self);
        _completionHandler = nil;
    }
}

#pragma mark -

- (BOOL)shouldAutorotateForRotationFullscreenViewController:(SJRotationFullscreenViewController_iOS_9_15 *)viewController {
    if ( [self allowsRotation] ) {
        if ( !self.rotating ) [self rotationBegin];
        return YES;
    }
    return NO;
}

- (void)rotationFullscreenViewController:(SJRotationFullscreenViewController_iOS_9_15 *)viewController viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self transitionBegin];
    UIView *sourceView = self.target;
    UIView *sourceSuperview = self.superview;
    UIView *targetSuperview = self.rotationFullscreenViewController.playerSuperview;
    if ( size.width > size.height ) {
        if ( sourceView.superview != targetSuperview ) {
            CGRect frame = [sourceView convertRect:sourceView.bounds toView:sourceView.window];
            targetSuperview.frame = frame; // t1
            
            sourceView.frame = (CGRect){0, 0, frame.size};
            sourceView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [targetSuperview addSubview:sourceView]; // t2
        }
        
        [UIView animateWithDuration:0.0 animations:^{ /* preparing */ } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 animations:^{
                targetSuperview.frame = (CGRect){CGPointZero, size};
            } completion:^(BOOL finished) {
                [self transitionEnd];
                [self rotationEnd];
            }];
        }];
    }
    else {
        [UIView animateWithDuration:0.0 animations:^{ /* preparing */ } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 animations:^{
                targetSuperview.frame = [sourceSuperview convertRect:sourceSuperview.bounds toView:sourceSuperview.window];
            } completion:^(BOOL finished) {
                UIView *snapshot = [sourceView snapshotViewAfterScreenUpdates:NO];
                snapshot.frame = sourceSuperview.bounds;
                snapshot.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                [sourceSuperview addSubview:snapshot];
                [UIView animateWithDuration:0.0 animations:^{ /* preparing */ } completion:^(BOOL finished) {
                    sourceView.frame = sourceSuperview.bounds;
                    sourceView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                    [sourceSuperview addSubview:sourceView];
                    [snapshot removeFromSuperview];
                    [self transitionEnd];
                    [self rotationEnd];
                }];
            }];
        }];
    }
}
@end
