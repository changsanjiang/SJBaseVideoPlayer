//
//  SJAliMediaPlayerLayerView.m
//  Pods
//
//  Created by BlueDancer on 2020/2/19.
//

#import "SJAliMediaPlayerLayerView.h"

NS_ASSUME_NONNULL_BEGIN
@implementation SJAliMediaPlayerLayerView
- (instancetype)initWithPlayer:(SJAliMediaPlayer *)player {
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
    if ( self.videoGravity == AVLayerVideoGravityResize ) {
        _player.scalingMode = AVP_SCALINGMODE_SCALETOFILL;
    }
    else if ( self.videoGravity == AVLayerVideoGravityResizeAspect ) {
        _player.scalingMode = AVP_SCALINGMODE_SCALEASPECTFIT;
    }
    else if ( self.videoGravity == AVLayerVideoGravityResizeAspectFill ) {
        _player.scalingMode = AVP_SCALINGMODE_SCALEASPECTFILL;
    }
}

- (SJVideoGravity)videoGravity {
    return _videoGravity ? : AVLayerVideoGravityResizeAspect;
}

- (BOOL)isReadyForDisplay {
    return _player.firstVideoFrameRendered;
}
@end
NS_ASSUME_NONNULL_END
