//
//  SJKSYMediaPlayerView.m
//  SJBaseVideoPlayer
//
//  Created by 畅三江 on 2021/9/9.
//

#import "SJKSYMediaPlayerView.h"

@implementation SJKSYMediaPlayerView
- (instancetype)initWithPlayer:(SJKSYMediaPlayer *)player {
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
    _videoGravity = videoGravity;
    if ( videoGravity == AVLayerVideoGravityResize ) {
        _player.scalingMode = SJKSYMovieScalingModeFill;
    }
    else if ( videoGravity == AVLayerVideoGravityResizeAspect ) {
        _player.scalingMode = SJKSYMovieScalingModeAspectFit;
    }
    else if ( videoGravity == AVLayerVideoGravityResizeAspectFill ) {
        _player.scalingMode = SJKSYMovieScalingModeAspectFill;
    }
}

- (BOOL)isReadyForDisplay {
    return _player.firstVideoFrameRendered;
}
@end
