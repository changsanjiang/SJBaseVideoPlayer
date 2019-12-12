//
//  SJAliMediaPlayer.h
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2019/11/7.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AliyunPlayer/AVPSource.h>
#import <AliyunPlayer/AVPDef.h>

#import "SJVideoPlayerPlaybackControllerDefines.h"

NS_ASSUME_NONNULL_BEGIN
extern NSNotificationName const SJAliMediaPlayerAssetStatusDidChangeNotification;
extern NSNotificationName const SJAliMediaPlayerTimeControlStatusDidChangeNotification;
extern NSNotificationName const SJAliMediaPlayerPresentationSizeDidChangeNotification;
extern NSNotificationName const SJAliMediaPlayerDidPlayToEndTimeNotification;
extern NSNotificationName const SJAliMediaPlayerReadyForDisplayNotification;
extern NSNotificationName const SJAliMediaPlayerDidReplayNotification;

@interface SJAliMediaPlayer : NSObject
- (instancetype)initWithSource:(__kindof AVPSource *)source specifyStartTime:(NSTimeInterval)time;
@property (nonatomic, readonly) NSTimeInterval specifyStartTime;
@property (nonatomic, strong, readonly) __kindof AVPSource *source;
@property (nonatomic, readonly, nullable) SJWaitingReason reasonForWaitingToPlay;
@property (nonatomic, readonly) SJPlaybackTimeControlStatus timeControlStatus;
@property (nonatomic, readonly) SJSeekingInfo seekingInfo;
@property (nonatomic, readonly) SJAssetStatus assetStatus;
@property (nonatomic, readonly) CGSize presentationSize;
@property (nonatomic, readonly) BOOL isReplayed;
@property (nonatomic, readonly) BOOL isPlayed;
@property (nonatomic, readonly) BOOL isPlayedToEndTime;
@property (nonatomic) SJVideoGravity videoGravity;
@property (nonatomic) float rate;
@property (nonatomic) float volume;
@property (nonatomic, getter=isMuted) BOOL muted;
@property (nonatomic, readonly, getter=isReadyForDisplay) BOOL readyForDisplay;
@property (nonatomic, strong, readonly) UIView *view;
@property (nonatomic) BOOL shouldAutoplay;

@property (nonatomic) AVPSeekMode seekMode;
- (void)seekToTime:(CMTime)time completionHandler:(nullable void (^)(BOOL finished))completionHandler;

@property (nonatomic, readonly) NSTimeInterval currentTime;
@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic, readonly) NSTimeInterval playableDuration;

- (void)play;
- (void)pause;

@property (nonatomic) BOOL pauseWhenAppDidEnterBackground;

- (void)replay;
- (void)report;

- (id)addTimeObserverWithCurrentTimeDidChangeExeBlock:(void (^)(NSTimeInterval time))block
                    playableDurationDidChangeExeBlock:(void (^)(NSTimeInterval time))block1
                            durationDidChangeExeBlock:(void (^)(NSTimeInterval time))block2;
- (void)removeTimeObserver:(id)observer;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end
NS_ASSUME_NONNULL_END
