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

@synthesize videoGravity = _videoGravity;
- (void)setVideoGravity:(SJVideoGravity)videoGravity {
    _videoGravity = videoGravity;
    IJKMPMovieScalingMode mode = IJKMPMovieScalingModeNone;
    if ( videoGravity == AVLayerVideoGravityResize )
        mode = IJKMPMovieScalingModeFill;
    else if ( videoGravity == AVLayerVideoGravityResizeAspect )
        mode = IJKMPMovieScalingModeAspectFit;
    else if ( videoGravity == AVLayerVideoGravityResizeAspectFill )
        mode = IJKMPMovieScalingModeAspectFill;
    _player.scalingMode = mode;
}
 
- (SJVideoGravity)videoGravity {
    return _videoGravity ? : AVLayerVideoGravityResizeAspect;
}

- (BOOL)isReadyForDisplay {
    return _player.firstVideoFrameRendered;
}
@end
