//
//  SJAVMediaPlaybackDefines.h
//  Pods
//
//  Created by BlueDancer on 2019/4/9.
//

#ifndef SJAVMediaPlaybackDefines_h
#define SJAVMediaPlaybackDefines_h
#import <AVFoundation/AVFoundation.h>
#import "SJVideoPlayerPlayStatusDefines.h"
#import "SJPlayerBufferStatus.h"

NS_ASSUME_NONNULL_BEGIN
UIKIT_EXTERN NSNotificationName const SJAVMediaPlayerPlaybackStatusDidChangeNotification;
UIKIT_EXTERN NSNotificationName const SJAVMediaPlayerBufferStatusDidChangeNotification;
UIKIT_EXTERN NSNotificationName const SJAVMediaPlayerPlayDidToEndTimeNotification;

@protocol SJAVMediaPlayerProtocol <NSObject>
- (instancetype)initWithURL:(NSURL *)URL;
- (instancetype)initWithURL:(NSURL *)URL specifyStartTime:(NSTimeInterval)specifyStartTime;
- (instancetype)initWithAVAsset:(__kindof AVAsset *)asset specifyStartTime:(NSTimeInterval)specifyStartTime;

@property (nonatomic) float sj_playbackRate;
@property (nonatomic) float sj_playbackVolume;
@property (nonatomic, getter=isSJMuted) BOOL sj_muted;

// - status -
@property (nonatomic, readonly) SJVideoPlayerInactivityReason sj_inactivityReason;
@property (nonatomic, readonly) SJVideoPlayerPausedReason sj_pausedReason;
@property (nonatomic, readonly) SJVideoPlayerPlayStatus sj_playbackStatus;
@property (nonatomic, readonly) SJPlayerBufferStatus sj_bufferStatus;
- (NSTimeInterval)sj_getDuration;
- (NSTimeInterval)sj_getCurrentPlaybackTime;
- (NSError *_Nullable)sj_getError;

- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL))completionHandler;
- (void)seekToTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter completionHandler:(void (^)(BOOL))completionHandler;

- (void)play;
- (void)pause;
@end
NS_ASSUME_NONNULL_END
#endif /* SJAVMediaPlaybackDefines_h */
