//
//  SJIJKMediaPlayerLayerView.m
//  Pods
//
//  Created by BlueDancer on 2020/2/19.
//

#import "SJIJKMediaPlayerLayerView.h"

@implementation SJIJKMediaPlayerLayerView
- (instancetype)initWithPlayer:(SJIJKMediaPlayer *)player {
    self = [super init];
    if ( self ) {
        _player = player;
        [self addSubview:_player.view];
        [self setVideoGravity:AVVideoScalingModeResizeAspect];
        [player addObserver:self forKeyPath:@"firstVideoFrameRendered" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _player.view.frame = self.bounds;
}

- (void)dealloc {
    [_player removeObserver:self forKeyPath:@"firstVideoFrameRendered"];
}

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey,id> *)change context:(nullable void *)context {
    [NSNotificationCenter.defaultCenter postNotificationName:SJMediaPlayerViewReadyForDisplayNotification object:self];
}

- (void)setVideoGravity:(SJVideoGravity)videoGravity {
    _player.videoGravity = videoGravity;
}

- (SJVideoGravity)videoGravity {
    return _player.videoGravity;
}

- (BOOL)isReadyForDisplay {
    return _player.firstVideoFrameRendered;
}
@end
