//
//  SJIJKMediaPlaybackController.m
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2019/10/12.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

#import "SJIJKMediaPlaybackController.h"
#import "SJIJKMediaPlayerLayerView.h"

NS_ASSUME_NONNULL_BEGIN
@interface SJIJKMediaPlaybackController ()

@end

@implementation SJIJKMediaPlaybackController
@dynamic currentPlayer;

- (IJKFFOptions *)options {
    if ( _options == nil ) _options = IJKFFOptions.optionsByDefault;
    return _options;
}

- (void)playerWithMedia:(SJVideoPlayerURLAsset *)media completionHandler:(void (^)(id<SJMediaPlayer> _Nullable))completionHandler {
    SJIJKMediaPlayer *player = [SJIJKMediaPlayer.alloc initWithURL:self.media.mediaURL startPosition:self.media.startPosition options:self.options];
    player.pauseWhenAppDidEnterBackground = self.pauseWhenAppDidEnterBackground;
    if ( completionHandler ) completionHandler(player);
}

- (UIView<SJMediaPlayerView> *)playerViewWithPlayer:(SJIJKMediaPlayer *)player {
    return [SJIJKMediaPlayerLayerView.alloc initWithPlayer:player];
}

- (void)setPauseWhenAppDidEnterBackground:(BOOL)pauseWhenAppDidEnterBackground {
    [super pauseWhenAppDidEnterBackground];
    self.currentPlayer.pauseWhenAppDidEnterBackground = pauseWhenAppDidEnterBackground;
}

#pragma mark -

- (void)setMinBufferedDuration:(NSTimeInterval)minBufferedDuration {
#ifdef DEBUG
    NSLog(@"%d \t %s \t 未实现该方法!", (int)__LINE__, __func__);
#endif
}

- (NSTimeInterval)durationWatched {
#ifdef DEBUG
    NSLog(@"%d \t %s \t 未实现该方法!", (int)__LINE__, __func__);
#endif
    return 0;
}

- (SJPlaybackType)playbackType {
#ifdef DEBUG
    NSLog(@"%d \t %s \t 未实现该方法!", (int)__LINE__, __func__);
#endif
    return SJPlaybackTypeUnknown;
}
@end
NS_ASSUME_NONNULL_END
