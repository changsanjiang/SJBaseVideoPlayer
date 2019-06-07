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
@property (nonatomic) CGFloat safeMargin;
@end

@implementation SJFloatSmallView  
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if ( !self ) return nil;
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_handlePanGesture:)];
    panGesture.delaysTouchesBegan = YES;
    [self addGestureRecognizer:panGesture];
    return self;
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
            CGFloat safeMargin = _safeMargin;
            [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                CGFloat left = safeMargin;
                CGFloat right = UIScreen.mainScreen.bounds.size.width - safeMargin - self.w;
                if ( self.x <= left ) {
                    [self setX:left];
                }
                else if ( self.x >= right ) {
                    [self setX:right];
                }
                
                UIView *superview = self.superview;
                UIEdgeInsets insets = UIEdgeInsetsZero;
                if (@available(iOS 11.0, *)) {
                    insets = superview.safeAreaInsets;
                }
                CGFloat top = insets.top + safeMargin;
                CGFloat bottom = superview.bounds.size.height - (insets.bottom + safeMargin + self.h);
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
@synthesize enabledControllerExeBlock = _enabledControllerExeBlock;
@synthesize controller = _controller;

- (instancetype)initWithController:(id<SJFloatSmallViewControllerProtocol>)controller {
    self = [super init];
    if ( self ) {
        _controller = controller;
        
        sjkvo_observe(controller, @"isAppeared", ^(id  _Nonnull target, NSDictionary<NSKeyValueChangeKey,id> * _Nullable change) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ( self.appearStateDidChangeExeBlock )
                    self.appearStateDidChangeExeBlock(controller);
            });
        });
        
        sjkvo_observe(controller, @"enabled", ^(id  _Nonnull target, NSDictionary<NSKeyValueChangeKey,id> * _Nullable change) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ( self.enabledControllerExeBlock )
                    self.enabledControllerExeBlock(controller);
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
@synthesize floatSmallViewShouldAppear = _floatSmallViewShouldAppear;
@synthesize targetSuperview = _targetSuperview;
@synthesize enabled = _enabled;
@synthesize target = _target;
@synthesize safeMargin = _safeMargin;
@synthesize view = _view;

- (instancetype)init {
    self = [super init];
    if ( self ) {
        _safeMargin = 12;
    }
    return self;
}

- (void)dealloc {
    [_view removeFromSuperview];
}

- (UIView *)view {
    if ( _view == nil ) {
        SJFloatSmallView *view = [[SJFloatSmallView alloc] initWithFrame:CGRectZero];
        view.safeMargin = _safeMargin;
        _view = view;
    }
    return _view;
}

- (void)setSafeMargin:(CGFloat)safeMargin {
    _safeMargin = safeMargin;
    [(SJFloatSmallView *)_view setSafeMargin:safeMargin];
}

- (void)showFloatSmallView {
    if ( !self.isEnabled ) return;
    
    //
    if ( _floatSmallViewShouldAppear && _floatSmallViewShouldAppear(self) ) {
        //
        UIViewController *currentViewController = [self atViewController];
        UIView *superview = currentViewController.view;
        if ( self.view.superview != superview ) {
            [superview addSubview:self.view];
            CGRect bounds = superview.bounds;
            CGFloat width = bounds.size.width;
            
            //
            CGFloat maxW = ceil(width * 0.48);
            CGFloat w = maxW>300?300:maxW;
            CGFloat h = w * 9 /16.0;
            CGFloat x = width - w - _safeMargin;
            CGFloat y = _safeMargin;
            if (@available(iOS 11.0, *)) {
                y += superview.safeAreaInsets.top;
            }

            self.view.frame = CGRectMake(x, y, w, h);
        }
        
        //
        self.target.frame = self.view.bounds;
        [self.view addSubview:self.target];
        [self.target layoutIfNeeded];

        [UIView animateWithDuration:0.3 animations:^{
            self.view.alpha = 1;
        }];
        
        self.isAppeared = YES;
    }
}

- (void)dismissFloatSmallView {
    if ( !self.isEnabled ) return;
    
    self.target.frame = self.targetSuperview.bounds;
    [self.targetSuperview addSubview:self.target];
    [self.target layoutIfNeeded];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.view.alpha = 0.001;
    }];
    
    self.isAppeared = NO;
}

- (id<SJFloatSmallViewControllerObserverProtocol>)getObserver {
    return [[SJFloatSmallViewControllerObserver alloc] initWithController:self];
}

- (nullable __kindof UIViewController *)atViewController {
    UIResponder *_Nullable responder = _targetSuperview;
    if ( responder != nil ) {
        while ( ![responder isKindOfClass:[UIViewController class]] ) {
            responder = responder.nextResponder;
            if ( [responder isMemberOfClass:[UIResponder class]] || !responder ) return nil;
        }
    }
    return (__kindof UIViewController *)responder;
}
@end
NS_ASSUME_NONNULL_END
