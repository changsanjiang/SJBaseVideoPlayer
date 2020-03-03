//
//  SJPLMediaPlayer.m
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2020/2/20.
//  Copyright © 2020 changsanjiang. All rights reserved.
//

#import "SJPLMediaPlayer.h"
#import "NSTimer+SJAssetAdd.h"

NS_ASSUME_NONNULL_BEGIN
@interface SJPLMediaPlayer ()<PLPlayerDelegate>
@property (nonatomic, strong, readonly) PLPlayer *plPlayer;
@property (nonatomic, nullable) SJWaitingReason reasonForWaitingToPlay;
@property (nonatomic) SJPlaybackTimeControlStatus timeControlStatus;
@property (nonatomic) SJAssetStatus assetStatus;
@property (nonatomic) SJSeekingInfo seekingInfo;
@property (nonatomic) BOOL isReplayed; ///< 是否调用过`replay`方法
@property (nonatomic) BOOL isPlayed; ///< 是否调用过`play`方法
@property (nonatomic) NSTimeInterval playableDuration;
@property (nonatomic) BOOL firstVideoFrameRendered;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic, copy, nullable) void (^seekCompletionHandler)(BOOL);

@property (nonatomic) BOOL isPlaybackFinished;                        ///< 播放结束
@property (nonatomic, nullable) SJFinishedReason finishedReason;      ///< 播放结束的reason
@property (nonatomic, strong, nullable) NSTimer *refreshTimer;
@property (nonatomic, readonly) BOOL isPlayedToTrialEndPosition;
@end

@implementation SJPLMediaPlayer
@synthesize playableDuration = _playableDuration;
- (instancetype)initWithURL:(NSURL *)URL options:(PLPlayerOption *)options startPosition:(NSTimeInterval)startPosition {
    return [self initWithURL:URL options:options startPosition:startPosition playbackType:SJPlaybackTypeUnknown];
}

- (instancetype)initWithLiveURL:(NSURL *)URL options:(PLPlayerOption *)options {
    return [self initWithURL:URL options:options startPosition:0 playbackType:SJPlaybackTypeLIVE];
}

- (instancetype)initWithURL:(NSURL *)URL options:(PLPlayerOption *)options startPosition:(NSTimeInterval)startPosition playbackType:(SJPlaybackType)type {
    self = [super init];
    if ( self ) {
        _URL = URL;
        _startPosition = startPosition;
        _assetStatus = SJAssetStatusPreparing;
        _playbackType = type;
        
        _plPlayer = [PLPlayer playerWithURL:URL option:options];
        if ( startPosition != 0 ) [_plPlayer preStartPosTime:CMTimeMakeWithSeconds(startPosition, NSEC_PER_SEC)];
        _plPlayer.delegateQueue = dispatch_get_main_queue();
        _plPlayer.delegate = self;
        [_plPlayer play];
    }
    return self;
}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%d \t %s", (int)__LINE__, __func__);
#endif
    PLPlayer *player = _plPlayer;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [player stop];
    });
}

#pragma mark -

- (CGSize)presentationSize {
    return CGSizeMake(_plPlayer.width, _plPlayer.height);
}

- (void)setIsPlaybackFinished:(BOOL)isPlaybackFinished {
    if ( isPlaybackFinished != _isPlaybackFinished ) {
        if ( !isPlaybackFinished ) _finishedReason = nil;
        _isPlaybackFinished = isPlaybackFinished;
        if ( isPlaybackFinished ) {
            [self _postNotification:SJMediaPlayerPlaybackDidFinishNotification];
        }
    }
}

- (void)setTrialEndPosition:(NSTimeInterval)trialEndPosition {
    if ( trialEndPosition != _trialEndPosition ) {
        _trialEndPosition = trialEndPosition;
        [self _refreshOrStop];
    }
}

- (void)setAutoReconnectEnable:(BOOL)autoReconnectEnable {
    _plPlayer.autoReconnectEnable = autoReconnectEnable;
}
- (BOOL)isAutoReconnectEnable {
    return _plPlayer.isAutoReconnectEnable;
}

- (void)setPauseWhenAppDidEnterBackground:(BOOL)pauseWhenAppDidEnterBackground {
    [_plPlayer setBackgroundPlayEnable:!pauseWhenAppDidEnterBackground];
}

- (BOOL)pauseWhenAppDidEnterBackground {
    return !_plPlayer.isBackgroundPlayEnable;
}

- (void)setRate:(float)rate {
    _plPlayer.playSpeed = rate;
}

- (float)rate {
    return _plPlayer.playSpeed;
}

- (void)setVolume:(float)volume {
    [_plPlayer setVolume:volume];
}

- (float)volume {
    return _plPlayer.getVolume;
}

- (void)setMuted:(BOOL)muted {
    _plPlayer.mute = muted;
}

