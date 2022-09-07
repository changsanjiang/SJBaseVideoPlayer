//
//  SJPromptingPopupController.m
//  Pods
//
//  Created by 畅三江 on 2019/7/12.
//

#import "SJPromptingPopupController.h"
#import "SJBaseVideoPlayerConst.h"
#if __has_include(<Masonry/Masonry.h>)
#import <Masonry/Masonry.h>
#else
#import "Masonry.h"
#endif

NS_ASSUME_NONNULL_BEGIN

#define _AnimDuration (0.4)

@interface _SJItemPopupContainerView : UIView
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UIView *customView;
@end

@implementation _SJItemPopupContainerView
- (instancetype)initWithFrame:(CGRect)frame contentInset:(UIEdgeInsets)contentInset {
    self = [self initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
        self.layer.cornerRadius = 5;
        
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.numberOfLines = 0;
        [self addSubview:_titleLabel];
        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_offset(contentInset);
        }];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame customView:(UIView *)customView {
    self = [self initWithFrame:frame];
    if ( self ) {
        _customView = customView;
        [self addSubview:customView];
        [customView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.offset(0);
        }];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if ( self ) {
        self.layer.zPosition = SJPlayerZIndexes.shared.promptingPopupViewZIndex;
    }
    return self;
}
@end


@interface SJPromptingPopupController ()
@property (nonatomic, strong, readonly) NSMutableArray<_SJItemPopupContainerView *> *subviews;
@end

@implementation SJPromptingPopupController
@synthesize target = _target;
@synthesize leftMargin = _leftMargin;
@synthesize bottomMargin = _bottomMargin;
@synthesize itemSpacing = _itemSpacing;
@synthesize contentInset = _contentInset;
@synthesize automaticallyAdjustsLeftInset = _automaticallyAdjustsLeftInset;
@synthesize automaticallyAdjustsBottomInset = _automaticallyAdjustsBottomInset;

- (instancetype)init {
    self = [super init];
    if (self) {
        _automaticallyAdjustsLeftInset = YES;
        _automaticallyAdjustsBottomInset = YES;
        
        _subviews = [NSMutableArray new];
        _leftMargin = 16;
        _bottomMargin = 16;
        _itemSpacing = 12;
        _contentInset = UIEdgeInsetsMake(12, 22, 12, 22);
    }
    return self;
}

- (void)setBottomMargin:(CGFloat)bottomMargin {
    if ( bottomMargin != _bottomMargin ) {
        _bottomMargin = bottomMargin;
        if ( self.subviews.count != 0 ) {
            [self _remakeConstraintsAtIndex:self.subviews.count - 1];
            [UIView animateWithDuration:_AnimDuration animations:^{
                [self.target layoutIfNeeded];
            }];
        }
    }
}

- (void)show:(NSAttributedString *)title {
    [self show:title duration:3];
}

- (void)show:(NSAttributedString *)title duration:(NSTimeInterval)duration {
    _SJItemPopupContainerView *view = [[_SJItemPopupContainerView alloc] initWithFrame:CGRectZero contentInset:_contentInset];
    view.titleLabel.attributedText = title;
    [self _show:view duration:duration];
}

- (void)showCustomView:(UIView *)view {
    [self showCustomView:view duration:3];
}

- (void)showCustomView:(UIView *)customView duration:(NSTimeInterval)duration {
    _SJItemPopupContainerView *view = [[_SJItemPopupContainerView alloc] initWithFrame:CGRectZero customView:customView];
    [self _show:view duration:duration];
}

- (BOOL)isShowingWithCustomView:(UIView *)view {
    for ( _SJItemPopupContainerView *containerView in self.subviews ) {
        if ( containerView.customView == view )
            return YES;
    }
    return NO;
}

- (nullable __kindof NSArray<UIView *> *)displayingViews {
    if ( self.subviews.count != 0 ) {
        NSMutableArray *m = [NSMutableArray arrayWithCapacity:self.subviews.count];
        for ( _SJItemPopupContainerView *containerView  in self.subviews ) {
            [m addObject:containerView.customView ?: containerView.titleLabel];
        }
        return m;
    }
    return nil;
}

