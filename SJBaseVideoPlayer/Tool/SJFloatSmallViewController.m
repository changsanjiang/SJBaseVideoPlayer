//
//  SJFloatSmallViewController.m
//  Pods
//
//  Created by BlueDancer on 2019/6/6.
//

#import "SJFloatSmallViewController.h"
#if __has_include(<SJUIKit/NSObject+SJObserverHelper.h>)
#import <SJUIKit/NSObject+SJObserverHelper.h>
#else
#import "NSObject+SJObserverHelper.h"
#endif

NS_ASSUME_NONNULL_BEGIN
@interface SJFloatSmallView : UIView
@property (nonatomic, strong, readonly) UIPanGestureRecognizer *panGesture;
@end

@implementation SJFloatSmallView {
    CGFloat _safeEdge;
}
- (instancetype)initWithFrame:(CGRect)frame safeEdge:(CGFloat)safeEdge {
    self = [super initWithFrame:frame];
    if ( !self ) return nil;
    _safeEdge = safeEdge;
    [self _setupView];
    return self;
}

- (void)_setupView {
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_handlePanGesture:)];
    _panGesture.delaysTouchesBegan = YES;
    [self addGestureRecognizer:_panGesture];
}

- (void)_handlePanGesture:(UIPanGestureRecognizer *)panGesture {
    CGPoint offset = [panGesture translationInView:self.superview];
    CGPoint center = self.center;
    self.center = CGPointMake(center.x + offset.x, center.y + offset.y);
    [panGesture setTranslation:CGPointZero inView:self.superview];
    
    switch ( panGesture.state ) {
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed: {
            CGFloat safeEdge = _safeEdge;
            [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                CGFloat left = safeEdge;
                CGFloat right = UIScreen.mainScreen.bounds.size.width - safeEdge - self.w;
                if ( self.x <= left ) {
                    [self setX:left];
                }
                else if ( self.x >= right ) {
                    [self setX:right];
                }
                
                UIWindow *window = UIApplication.sharedApplication.keyWindow;
                UIEdgeInsets insets = UIEdgeInsetsZero;
                if (@available(iOS 11.0, *)) {
                    insets = window.safeAreaInsets;
                }
                CGFloat top = insets.top + 44 + safeEdge;
                CGFloat bottom = window.bounds.size.height - (insets.bottom + 49 + safeEdge + self.h);
                if ( self.y <= top ) {
                    [self setY:top];
                }
                else if ( self.y >= bottom ) {
                    [self setY:bottom];
                }
            } completion:nil];
        }
            break;
        default: break;
    }
}

- (void)setX:(CGFloat)x {
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (CGFloat)x {
    return self.frame.origin.x;
}

- (void)setY:(CGFloat)y {
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (CGFloat)y {
    return self.frame.origin.y;
}

- (CGFloat)w {
    return self.frame.size.width;
}

- (CGFloat)h {
    return self.frame.size.height;
}
@end




@interface SJFloatSmallViewControllerObserver : NSObject<SJFloatSmallViewControllerObserverProtocol>
- (instancetype)initWithController:(id<SJFloatSmallViewControllerProtocol>)controller;
@end

@implementation SJFloatSmallViewControllerObserver
@synthesize appearStateDidChangeExeBlock = _appearStateDidChangeExeBlock;
@synthesize disabledControllerExeBlock = _disabledControllerExeBlock;

- (instancetype)initWithController:(id<SJFloatSmallViewControllerProtocol>)controller {
    self = [super init];
    if ( self ) {
        sjkvo_observe(controller, @"isAppeared", ^(id  _Nonnull target, NSDictionary<NSKeyValueChangeKey,id> * _Nullable change) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ( self.appearStateDidChangeExeBlock )
                    self.appearStateDidChangeExeBlock(controller);
            });
        });
        
        sjkvo_observe(controller, @"disabled", ^(id  _Nonnull target, NSDictionary<NSKeyValueChangeKey,id> * _Nullable change) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ( self.disabledControllerExeBlock )
                    self.disabledControllerExeBlock(controller);
            });
        });
    }
    return self;
}
@end

@interface SJFloatSmallViewController ()
@property (nonatomic) BOOL isAppeared;
@end

@implementation SJFloatSmallViewController
@synthesize disabled = _disabled;
@synthesize view = _view;

- (void)dealloc {
    [_view removeFromSuperview];
}

- (UIView *)view {
    if ( _view == nil ) {
        
        CGFloat safeEdge = 12;
        _view = [[SJFloatSmallView alloc] initWithFrame:CGRectZero safeEdge:safeEdge];
        
        CGRect bounds = UIScreen.mainScreen.bounds;
        CGFloat width = bounds.size.width;
        
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        CGFloat maxW = ceil(width * 0.48);
        CGFloat w = maxW>300?300:maxW;
        CGFloat h = w * 9 /16.0;
        CGFloat x = width - w - safeEdge;
        CGFloat y = 64 + safeEdge;
        if (@available(iOS 11.0, *)) {
            y = window.safeAreaInsets.top + 44 + safeEdge;
        }
        _view.frame = CGRectMake(x, y, w, h);
        _view.backgroundColor = [UIColor clearColor];
        [window addSubview:_view];
    }
    return _view;
}

- (void)floatSmallViewNeedAppear {
    self.isAppeared = YES;
    
    self.view.alpha = 0.001;
    [UIView animateWithDuration:0.3 animations:^{
        self.view.alpha = 1;
    }];
}

- (void)floatSmallViewNeedDisappear {
    self.isAppeared = NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.view.alpha = 0.001;
    }];
}

- (id<SJFloatSmallViewControllerObserverProtocol>)getObserver {
    return [[SJFloatSmallViewControllerObserver alloc] initWithController:self];
}
@end
NS_ASSUME_NONNULL_END
