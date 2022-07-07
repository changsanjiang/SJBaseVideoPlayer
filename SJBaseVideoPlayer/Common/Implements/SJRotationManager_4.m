//
//  SJRotationManager_4.m
//  SJVideoPlayer_Example
//
//  Created by 畅三江 on 2022/7/6.
//  Copyright © 2022 changsanjiang. All rights reserved.
//

#import "SJRotationManager_4.h"
#import "SJTimerControl.h"
#import "SJBaseVideoPlayerConst.h"
#import "SJRotationManagerInternal_4.h"
#import "UIView+SJBaseVideoPlayerExtended.h"

FOUNDATION_STATIC_INLINE  BOOL
_isFullscreenOrientation(SJOrientation orientation) {
    return orientation != SJOrientation_Portrait;
}

FOUNDATION_STATIC_INLINE  BOOL
_isSupportedOrientation(SJOrientationMask supportedOrientations, SJOrientation orientation) {
    switch ( orientation ) {
        case SJOrientation_Portrait:
            return supportedOrientations & SJOrientationMaskPortrait;
        case SJOrientation_LandscapeLeft:
            return supportedOrientations & SJOrientationMaskLandscapeLeft;
        case SJOrientation_LandscapeRight:
            return supportedOrientations & SJOrientationMaskLandscapeRight;
    }
    return NO;
}

@protocol UIDevicePrivateMethods_4 <NSObject>
- (void)setOrientation:(UIDeviceOrientation)orientation animated:(BOOL)animated;
@end

#pragma mark - observer


static NSNotificationName const SJRotationManagerRotationNotification_4 = @"SJRotationManagerRotationNotification_4";


@interface SJRotationObserver_4 : NSObject<SJRotationManagerObserver>
- (instancetype)initWithManager:(id<SJRotationManager>)manager;
@property (nonatomic, copy, nullable) void(^rotationDidStartExeBlock)(id<SJRotationManager> mgr);
@property (nonatomic, copy, nullable) void(^rotationDidEndExeBlock)(id<SJRotationManager> mgr);
@end

@implementation SJRotationObserver_4
- (instancetype)initWithManager:(id<SJRotationManager>)manager {
    self = [super init];
    if ( self ) {
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onRotation:) name:SJRotationManagerRotationNotification_4 object:manager];
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)onRotation:(NSNotification *)note {
    BOOL isRotating = [(SJRotationManager_4 *)note.object isRotating];
    if ( isRotating ) {
        if ( _rotationDidStartExeBlock != nil ) _rotationDidStartExeBlock(note.object);
    }
    else {
        if ( _rotationDidEndExeBlock != nil ) _rotationDidEndExeBlock(note.object);
    }
}
@end

#pragma mark - view controller

@protocol SJRotationFullscreenViewController_4Delegate;

// API_AVAILABLE 后面去掉

@interface SJRotationFullscreenViewController_4 : UIViewController

@property (nonatomic, weak, nullable) id<SJRotationFullscreenViewController_4Delegate> sj_4_delegate;

@property (nonatomic, strong, readonly) UIView *playerSuperview;

@end


@protocol SJRotationFullscreenViewController_4Delegate <NSObject>
- (BOOL)shouldAutorotate;
- (void)viewController:(SJRotationFullscreenViewController_4 *)viewController viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator;

- (BOOL)prefersStatusBarHidden;
- (UIStatusBarStyle)preferredStatusBarStyle;
@end

@implementation SJRotationFullscreenViewController_4
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.clipsToBounds = NO;
    self.view.backgroundColor = UIColor.clearColor;
    
    _playerSuperview = [UIView.alloc initWithFrame:CGRectZero];
    _playerSuperview.backgroundColor = UIColor.clearColor;
    [self.view addSubview:_playerSuperview];
}

