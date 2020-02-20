//
//  SJAliyunVodPlaybackController.m
//  Demo
//
//  Created by BlueDancer on 2019/11/13.
//  Copyright © 2019 SanJiang. All rights reserved.
//

#import "SJAliyunVodPlaybackController.h"
#import "SJAliyunVodPlayerLayerView.h"

NS_ASSUME_NONNULL_BEGIN
@interface SJAliyunVodPlaybackController ()

@end

@implementation SJAliyunVodPlaybackController
@dynamic currentPlayer;

- (void)playerWithMedia:(SJVideoPlayerURLAsset *)media completionHandler:(void (^)(id<SJMediaPlayer> _Nullable))completionHandler {
    if ( media.aliyunMedia != nil ) {
        SJAliyunVodPlayer *player = [SJAliyunVodPlayer.alloc initWithMedia:self.media.aliyunMedia startPosition:self.media.startPosition];
        player.pauseWhenAppDidEnterBackground = self.pauseWhenAppDidEnterBackground;
        if ( completionHandler ) completionHandler(player);
    }
}

- (UIView<SJMediaPlayerView> *)playerViewWithPlayer:(id<SJMediaPlayer>)player {
    return [SJAliyunVodPlayerLayerView.alloc initWithPlayer:player];
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