- (BOOL)isMuted {
    return _plPlayer.isMute;
}

- (void)seekToTime:(CMTime)time completionHandler:(void (^_Nullable)(BOOL))completionHandler {
    if ( self.assetStatus != SJAssetStatusReadyToPlay ) {
        if ( completionHandler ) completionHandler(NO);
        return;
    }
    
    if ( self.seekingInfo.isSeeking ) {
        [self _didEndSeeking:NO];
    }
    
    time = [self _adjustSeekTimeIfNeeded:time];
    
    _seekCompletionHandler = completionHandler;
    [self _willSeeking:time];
    [_plPlayer seekTo:time];
}

- (NSTimeInterval)currentTime {
    if ( _isPlaybackFinished ) {
        if ( _finishedReason == SJFinishedReasonToEndTimePosition )
            return _duration;
        else if ( _finishedReason == SJFinishedReasonToTrialEndPosition )
            return _trialEndPosition;
    }
    return CMTimeGetSeconds( _seekingInfo.isSeeking ? _seekingInfo.time : _plPlayer.currentTime);
}

- (void)setDuration:(NSTimeInterval)duration {
    _duration = duration;
    [self _postNotification:SJMediaPlayerDurationDidChangeNotification];
}

- (void)setPlayableDuration:(NSTimeInterval)playableDuration {
    _playableDuration = playableDuration;
    [self _postNotification:SJMediaPlayerPlayableDurationDidChangeNotification];
}

- (NSTimeInterval)playableDuration {
    if ( _trialEndPosition != 0 && _playableDuration >= _trialEndPosition ) {
        return _trialEndPosition;
    }
    return _playableDuration;
}

- (void)setAssetStatus:(SJAssetStatus)assetStatus {
#ifdef SJDEBUG
    switch ( assetStatus ) {
        case SJAssetStatusUnknown:
            NSLog(@"SJAssetStatusUnknown");
            break;
        case SJAssetStatusPreparing:
            NSLog(@"SJAssetStatusPreparing");
            break;
        case SJAssetStatusReadyToPlay:
            NSLog(@"SJAssetStatusReadyToPlay %lf - %lf - %lf", self.playableDuration, self.currentTime, self.duration);
            break;
        case SJAssetStatusFailed:
            NSLog(@"SJAssetStatusFailed");
            break;
    }
#endif

    _assetStatus = assetStatus;
    [self _postNotification:SJMediaPlayerAssetStatusDidChangeNotification];
}

- (void)setTimeControlStatus:(SJPlaybackTimeControlStatus)timeControlStatus {
    if ( timeControlStatus == SJPlaybackTimeControlStatusPaused ) _reasonForWaitingToPlay = nil;
    _timeControlStatus = timeControlStatus;
    [self _refreshOrStop];
    [self _postNotification:SJMediaPlayerTimeControlStatusDidChangeNotification];
}

- (void)play {
    _isPlayed = YES;
    
    if ( self.isPlaybackFinished ) {
        [self replay];
    }
    else {
        self.reasonForWaitingToPlay = SJWaitingWhileEvaluatingBufferingRateReason;
        self.timeControlStatus = SJPlaybackTimeControlStatusWaitingToPlay;

        [_plPlayer resume];
        [self _toEvaluating];
    }
}

- (void)pause {
    self.reasonForWaitingToPlay = nil;
    self.timeControlStatus = SJPlaybackTimeControlStatusPaused;

    [_plPlayer pause];
}

- (void)replay {
    _isReplayed = YES;
    __weak typeof(self) _self = self;
    [self seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        [self play];
        [self _toEvaluating];
        [self _postNotification:SJMediaPlayerDidReplayNotification];
    }];
}

- (void)report {
    [self _postNotification:SJMediaPlayerAssetStatusDidChangeNotification];
    [self _postNotification:SJMediaPlayerTimeControlStatusDidChangeNotification];
    [self _postNotification:SJMediaPlayerDurationDidChangeNotification];
    [self _postNotification:SJMediaPlayerPlayableDurationDidChangeNotification];
    [self _postNotification:SJMediaPlayerPlaybackTypeDidChangeNotification];
}

- (nullable UIImage *)screenshot {
    return nil;
}

- (UIView *)view {
    return _plPlayer.playerView;
}

#pragma mark -

/**
 告知代理对象 PLPlayer 即将开始进入后台播放任务
 
 @param player 调用该代理方法的 PLPlayer 对象
 
 @since v1.0.0
 */
- (void)playerWillBeginBackgroundTask:(nonnull PLPlayer *)player {
    player.enableRender = NO;
}

/**
 告知代理对象 PLPlayer 即将结束后台播放状态任务
 
 @param player 调用该方法的 PLPlayer 对象
 
 @since v2.1.1
 */