- (BOOL)shouldAutorotate {
    return [_sj_4_delegate shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return [_sj_4_delegate prefersStatusBarHidden];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [_sj_4_delegate preferredStatusBarStyle];
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}

- (void)setNeedsStatusBarAppearanceUpdate {
    [super setNeedsStatusBarAppearanceUpdate];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [_sj_4_delegate viewController:self viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}
@end

@protocol SJRotationFullscreenNavigationController_4Delegate <NSObject>
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;
@end

@interface SJRotationFullscreenNavigationController_4 : UINavigationController
@property (nonatomic, weak, nullable) id<SJRotationFullscreenNavigationController_4Delegate> sj_4_delegate;
@end

@implementation SJRotationFullscreenNavigationController_4
- (void)viewDidLoad {
    [super viewDidLoad];
    [super setNavigationBarHidden:YES animated:NO];
}

- (void)setNavigationBarHidden:(BOOL)navigationBarHidden { }

- (void)setNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated { }

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
- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ( [viewController isKindOfClass:SJRotationFullscreenViewController_4.class] ) {
        [super pushViewController:viewController animated:animated];
    }
    else if ( [self.sj_4_delegate respondsToSelector:@selector(pushViewController:animated:)] ) {
        [self.sj_4_delegate pushViewController:viewController animated:animated];
    }
}
@end


#pragma mark - window

@protocol SJRotationFullscreenWindow_4Delegate;


@interface SJRotationFullscreenWindow_4 : UIWindow
@property (nonatomic, weak, nullable) id<SJRotationFullscreenWindow_4Delegate> sj_4_delegate;
@end


@protocol SJRotationFullscreenWindow_4Delegate <NSObject>
- (BOOL)window:(SJRotationFullscreenWindow_4 *)window pointInside:(CGPoint)point withEvent:(UIEvent *_Nullable)event;
- (BOOL)allowsRotation;
@end

@implementation SJRotationFullscreenWindow_4
@dynamic rootViewController;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if ( self ) {
        [self _setup];
    }
    return self;
}

- (instancetype)initWithWindowScene:(UIWindowScene *)windowScene {
    self = [super initWithWindowScene:windowScene];
    if ( self ) {
        [self _setup];
    }
    return self;
}

- (BOOL)canBecomeKeyWindow {
    return NO;
}

#ifdef DEBUG
- (void)dealloc {
    NSLog(@"%d \t %s", (int)__LINE__, __func__);
}
#endif

- (void)setRootViewController:(UIViewController *)rootViewController {
    [super setRootViewController:rootViewController];
    rootViewController.view.frame = self.bounds;
    rootViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)_setup {
    self.frame = UIScreen.mainScreen.bounds;
    self.windowLevel = UIWindowLevelStatusBar - 1;
}

- (void)setBackgroundColor:(nullable UIColor *)backgroundColor {}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *_Nullable)event {
    return [_sj_4_delegate window:self pointInside:point withEvent:event];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    
    static CGRect bounds;
    
    // 如果是大屏转大屏 就不需要修改了
    
    if ( !CGRectEqualToRect(bounds, self.bounds) ) {
        
        UIView *superview = self;
        if ( @available(iOS 13.0, *) ) {
            superview = self.subviews.firstObject;
        }

        [UIView performWithoutAnimation:^{
            for ( UIView *view in superview.subviews ) {
                if ( view != self.rootViewController.view && [view isMemberOfClass:UIView.class] ) {
                    view.backgroundColor = UIColor.clearColor;
                    for ( UIView *subview in view.subviews ) {
                        subview.backgroundColor = UIColor.clearColor;
                    }
                }
                
            }
        }];
    }
    
    bounds = self.bounds;
    self.rootViewController.view.frame = bounds;
}

@end

#pragma mark - manager

@interface SJRotationManager_4 ()<SJRotationFullscreenWindow_4Delegate, SJRotationFullscreenViewController_4Delegate, SJRotationFullscreenNavigationController_4Delegate>
@property (nonatomic) UIDeviceOrientation deviceOrientation;
@property (nonatomic, copy, nullable) void(^completionHandler)(id<SJRotationManager> mgr);

