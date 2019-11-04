//
//  SJIJKMediaPlayer.h
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2019/10/12.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IJKMediaFrameworkWithSSL/IJKMediaFrameworkWithSSL.h>
#import "SJVideoPlayerPlaybackControllerDefines.h"
#import "SJAVMediaPlayer.h"

NS_ASSUME_NONNULL_BEGIN
extern NSNotificationName const SJIJKMediaPlayerAssetStatusDidChangeNotification;
extern NSNotificationName const SJIJKMediaPlayerTimeControlStatusDidChangeNotification;
extern NSNotificationName const SJIJKMediaPlayerPresentationSizeDidChangeNotification;
extern NSNotificationName const SJIJKMediaPlayerDidPlayToEndTimeNotification;
extern NSNotificationName const SJIJKMediaPlayerReadyForDisplayNotification;

typedef struct {
    BOOL isFinished;
    IJKMPMovieFinishReason reason;
} SJPlaybackFinishedInfo;

@interface SJIJKMediaPlayer : IJKFFMoviePlayerController
- (instancetype)initWithURL:(NSURL *)URL specifyStartTime:(NSTimeInterval)specifyStartTime options:(IJKFFOptions *)ops;
@property (nonatomic, readonly) NSTimeInterval specifyStartTime;
@property (nonatomic, readonly, strong) NSURL *URL;
@property (nonatomic, readonly, nullable) SJWaitingReason reasonForWaitingToPlay;
@property (nonatomic, readonly) SJPlaybackTimeControlStatus timeControlStatus;
@property (nonatomic, readonly) SJPlaybackFinishedInfo finishedInfo;
@property (nonatomic, readonly) SJSeekingInfo seekingInfo;
@property (nonatomic, readonly) SJAssetStatus assetStatus;
@property (nonatomic, readonly) CGSize presentationSize;
@property (nonatomic, readonly) BOOL isReplayed;
@property (nonatomic, readonly) BOOL isPlayed;
@property (nonatomic) SJVideoGravity videoGravity;
@property (nonatomic) float rate;
@property (nonatomic) float volume;
@property (nonatomic, getter=isMuted) BOOL muted;
@property (nonatomic, readonly, getter=isReadyForDisplay) BOOL readyForDisplay;

- (void)seekToTime:(CMTime)time completionHandler:(nullable void (^)(BOOL finished))completionHandler;
- (void)replay;
- (void)report;

- (id)addPeriodicTimeObserverForInterval:(CMTime)interval
            currentTimeDidChangeExeBlock:(void (^)(NSTimeInterval time))block
       playableDurationDidChangeExeBlock:(void (^)(NSTimeInterval time))block1
               durationDidChangeExeBlock:(void (^)(NSTimeInterval time))block2;
- (void)removeTimeObserver:(id)observer;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end
NS_ASSUME_NONNULL_END
