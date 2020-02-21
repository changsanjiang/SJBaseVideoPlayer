//
//  SJPLMediaPlayerLayerView.m
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2020/2/20.
//  Copyright © 2020 changsanjiang. All rights reserved.
//

#import "SJPLMediaPlayerLayerView.h"

@implementation SJPLMediaPlayerLayerView
- (instancetype)initWithPlayer:(SJPLMediaPlayer *)player {
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
    [_player.view removeFromSuperview];
    [_player removeObserver:self forKeyPath:@"firstVideoFrameRendered"];
}

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey,id> *)change context:(nullable void *)context {
    [NSNotificationCenter.defaultCenter postNotificationName:SJMediaPlayerViewReadyForDisplayNotification object:self];
}

@synthesize videoGravity = _videoGravity;
- (void)setVideoGravity:(SJVideoGravity)videoGravity {
    _videoGravity = videoGravity ?: AVLayerVideoGravityResizeAspect;
    if ( _videoGravity == AVLayerVideoGravityResize ) {
        _player.view.contentMode = UIViewContentModeScaleToFill;
    }
    else if ( _videoGravity == AVLayerVideoGravityResizeAspect ) {
        _player.view.contentMode = UIViewContentModeScaleAspectFit;
    }
    else if ( _videoGravity == AVLayerVideoGravityResizeAspectFill ) {
        _player.view.contentMode = UIViewContentModeScaleAspectFill;
    }
}

- (SJVideoGravity)videoGravity {
    return _videoGravity ? : AVLayerVideoGravityResizeAspect;
}

- (BOOL)isReadyForDisplay {
    return _player.firstVideoFrameRendered;
}
@end
