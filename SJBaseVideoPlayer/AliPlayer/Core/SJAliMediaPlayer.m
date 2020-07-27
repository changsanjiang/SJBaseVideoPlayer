//
//  SJAliMediaPlayer.m
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2019/11/7.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

#import "SJAliMediaPlayer.h"
#import <AliyunPlayer/AliyunPlayer.h>

NS_ASSUME_NONNULL_BEGIN
@interface SJAliMediaPlayer ()<AVPDelegate>
@property (nonatomic) BOOL isPlaybackFinished;                      ///< 播放结束
@property (nonatomic, nullable) SJFinishedReason finishedReason;    ///< 播放结束的reason
@property (nonatomic) BOOL firstVideoFrameRendered;
@property (nonatomic, copy, nullable) void(^seekCompletionHandler)(BOOL);
@property (nonatomic) NSTimeInterval startPosition;
@property (nonatomic) BOOL needSeekToStartPosition;
@property (nonatomic, nullable) SJWaitingReason reasonForWaitingToPlay;
@property (nonatomic) SJPlaybackTimeControlStatus timeControlStatus;
@property (nonatomic) SJSeekingInfo seekingInfo;
@property (nonatomic) SJAssetStatus assetStatus;
@property (nonatomic) CGSize presentationSize;

@property (nonatomic, strong, nullable) AliPlayer *player;
@property (nonatomic) AVPStatus playerStatus;
@property (nonatomic) AVPEventType eventType;

@property (nonatomic) NSTimeInterval currentTime;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic) NSTimeInterval playableDuration;

@property (nonatomic, readonly) BOOL isPlayedToTrialEndPosition;
@end

@implementation SJAliMediaPlayer
@synthesize pauseWhenAppDidEnterBackground = _pauseWhenAppDidEnterBackground;
@synthesize playableDuration = _playableDuration;
@synthesize isPlayed = _isPlayed;
@synthesize isReplayed = _isReplayed;
@synthesize rate = _rate;
@synthesize volume = _volume;
@synthesize muted = _muted; 

- (instancetype)initWithSource:(__kindof AVPSource *)source config:(nullable AVPConfig *)config startPosition:(NSTimeInterval)time {
    self = [super init];
    if ( self ) {
        _source = source;
        _startPosition = time;
        _assetStatus = SJAssetStatusPreparing;
        _player = AliPlayer.alloc.init;
        _player.delegate = self;
        _player.playerView = UIView.new;
        _pauseWhenAppDidEnterBackground = YES;
        _seekMode = AVP_SEEKMODE_INACCURATE;
        _needSeekToStartPosition = time != 0;
        
        if ( config != nil )
            [_player setConfig:config];
        
        if      ( [source isKindOfClass:AVPUrlSource.class] ) {
            [_player setUrlSource:source];
        }
        else if ( [source isKindOfClass:AVPVidStsSource.class] ) {
            [_player setStsSource:source];
        }
        else if ( [source isKindOfClass:AVPVidMpsSource.class] ) {
            [_player setMpsSource:source];
        }
        else if ( [source isKindOfClass:AVPVidAuthSource.class] ) {
            [_player setAuthSource:source];
        }
        
        [_player prepare];

        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%d \t %s", (int)__LINE__, __func__);
#endif
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_player destroy];
}

- (UIView *)view {
    return self.player.playerView;
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
    [_player seekToTime:CMTimeGetSeconds(time) * 1000 seekMode:_seekMode];
    [self play];
}

- (void)play {
    _isPlayed = YES;
    
    if ( self.isPlaybackFinished ) {
        [self replay];
    }
    else {
        self.reasonForWaitingToPlay = SJWaitingWhileEvaluatingBufferingRateReason;
        self.timeControlStatus = SJPlaybackTimeControlStatusWaitingToPlay;

        [_player start];
    }
}
- (void)pause {
    self.reasonForWaitingToPlay = nil;
    self.timeControlStatus = SJPlaybackTimeControlStatusPaused;

    [_player pause];
}

- (void)replay {
    _isReplayed = YES;
    __weak typeof(self) _self = self;
    [self seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        if ( self.playerStatus != AVPStatusStarted ) [self play];
        [self _toEvaluating];
        [self _postNotification:SJMediaPlayerDidReplayNotification];
    }];
}
- (void)report {
    [self _postNotification:SJMediaPlayerAssetStatusDidChangeNotification];
    [self _postNotification:SJMediaPlayerTimeControlStatusDidChangeNotification];
    [self _postNotification:SJMediaPlayerDurationDidChangeNotification];
    [self _postNotification:SJMediaPlayerPlayableDurationDidChangeNotification];

}

