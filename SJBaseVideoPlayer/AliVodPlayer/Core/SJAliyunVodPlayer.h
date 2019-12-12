//
//  SJAliyunVodPlayer.h
//  Demo
//
//  Created by BlueDancer on 2019/11/13.
//  Copyright © 2019 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJVideoPlayerPlaybackControllerDefines.h"
#import "SJAliyunVodModel.h"

NS_ASSUME_NONNULL_BEGIN
extern NSNotificationName const SJAliyunVodPlayerAssetStatusDidChangeNotification;
extern NSNotificationName const SJAliyunVodPlayerTimeControlStatusDidChangeNotification;
extern NSNotificationName const SJAliyunVodPlayerPresentationSizeDidChangeNotification;
extern NSNotificationName const SJAliyunVodPlayerDidPlayToEndTimeNotification;
extern NSNotificationName const SJAliyunVodPlayerReadyForDisplayNotification;
extern NSNotificationName const SJAliyunVodPlayerDidReplayNotification;

@interface SJAliyunVodPlayer : NSObject
- (instancetype)initWithMedia:(__kindof SJAliyunVodModel *)media specifyStartTime:(NSTimeInterval)time;
@property (nonatomic, strong, readonly) SJAliyunVodModel *media;
@property (nonatomic, readonly) NSTimeInterval specifyStartTime;
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
