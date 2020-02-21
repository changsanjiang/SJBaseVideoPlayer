//
//  SJPLPlayerPlaybackController.m
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2020/2/20.
//  Copyright © 2020 changsanjiang. All rights reserved.
//

#import "SJPLPlayerPlaybackController.h"
#import "SJPLMediaPlayerLayerView.h"
#import "SJPLMediaPlayer.h"

#if __has_include(<SJUIKit/SJRunLoopTaskQueue.h>)
#import <SJUIKit/SJRunLoopTaskQueue.h>
#else
#import "SJRunLoopTaskQueue.h"
#endif

NS_ASSUME_NONNULL_BEGIN
@implementation SJPLPlayerPlaybackController
@dynamic currentPlayer;

- (instancetype)init {
    self = [super init];
    if ( self ) {
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_pl_playbackTypeDidChange:) name:SJMediaPlayerPlaybackTypeDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)playerWithMedia:(SJVideoPlayerURLAsset *)media completionHandler:(void (^)(id<SJMediaPlayer> _Nullable))completionHandler {
    __weak typeof(self) _self = self;
    SJRunLoopTaskQueue.main.enqueue(^{
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        SJPLMediaPlayer *player = nil;
        if ( media.mediaURL != nil ) {
            player = [SJPLMediaPlayer.alloc initWithURL:media.mediaURL options:media.pl_playerOptions startPosition:media.startPosition];
        }
        else if ( media.liveURL != nil ) {
            player = [SJPLMediaPlayer.alloc initWithLiveURL:media.liveURL options:media.pl_playerOptions];
        }
        else {
            return;
        }
        
        player.autoReconnectEnable = self.isAutoReconnectEnable;
        player.pauseWhenAppDidEnterBackground = self.pauseWhenAppDidEnterBackground;
        if ( completionHandler ) completionHandler(player);
    });
}

- (UIView<SJMediaPlayerView> *)playerViewWithPlayer:(id<SJMediaPlayer>)player {
    return [SJPLMediaPlayerLayerView.alloc initWithPlayer:player];
}

- (void)receivedApplicationWillResignActiveNotification {
    if ( self.pauseWhenAppDidEnterBackground )
        [self pause];
}

#pragma mark -

- (void)setAutoReconnectEnable:(BOOL)autoReconnectEnable {
    _autoReconnectEnable = autoReconnectEnable;
    self.currentPlayer.autoReconnectEnable = autoReconnectEnable;
}

- (void)setPauseWhenAppDidEnterBackground:(BOOL)pauseWhenAppDidEnterBackground {
    [super setPauseWhenAppDidEnterBackground:pauseWhenAppDidEnterBackground];
    self.currentPlayer.pauseWhenAppDidEnterBackground = pauseWhenAppDidEnterBackground;
}

- (SJPlaybackType)playbackType {
    return self.currentPlayer.playbackType;
}

#pragma mark -

- (void)_pl_playbackTypeDidChange:(NSNotification *)note {
    if ( [self.delegate respondsToSelector:@selector(playbackController:playbackTypeDidChange:)] ) {
        [self.delegate playbackController:self playbackTypeDidChange:self.playbackType];
    }
}
@end
NS_ASSUME_NONNULL_END