///
/// 默认为活跃状态
///
///     进入后台时, 将设置状态为不活跃状态, 此时将不会触发自动旋转
///     进入前台时, 两秒后将恢复为活跃状态, 两秒之后才能开始响应自动旋转
///
///     主动调用旋转时, 将直接激活为活跃状态
///
@property (nonatomic, getter=isInactivated) BOOL inactivated;
@property (nonatomic, strong, readonly) SJTimerControl *timerControl;

@property (nonatomic, getter=isForcedrotation) BOOL forcedrotation;
@property (nonatomic, getter=isTransitioning) BOOL transitioning;

@property (nonatomic, strong) SJRotationFullscreenWindow_4 *window;
@property (nonatomic, strong) SJRotationFullscreenViewController_4 *viewController;
@property (nonatomic, weak, nullable) id<SJRotationManager_4Delegate> delegate;
@end

@implementation SJRotationManager_4
@synthesize shouldTriggerRotation = _shouldTriggerRotation;
@synthesize disabledAutorotation = _disabledAutorotation;
@synthesize autorotationSupportedOrientations = _autorotationSupportedOrientations;
@synthesize currentOrientation = _currentOrientation;
@synthesize rotating = _rotating;
@synthesize superview = _superview;
@synthesize target = _target;

- (instancetype)init {
    self = [super init];
    if ( self ) {
        _autorotationSupportedOrientations = SJOrientationMaskAll;
        _currentOrientation = SJOrientation_Portrait;
        _deviceOrientation = UIDeviceOrientationPortrait;
        _timerControl = [SJTimerControl.alloc init];
        _timerControl.interval = 2;
        __weak typeof(self) _self = self;
        _timerControl.exeBlock = ^(SJTimerControl * _Nonnull control) {
            __strong typeof(_self) self = _self;
            if ( !self ) return ;
            self.inactivated = NO;
        };
        [self _observeNotifies];
        
        _viewController = [SJRotationFullscreenViewController_4.alloc init];
        _viewController.sj_4_delegate = self;
        
        SJRotationFullscreenNavigationController_4 *nav = [SJRotationFullscreenNavigationController_4.alloc initWithRootViewController:_viewController];
        nav.sj_4_delegate = self;
        
        if ( @available(iOS 13.0, *) ) {
            _window = [SJRotationFullscreenWindow_4.alloc initWithWindowScene:UIApplication.sharedApplication.keyWindow.windowScene];
        }
        else {
            _window = [SJRotationFullscreenWindow_4.alloc initWithFrame:UIScreen.mainScreen.bounds];
        }
        _window.sj_4_delegate = self;
        _window.rootViewController = nav;
        _window.hidden = NO;
    }
    return self;
}

- (id<SJRotationManagerObserver>)getObserver {
    return [SJRotationObserver_4.alloc initWithManager:self];
}

- (BOOL)isFullscreen {
    return _isFullscreenOrientation(_currentOrientation);
}

- (void)rotate {
    SJOrientation orientation;
    if ( _isFullscreenOrientation(_currentOrientation) ) {
        orientation = SJOrientation_Portrait;
    }
    else {
        orientation = _isFullscreenOrientation(_deviceOrientation) ? _deviceOrientation : SJOrientation_LandscapeLeft;
    }
    
    [self rotate:orientation animated:YES];
}

- (void)rotate:(SJOrientation)orientation animated:(BOOL)animated {
    [self rotate:orientation animated:animated completionHandler:nil];
}

