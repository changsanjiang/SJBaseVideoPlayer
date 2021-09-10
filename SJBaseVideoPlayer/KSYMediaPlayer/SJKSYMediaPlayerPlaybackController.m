//
//  SJKSYMediaPlayerPlaybackController.m
//  SJBaseVideoPlayer
//
//  Created by 畅三江 on 2021/9/9.
//

#import "SJKSYMediaPlayerPlaybackController.h"
#import "SJKSYMediaPlayer.h"
#import "SJKSYMediaPlayerView.h"
#if __has_include(<SJUIKit/SJRunLoopTaskQueue.h>)
#import <SJUIKit/SJRunLoopTaskQueue.h>
#else
#import "SJRunLoopTaskQueue.h"
#endif

@interface SJKSYMediaPlayerPlaybackController ()

@end

@implementation SJKSYMediaPlayerPlaybackController
@dynamic currentPlayer;

- (void)dealloc {
    [self.currentPlayer stop];
}

- (void)stop {
    [self.currentPlayer stop];
    [super stop];
}

- (void)playerWithMedia:(SJVideoPlayerURLAsset *)media completionHandler:(void (^)(id<SJMediaPlayer> _Nullable))completionHandler {
    __weak typeof(self) _self = self;
    SJRunLoopTaskQueue.main.enqueue(^{
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        SJKSYMediaPlayer *player = [SJKSYMediaPlayer.alloc initWithURL:media.mediaURL startPosition:media.startPosition options:nil];
        if ( completionHandler ) completionHandler(player);
    });
}

- (UIView<SJMediaPlayerView> *)playerViewWithPlayer:(SJKSYMediaPlayer *)player {
    return [SJKSYMediaPlayerView.alloc initWithPlayer:player];
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
