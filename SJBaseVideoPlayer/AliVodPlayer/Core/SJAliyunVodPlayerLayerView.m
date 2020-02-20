//
//  SJAliyunVodPlayerLayerView.m
//  Pods
//
//  Created by BlueDancer on 2020/2/19.
//

#import "SJAliyunVodPlayerLayerView.h"

@implementation SJAliyunVodPlayerLayerView
- (instancetype)initWithPlayer:(SJAliyunVodPlayer *)player {
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
    _videoGravity = videoGravity ?: AVLayerVideoGravityResizeAspect;
    if ( _videoGravity == AVLayerVideoGravityResize ||
         _videoGravity == AVLayerVideoGravityResizeAspect ) {
        _player.displayMode = AliyunVodPlayerDisplayModeFit;
    }
    else if ( _videoGravity == AVLayerVideoGravityResizeAspectFill ) {
        _player.displayMode = AliyunVodPlayerDisplayModeFitWithCropping;
    }
}

- (SJVideoGravity)videoGravity {
    return _videoGravity ? : AVLayerVideoGravityResizeAspect;
}

- (BOOL)isReadyForDisplay {
    return _player.firstVideoFrameRendered;
}
@end