- (void)rotate:(SJOrientation)orientation animated:(BOOL)animated completionHandler:(nullable void(^)(id<SJRotationManager> mgr))completionHandler {
#ifdef DEBUG
    if ( !animated ) {
        NSAssert(false, @"暂不支持关闭动画!");
    }
#endif
    _completionHandler = completionHandler;
    _inactivated = NO;
    _forcedrotation = YES;
    
    if ( orientation == _currentOrientation ) {
        [self _endRotation];
        return;
    }
    
    
    if ( @available(iOS 16.0, *) ) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 160000
        __weak typeof(self) _self = self;
        UIWindowSceneGeometryPreferencesIOS *preferences = [UIWindowSceneGeometryPreferencesIOS.alloc initWithInterfaceOrientations:1 << orientation];
        [(id)UIDevice.currentDevice setOrientation:orientation animated:YES];
        [UIView animateWithDuration:0.0 animations:^{ /* nothing */ } completion:^(BOOL finished) {
            self->_window.hidden = NO;
            [UIViewController attemptRotationToDeviceOrientation];
            [self->_window.windowScene requestGeometryUpdateWithPreferences:preferences errorHandler:^(NSError * _Nonnull error) {
                __strong typeof(_self) self = _self;
                if ( !self ) return ;
#ifdef DEBUG
                NSLog(@"旋转失败: %@", error);
#endif
                [self _endRotation];
            }];
        }];
#endif
    }
    else {
        [UIViewController attemptRotationToDeviceOrientation];
        [UIDevice.currentDevice setValue:@(UIDeviceOrientationUnknown) forKey:@"orientation"];
        [UIDevice.currentDevice setValue:@(orientation) forKey:@"orientation"];
    }
}

#pragma mark - SJRotationFullscreenWindow_4Delegate, SJRotationFullscreenViewController_4Delegate, SJRotationFullscreenNavigationController_4Delegate

- (BOOL)window:(SJRotationFullscreenWindow_4 *)window pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return _viewController.playerSuperview.subviews.count != 0 &&
          [_viewController.playerSuperview pointInside:[window convertPoint:point toView:_viewController.playerSuperview] withEvent:event];
}

- (BOOL)prefersStatusBarHidden {
    return _rotating ? _isFullscreenOrientation(_deviceOrientation) : [_delegate prefersStatusBarHidden];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [_delegate preferredStatusBarStyle];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [_delegate pushViewController:viewController animated:animated];
}

- (BOOL)allowsRotation {
    if ( _inactivated ) return NO;
    if ( _currentOrientation == (SJOrientation)_deviceOrientation ) return NO;
    if ( !_forcedrotation ) {
        if ( _disabledAutorotation ) return NO;
        if ( !_isSupportedOrientation(_autorotationSupportedOrientations, _deviceOrientation) ) return NO;
    }
    if ( _rotating && _transitioning ) return NO;
    UIView *playerView = [UIApplication.sharedApplication.keyWindow viewWithTag:SJBaseVideoPlayerViewTag];
    if ( playerView == nil || playerView != _superview ) return NO;
    if ( _shouldTriggerRotation != nil && !_shouldTriggerRotation(self) ) return NO;
    return YES;
}

- (BOOL)shouldAutorotate {
    if ( [self allowsRotation] ) {
        if ( !_rotating ) [self _beginRotation];
        return YES;
    }
    return NO;
}

- (void)viewController:(SJRotationFullscreenViewController_4 *)viewController viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    _transitioning = YES;
    _currentOrientation = _deviceOrientation;
    
    UIWindow *keyWindow = UIApplication.sharedApplication.keyWindow;
    
    if ( size.width > size.height ) {
        if ( _target.superview != _viewController.playerSuperview ) {
            CGRect frame = [_target convertRect:_target.bounds toView:keyWindow];
            _viewController.playerSuperview.frame = frame; // t1
            
            _target.frame = (CGRect){0, 0, frame.size};
            _target.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [_viewController.playerSuperview addSubview:_target]; // t2
        }
        
        [UIView animateWithDuration:0.0 animations:^{ /* nothing */ } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 animations:^{
                self->_viewController.playerSuperview.frame = (CGRect){CGPointZero, size};
            } completion:^(BOOL finished) {
                self->_transitioning = NO;
                [self _endRotation];
                [UIViewController attemptRotationToDeviceOrientation];
            }];
        }];
    }
    else {
        [self _fixNavigationBarLayout];
        [UIView animateWithDuration:0.0 animations:^{ /* nothing */ } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 animations:^{
                self->_viewController.playerSuperview.frame = [self->_superview convertRect:self->_superview.bounds toView:keyWindow];
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.0 animations:^{ /* nothing */ } completion:^(BOOL finished) {
                    self->_transitioning = NO;
                    self->_target.frame = self->_superview.bounds;
                    [self->_superview addSubview:self->_target];
                    [self _endRotation];
                    [UIViewController attemptRotationToDeviceOrientation];
                }];
            }];
        }];
    }
}