- (nullable UIImage *)screenshot {
    return nil;
}

#pragma mark -

-(void)onPlayerEvent:(AliPlayer *)player eventType:(AVPEventType)eventType {
#ifdef SJDEBUG
    __auto_type toString = ^NSString *(AVPEventType event) {
        switch ( event ) {
            case AVPEventPrepareDone:
                return @"AVPEventPrepareDone";
            case AVPEventAutoPlayStart:
                return @"AVPEventAutoPlayStart";
            case AVPEventFirstRenderedStart:
                return @"AVPEventFirstRenderedStart";
            case AVPEventCompletion:
                return @"AVPEventCompletion";
            case AVPEventLoadingStart:
                return @"AVPEventLoadingStart";
            case AVPEventLoadingEnd:
                return @"AVPEventLoadingEnd";
            case AVPEventSeekEnd:
                return @"AVPEventSeekEnd";
            case AVPEventLoopingStart:
                return @"AVPEventLoopingStart";
        }
    };
    
    NSLog(@"eventType: %@", toString(eventType));
#endif
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.eventType = eventType;
        [self _toEvaluating];
    });
}

- (void)onError:(AliPlayer *)player errorModel:(AVPErrorModel *)errorModel {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.playerStatus = AVPStatusError;
        [self _toEvaluating];
    });
}

- (void)onVideoSizeChanged:(AliPlayer *)player width:(int)width height:(int)height rotation:(int)rotation {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.presentationSize = CGSizeMake(width, height);
    });
}

- (void)onCurrentPositionUpdate:(AliPlayer *)player position:(int64_t)position {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSTimeInterval time = 1.0 * position / 1000;
        self.currentTime = time;
        if ( self.isPlayedToTrialEndPosition ) {
            [self _didPlayToTrialEndPosition];
        }
    });
}

- (void)onBufferedPositionUpdate:(AliPlayer *)player position:(int64_t)position {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSTimeInterval time = 1.0 * position / 1000;
        self.playableDuration = time;
    });
}

- (void)onPlayerStatusChanged:(AliPlayer *)player oldStatus:(AVPStatus)oldStatus newStatus:(AVPStatus)newStatus {
    
#ifdef SJDEBUG
    __auto_type toString = ^NSString *(AVPStatus status) {
        switch ( status ) {
            case AVPStatusIdle:
                return @"AVPStatusIdle";
            case AVPStatusInitialzed:
                return @"AVPStatusInitialzed";
            case AVPStatusPrepared:
                return @"AVPStatusPrepared";
            case AVPStatusStarted:
                return @"AVPStatusStarted";
            case AVPStatusPaused:
                return @"AVPStatusPaused";
            case AVPStatusStopped:
                return @"AVPStatusStopped";
            case AVPStatusCompletion:
                return @"AVPStatusCompletion";
            case AVPStatusError:
                return @"AVPStatusError";
        }
    };
    
    NSLog(@"oldStatus: %@ \t newStatus: %@", toString(oldStatus), toString(newStatus));
#endif

    dispatch_async(dispatch_get_main_queue(), ^{
        self.playerStatus = newStatus;
        [self _toEvaluating];
    });
}

#pragma mark -

- (void)_postNotification:(NSNotificationName)name {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSNotificationCenter.defaultCenter postNotificationName:name object:self];
    });
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

- (void)_toEvaluating {
    SJAssetStatus status = self.assetStatus;
    if ( self.playerStatus == AVPStatusPrepared ) {
        status = SJAssetStatusReadyToPlay;
    }
    else if ( self.playerStatus == AVPStatusError ) {
        status = SJAssetStatusFailed;
    }
    
    if ( status != self.assetStatus ) {
        self.assetStatus = status;
        
        if ( status == SJAssetStatusReadyToPlay ) {
            if ( self.needSeekToStartPosition ) {
                self.needSeekToStartPosition = NO;
                [self seekToTime:CMTimeMakeWithSeconds(self.startPosition, NSEC_PER_SEC) completionHandler:nil];
            }
        }
    }
    
    if ( status == SJAssetStatusReadyToPlay && self.duration == 0 ) {
        self.duration = self.player.duration * 1.0 / 1000;
    }
    
    if ( status == SJAssetStatusFailed )
        return;
    
    if ( self.eventType == AVPEventSeekEnd && self.seekingInfo.isSeeking ) {
        [self _didEndSeeking:YES];
    }
    else if ( self.isPlayedToTrialEndPosition ) {
        [self _didPlayToTrialEndPosition];
        return;
    }
    else if ( self.playerStatus == AVPStatusCompletion ) {
        [self _didPlayToEndPositoion];
        return;
    }
    
    if ( self.eventType == AVPEventFirstRenderedStart ) {
        self.firstVideoFrameRendered = YES;
    }
    
    if ( self.timeControlStatus != SJPlaybackTimeControlStatusPaused ) {
        SJPlaybackTimeControlStatus status = self.timeControlStatus;
        SJWaitingReason _Nullable reason = self.reasonForWaitingToPlay;
        if ( self.eventType == AVPEventLoadingStart ) {
            reason = SJWaitingToMinimizeStallsReason;
            status = SJPlaybackTimeControlStatusWaitingToPlay;
        }
        else if ( self.eventType == AVPEventLoadingEnd ) {
            reason = nil;
            status = SJPlaybackTimeControlStatusPlaying;
        }
        
        if ( status != self.timeControlStatus || reason != self.reasonForWaitingToPlay ) {
            self.reasonForWaitingToPlay = reason;
            self.timeControlStatus = status;
        }
    }
}