- (void)playerWillEndBackgroundTask:(nonnull PLPlayer *)player {
    player.enableRender = YES;
}

/**
 告知代理对象播放器状态变更
 
 @param player 调用该方法的 PLPlayer 对象
 @param state  变更之后的 PLPlayer 状态
 
 @since v1.0.0
 */
- (void)player:(nonnull PLPlayer *)player statusDidChange:(PLPlayerStatus)state {
#ifdef SJDEBUG
    switch ( state ) {
        case PLPlayerStatusUnknow:
            NSLog(@"PLPlayerStatusUnknow");
            break;
        case PLPlayerStatusPreparing:
            NSLog(@"PLPlayerStatusPreparing");
            break;
        case PLPlayerStatusReady:
            NSLog(@"PLPlayerStatusReady");
            break;
        case PLPlayerStatusOpen:
            NSLog(@"PLPlayerStatusOpen");
            break;
        case PLPlayerStatusCaching:
            NSLog(@"PLPlayerStatusCaching");
            break;
        case PLPlayerStatusPlaying:
            NSLog(@"PLPlayerStatusPlaying");
            break;
        case PLPlayerStatusPaused:
            NSLog(@"PLPlayerStatusPaused");
            break;
        case PLPlayerStatusStopped:
            NSLog(@"PLPlayerStatusStopped");
            break;
        case PLPlayerStatusError:
            NSLog(@"PLPlayerStatusError");
            break;
        case PLPlayerStateAutoReconnecting:
            NSLog(@"PLPlayerStateAutoReconnecting");
            break;
        case PLPlayerStatusCompleted:
            NSLog(@"PLPlayerStatusCompleted");
            break;
    }
#endif
    [self _toEvaluating];
}

/**
 告知代理对象播放器因错误停止播放
 
 @param player 调用该方法的 PLPlayer 对象
 @param error  携带播放器停止播放错误信息的 NSError 对象
 
 @since v1.0.0
 */
- (void)player:(nonnull PLPlayer *)player stoppedWithError:(nullable NSError *)error {
#ifdef DEBUG
    NSLog(@"%d \t %s \t %@", (int)__LINE__, __func__, error);
#endif
    [self _toEvaluating];
}

/**
 点播已缓冲区域
 
 @param player 调用该方法的 PLPlayer 对象
 @param timeRange  CMTime , 表示从0时开始至当前缓冲区域，单位秒。
 
 @warning 仅对点播有效
 
 @since v2.4.1
 */
- (void)player:(nonnull PLPlayer *)player loadedTimeRange:(CMTime)timeRange {
    self.playableDuration = CMTimeGetSeconds(timeRange);
}
 
/**
 音视频渲染首帧回调通知
 
 @param player 调用该方法的 PLPlayer 对象
 @param firstRenderType 音视频首帧回调通知类型
 
 @since v3.2.1
 */
- (void)player:(nonnull PLPlayer *)player firstRender:(PLPlayerFirstRenderType)firstRenderType {
    if ( firstRenderType == PLPlayerFirstRenderTypeVideo ) {
        self.firstVideoFrameRendered = YES;
    }

    [self _toEvaluating];
}

/**
 视频宽高数据回调通知

 @param player 调用该方法的 PLPlayer 对象
 @param width 视频流宽
 @param height 视频流高
 
 @since v3.3.0
 */
- (void)player:(nonnull PLPlayer *)player width:(int)width height:(int)height {
    [self _postNotification:SJMediaPlayerPresentationSizeDidChangeNotification];
}

/**
 seekTo 完成的回调通知
 
 @param player 调用该方法的 PLPlayer 对象
 
 @since v3.3.0
 */
- (void)player:(nonnull PLPlayer *)player seekToCompleted:(BOOL)isCompleted {
    [self _didEndSeeking:isCompleted];
}

#pragma mark -

- (void)_postNotification:(NSNotificationName)name {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSNotificationCenter.defaultCenter postNotificationName:name object:self];
    });
}