- (void)clear {
    [self _removeAllSubviews];
}

- (void)remove:(UIView *)view {
    for ( _SJItemPopupContainerView *containerView  in self.subviews ) {
        if ( containerView.customView == view || containerView.titleLabel == view ) {
            [self _removeSubview:containerView];
            break;
        }
    }
}

- (void)_show:(_SJItemPopupContainerView *)view duration:(NSTimeInterval)duration {
    [self _addSubview:view];
    __weak typeof(view) _view = view;
    __weak typeof(self) _self = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(_self) self = _self;
        if ( !self ) return ;
        if ( !_view ) return ;
        [self _removeSubview:_view];
    });
}

- (void)_addSubview:(_SJItemPopupContainerView *)view {
    CGRect bounds = self.target.bounds;
    view.frame = CGRectMake(-bounds.size.width, bounds.size.height - _bottomMargin, 0, 0);
    [self.target addSubview:view];
    [self.subviews addObject:view];

    [self.subviews enumerateObjectsUsingBlock:^(_SJItemPopupContainerView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self _remakeConstraintsAtIndex:idx];
    }];
    
    [UIView animateWithDuration:_AnimDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.target layoutIfNeeded];
    } completion:nil];
}

- (void)_removeSubview:(_SJItemPopupContainerView *)view {
    NSUInteger idx = [self.subviews indexOfObject:view];
    if ( idx == NSNotFound )
        return;
    
    [self.subviews removeObjectAtIndex:idx];
    
    [self _remakeConstraintsAtIndex:idx - 1];
    [self _remakeConstraintsAtIndex:idx];

    [UIView animateWithDuration:_AnimDuration animations:^{
        view.alpha = 0.01;
        [self.target layoutIfNeeded];
    } completion:^(BOOL finished) {
        [view removeFromSuperview];
    }];
}

- (void)_removeAllSubviews {
    if ( self.subviews.count != 0 ) {
        NSArray<_SJItemPopupContainerView *> *subviews = self.subviews.copy;
        [self.subviews removeAllObjects];
        [UIView animateWithDuration:_AnimDuration animations:^{
            for ( UIView *subview in subviews ) {
                subview.alpha = 0.001;
            }
        } completion:^(BOOL finished) {
            [subviews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(_SJItemPopupContainerView * _Nonnull subview, NSUInteger idx, BOOL * _Nonnull stop) {
                [subview removeFromSuperview];
            }];
        }];
    }
}

- (void)_remakeConstraintsAtIndex:(NSInteger)idx {
    if ( idx < 0 || idx >= self.subviews.count )
        return;
    
    NSUInteger count = self.subviews.count;
    _SJItemPopupContainerView *view = self.subviews[idx];
    [view mas_remakeConstraints:^(MASConstraintMaker *make) {
        if ( self.automaticallyAdjustsLeftInset ) {
            if ( @available(iOS 11.0, *) ) {
                make.left.equalTo(self.target.mas_safeAreaLayoutGuideLeft).offset(self.leftMargin);
            } else {
                make.left.offset(self.leftMargin);
            }
        }
        else {
            make.left.offset(self.leftMargin);
        }
        
        if ( idx != count - 1 ) {
            make.bottom.equalTo(self.subviews[idx + 1].mas_top).offset(-self.itemSpacing);
        }
        else {
            if ( self.automaticallyAdjustsBottomInset ) {
                if ( @available(iOS 11.0, *) ) {
                    make.bottom.equalTo(self.target.mas_safeAreaLayoutGuideBottom).offset(-self.bottomMargin);
                } else {
                    make.bottom.offset(-self.bottomMargin);
                }
            }
            else {
                make.bottom.offset(-self.bottomMargin);
            }
        }
    }];
}
@end
NS_ASSUME_NONNULL_END