#pragma mark -

- (void)setAssetStatus:(SJAssetStatus)assetStatus {
    _assetStatus = assetStatus;

#ifdef SJDEBUG
    switch ( assetStatus ) {
        case SJAssetStatusUnknown:
            printf("SJAliMediaPlayer.assetStatus.Unknown\n");
            break;
        case SJAssetStatusPreparing:
            printf("SJAliMediaPlayer.assetStatus.Preparing\n");
            break;
        case SJAssetStatusReadyToPlay:
            printf("SJAliMediaPlayer.assetStatus.ReadyToPlay\n");
            break;
        case SJAssetStatusFailed:
            printf("SJAliMediaPlayer.assetStatus.Failed\n");
            break;
    }
#endif
    
    [self _postNotification:SJMediaPlayerAssetStatusDidChangeNotification];
}

- (void)setTimeControlStatus:(SJPlaybackTimeControlStatus)timeControlStatus {
    _timeControlStatus = timeControlStatus;

#ifdef SJDEBUG
    switch ( timeControlStatus ) {
        case SJPlaybackTimeControlStatusPaused:
            printf("SJAliMediaPlayer.timeControlStatus.Pause\n");
            break;
        case SJPlaybackTimeControlStatusWaitingToPlay:
            printf("SJAliMediaPlayer.timeControlStatus.WaitingToPlay.reason(%s)\n", _reasonForWaitingToPlay.UTF8String);
            break;
        case SJPlaybackTimeControlStatusPlaying:
            printf("SJAliMediaPlayer.timeControlStatus.Playing\n");
            break;
    }
#endif
    
    [self _postNotification:SJMediaPlayerTimeControlStatusDidChangeNotification];
}

- (void)setDuration:(NSTimeInterval)duration {
    _duration = duration;
    [self _postNotification:SJMediaPlayerDurationDidChangeNotification];
}

- (void)setPlayableDuration:(NSTimeInterval)playableDuration {
    _playableDuration = playableDuration;
    [self _postNotification:SJMediaPlayerPlayableDurationDidChangeNotification];
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

- (void)setScalingMode:(AVPScalingMode)scalingMode {
    _player.scalingMode = scalingMode;
}

- (AVPScalingMode)scalingMode {
    return _player.scalingMode;
}

- (void)setPresentationSize:(CGSize)presentationSize {
    _presentationSize = presentationSize;
    [self _postNotification:SJMediaPlayerPresentationSizeDidChangeNotification];
}

- (void)setRate:(float)rate {
    _rate = rate;
    _player.rate = rate;
}

- (void)setVolume:(float)volume {
    _volume = volume;
    _player.volume = volume;
}

- (void)setMuted:(BOOL)muted {
    _muted = muted;
    _player.muted = muted;
}

- (NSTimeInterval)playableDuration {
    if ( _trialEndPosition != 0 && _playableDuration >= _trialEndPosition ) {
        return _trialEndPosition;
    }
    return _playableDuration;
}

- (NSTimeInterval)currentTime {
    if ( _isPlaybackFinished ) {
        if ( _finishedReason == SJFinishedReasonToEndTimePosition )
            return _duration;
        else if ( _finishedReason == SJFinishedReasonToTrialEndPosition )
            return _trialEndPosition;
    }
    return _seekingInfo.isSeeking ? CMTimeGetSeconds(_seekingInfo.time) : _currentTime;
}

- (void)applicationDidEnterBackground {
    if ( self.pauseWhenAppDidEnterBackground ) [self pause];
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
@end
NS_ASSUME_NONNULL_END
