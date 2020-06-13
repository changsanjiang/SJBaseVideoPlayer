//
//  SJIJKMediaPlaybackController.m
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2019/10/12.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

#import "SJIJKMediaPlaybackController.h"
#import "SJIJKMediaPlayerLayerView.h"

#if __has_include(<SJUIKit/SJRunLoopTaskQueue.h>)
#import <SJUIKit/SJRunLoopTaskQueue.h>
#else
#import "SJRunLoopTaskQueue.h"
#endif

NS_ASSUME_NONNULL_BEGIN
@interface SJIJKMediaPlaybackController ()

@end

@implementation SJIJKMediaPlaybackController
@dynamic currentPlayer;

- (void)dealloc {
    [self.currentPlayer stop];
}

- (void)stop {
    [self.currentPlayer stop];
    [super stop];
}

- (IJKFFOptions *)options {
    if ( _options == nil ) _options = IJKFFOptions.optionsByDefault;
    return _options;
}

- (void)playerWithMedia:(SJVideoPlayerURLAsset *)media completionHandler:(void (^)(id<SJMediaPlayer> _Nullable))completionHandler {
    __weak typeof(self) _self = self;
    SJRunLoopTaskQueue.main.enqueue(^{
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        SJIJKMediaPlayer *player = [SJIJKMediaPlayer.alloc initWithURL:media.mediaURL startPosition:media.startPosition options:self.options];
        player.pauseWhenAppDidEnterBackground = self.pauseWhenAppDidEnterBackground;
        if ( completionHandler ) completionHandler(player);
    });
}

- (UIView<SJMediaPlayerView> *)playerViewWithPlayer:(SJIJKMediaPlayer *)player {
    return [SJIJKMediaPlayerLayerView.alloc initWithPlayer:player];
}

- (void)setPauseWhenAppDidEnterBackground:(BOOL)pauseWhenAppDidEnterBackground {
    [super setPauseWhenAppDidEnterBackground:pauseWhenAppDidEnterBackground];
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