- (void)_beginRotation {
    _window.hidden = NO;
    _rotating = YES;
    if ( _isFullscreenOrientation(_deviceOrientation) ) {
        [UIView animateWithDuration:0.0 animations:^{ } completion:^(BOOL finished) {
            [self->_window.rootViewController setNeedsStatusBarAppearanceUpdate];
        }];
    }
    else {
        [UIView performWithoutAnimation:^{
            [self->_window.rootViewController setNeedsStatusBarAppearanceUpdate];
        }];
    }
    [NSNotificationCenter.defaultCenter postNotificationName:SJRotationManagerRotationNotification_4 object:self];
}

- (void)_endRotation {
    _rotating = NO;
    _forcedrotation = NO;
    if ( ![self isFullscreen] ) _window.hidden = YES;
    if ( _completionHandler ) {
        _completionHandler(self);
        _completionHandler = nil;
    }
    [NSNotificationCenter.defaultCenter postNotificationName:SJRotationManagerRotationNotification_4 object:self];
}

- (void)_fixNavigationBarLayout {
    UINavigationController *nav = [_superview lookupResponderForClass:UINavigationController.class];
    [nav viewDidAppear:NO];
    [nav.navigationBar layoutSubviews];
}

#pragma mark -

- (void)_observeNotifies {
    UIDevice *device = UIDevice.currentDevice;
    if ( !device.isGeneratingDeviceOrientationNotifications ) {
        [device beginGeneratingDeviceOrientationNotifications];
    }
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_onDeviceOrientationChanged:) name:UIDeviceOrientationDidChangeNotification object:device];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_onApplicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_onApplicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)_onDeviceOrientationChanged:(NSNotification *)note {
    UIDeviceOrientation orientation = UIDevice.currentDevice.orientation;
    switch ( orientation ) {
        case UIDeviceOrientationPortraitUpsideDown:
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationLandscapeLeft:
        case UIDeviceOrientationLandscapeRight: {
            if ( _deviceOrientation != orientation ) {
                _deviceOrientation = orientation;
                
                if ( [self allowsRotation] ) {
                    [self rotate:_deviceOrientation animated:YES];
                }
            }
            
        }
            break;
        default: break;
    }
}

- (void)_onApplicationWillResignActive:(NSNotification *)note {
    [_timerControl clear];
    _inactivated = YES;
}

- (void)_onApplicationDidBecomeActive:(NSNotification *)note {
    [_timerControl start];
}

- (void)dealloc {
    _window.hidden = YES;
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)setNeedsStatusBarAppearanceUpdate {
    [_window.rootViewController setNeedsStatusBarAppearanceUpdate];
}
@end


@implementation UIWindow (SJRotationControls)
- (UIInterfaceOrientationMask)sj_4_supportedInterfaceOrientations {
    if ( [self isKindOfClass:SJRotationFullscreenWindow_4.class] ) {
        SJRotationFullscreenWindow_4 *window = (SJRotationFullscreenWindow_4 *)self;
        SJRotationManager_4 *rotationManager = (SJRotationManager_4 *)window.sj_4_delegate;
        if ( [rotationManager allowsRotation] ) {
            return UIInterfaceOrientationMaskAllButUpsideDown;
        }
        return 1 << rotationManager.currentOrientation;
    }
    
    return UIInterfaceOrientationMaskPortrait;
}
@end

//if ( UIUserInterfaceIdiomPhone == UI_USER_INTERFACE_IDIOM() ) { }
//else if ( UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM() ) { }
