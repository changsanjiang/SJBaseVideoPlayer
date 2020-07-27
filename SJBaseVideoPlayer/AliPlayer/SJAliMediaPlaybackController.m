//
//  SJAliMediaPlaybackController.m
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2019/11/7.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

#import "SJAliMediaPlaybackController.h"
#import "SJAliMediaPlayer.h"
#import "SJAliMediaPlayerLayerView.h"

#if __has_include(<SJUIKit/SJRunLoopTaskQueue.h>)
#import <SJUIKit/SJRunLoopTaskQueue.h>
#else
#import "SJRunLoopTaskQueue.h"
#endif

NS_ASSUME_NONNULL_BEGIN
@interface SJAliMediaPlaybackController ()

@end

@implementation SJAliMediaPlaybackController
@dynamic currentPlayer;
- (instancetype)init {
    self = [super init];
    if ( self ) {
        _seekMode = AVP_SEEKMODE_INACCURATE;
    }
    return self;
}

- (void)playerWithMedia:(SJVideoPlayerURLAsset *)media completionHandler:(void (^)(id<SJMediaPlayer> _Nullable))completionHandler {
    if ( media.source != nil ) {
        __weak typeof(self) _self = self;
        SJRunLoopTaskQueue.main.enqueue(^{
            __strong typeof(_self) self = _self;
            if ( !self ) return;
            SJAliMediaPlayer *player = [SJAliMediaPlayer.alloc initWithSource:media.source config:media.avpConfig startPosition:media.startPosition];
            player.seekMode = self.seekMode;
            player.pauseWhenAppDidEnterBackground = self.pauseWhenAppDidEnterBackground;
            if ( completionHandler ) completionHandler(player);
        });
    }
}

- (UIView<SJMediaPlayerView> *)playerViewWithPlayer:(id<SJMediaPlayer>)player {
    return [SJAliMediaPlayerLayerView.alloc initWithPlayer:player];
}

- (void)setPauseWhenAppDidEnterBackground:(BOOL)pauseWhenAppDidEnterBackground {
    [super setPauseWhenAppDidEnterBackground:pauseWhenAppDidEnterBackground];
}

- (void)setSeekMode:(AVPSeekMode)seekMode {
    _seekMode = seekMode;
    self.currentPlayer.seekMode = seekMode;
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