- (void)_toEvaluating {
    SJAssetStatus assetStatus = self.assetStatus;
    
    if ( _plPlayer.status == PLPlayerStatusReady || _plPlayer.status == PLPlayerStatusPlaying ) {
        assetStatus = SJAssetStatusReadyToPlay;
    }
    else if ( _plPlayer.status == PLPlayerStatusError ) {
        assetStatus = SJAssetStatusFailed;
    }
    
    if ( assetStatus != _assetStatus ) {
        self.assetStatus = assetStatus;
    }
    
    if ( self.duration == 0 ) {
        self.duration = CMTimeGetSeconds(_plPlayer.totalDuration);
    }
    
    if ( self.isPlayedToTrialEndPosition ) {
        [self _didPlayToTrialEndPosition];
        return;
    }
    
    if ( _plPlayer.status == PLPlayerStatusPlaying && self.timeControlStatus == SJPlaybackTimeControlStatusPaused ) {
#ifdef DEBUG
        NSLog(@"%d \t %s", (int)__LINE__, __func__);
#endif
        [_plPlayer pause];
    }
    
    __auto_type reasonForWaitingToPlay = self.reasonForWaitingToPlay;
    __auto_type timeControlStatus = self.timeControlStatus;
    
    if ( assetStatus == SJAssetStatusFailed ) {
        timeControlStatus = SJPlaybackTimeControlStatusPaused;
    }
    
    if ( self.timeControlStatus == SJPlaybackTimeControlStatusPaused ) {
        return;
    }
    
    switch ( _plPlayer.status ) {
        case PLPlayerStatusUnknow:
        case PLPlayerStatusOpen:
        case PLPlayerStatusError:
        case PLPlayerStateAutoReconnecting:
        case PLPlayerStatusPreparing:
        case PLPlayerStatusReady:
        case PLPlayerStatusStopped:
            break;
        case PLPlayerStatusPaused: {
            if ( timeControlStatus != SJPlaybackTimeControlStatusPaused ) {
#ifdef DEBUG
                NSLog(@"%d \t %s", (int)__LINE__, __func__);
#endif
                [_plPlayer resume];
            }
        }
            break;
        case PLPlayerStatusCaching: {
            reasonForWaitingToPlay = SJWaitingToMinimizeStallsReason;
            timeControlStatus = SJPlaybackTimeControlStatusWaitingToPlay;
        }
            break;
        case PLPlayerStatusPlaying: {
            reasonForWaitingToPlay = nil;
            timeControlStatus = SJPlaybackTimeControlStatusPlaying;
        }
            break;
        case PLPlayerStatusCompleted: {
            reasonForWaitingToPlay = nil;
            timeControlStatus = SJPlaybackTimeControlStatusPaused;
            self.finishedReason = SJFinishedReasonToEndTimePosition;
            self.isPlaybackFinished = YES;
        }
            break;
    }
    
    if ( reasonForWaitingToPlay != _reasonForWaitingToPlay || timeControlStatus != _timeControlStatus ) {
        self.reasonForWaitingToPlay = reasonForWaitingToPlay;
        self.timeControlStatus = timeControlStatus;
    }
}

- (void)_willSeeking:(CMTime)time {
    self.isPlaybackFinished = NO;
    _seekingInfo.time = time;
    _seekingInfo.isSeeking = YES;
}

- (void)_didEndSeeking:(BOOL)finished {
    _seekingInfo.time = kCMTimeZero;
    _seekingInfo.isSeeking = NO;
    if ( _seekCompletionHandler ) _seekCompletionHandler(finished);
    _seekCompletionHandler = nil;
}

- (BOOL)isPlayedToTrialEndPosition {
    return self.trialEndPosition != 0 && self.currentTime >= self.trialEndPosition;
}

- (void)_didPlayToTrialEndPosition {
    if ( self.finishedReason != SJFinishedReasonToTrialEndPosition ) {
        self.finishedReason = SJFinishedReasonToTrialEndPosition;
        self.isPlaybackFinished = YES;
        [self pause];
    }
}

- (void)_didPlayToEndPositoion {
    if ( self.finishedReason != SJFinishedReasonToEndTimePosition ) {
        self.finishedReason = SJFinishedReasonToEndTimePosition;
        self.isPlaybackFinished = YES;
        self.reasonForWaitingToPlay = nil;
        self.timeControlStatus = SJPlaybackTimeControlStatusPaused;
    }
}

- (CMTime)_adjustSeekTimeIfNeeded:(CMTime)time {
    if ( _trialEndPosition != 0 && CMTimeGetSeconds(time) >= _trialEndPosition ) {
        time = CMTimeMakeWithSeconds(_trialEndPosition * 0.98, NSEC_PER_SEC);
    }
    return time;
}

- (void)_refreshOrStop {
    if ( _trialEndPosition == 0 || _timeControlStatus == SJPlaybackTimeControlStatusPaused ) {
        if ( _refreshTimer != nil ) {
            [_refreshTimer invalidate];
            _refreshTimer = nil;
        }
    }
    else {
        if ( _refreshTimer == nil ) {
            __weak typeof(self) _self = self;
            _refreshTimer = [NSTimer sj_timerWithTimeInterval:0.5 repeats:YES usingBlock:^(NSTimer * _Nonnull timer) {
                __strong typeof(_self) self = _self;
                if ( !self ) return;
                if ( self.isPlayedToTrialEndPosition ) {
                    [self _didPlayToTrialEndPosition];
                }
            }];
            [_refreshTimer sj_fire];
            [NSRunLoop.mainRunLoop addTimer:_refreshTimer forMode:NSRunLoopCommonModes];
        }
    }
    
}

@end
NS_ASSUME_NONNULL_END
