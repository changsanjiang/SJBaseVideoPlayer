//
//  SJKSYMediaPlayer.m
//  SJBaseVideoPlayer
//
//  Created by 畅三江 on 2021/9/9.
//

#import "SJKSYMediaPlayer.h"
#import <KSYMediaPlayer/KSYMoviePlayerController.h>
#import "NSTimer+SJAssetAdd.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

NSErrorDomain const SJKSYMediaPlayerErrorDomain = @"SJKSYMediaPlayerErrorDomain";

typedef struct {
    BOOL isFinished;
    MPMovieFinishReason reason;
} SJKSYMediaPlaybackFinishedInfo;


@interface SJKSYMediaPlayer ()
@property (nonatomic, strong) NSURL *URL;
@property (nonatomic) NSTimeInterval startPosition;
@property (nonatomic) BOOL needsSeekToStartPosition;
@property (nonatomic, strong) KSYMoviePlayerController *player;
@property (nonatomic, strong, nullable) NSError *error;
@property (nonatomic) SJKSYMediaPlaybackFinishedInfo playbackFinishedInfo;
@property (nonatomic, nullable) SJWaitingReason reasonForWaitingToPlay;
@property (nonatomic) SJPlaybackTimeControlStatus timeControlStatus;
@property (nonatomic) SJAssetStatus assetStatus;
@property (nonatomic) SJSeekingInfo seekingInfo;
@property (nonatomic, copy, nullable) void(^seekCompletionHandler)(BOOL);
@property (nonatomic) CGSize presentationSize;
@property (nonatomic) BOOL isPreparedToPlay;
@property (nonatomic) BOOL isReplayed; ///< 是否调用过`replay`方法
@property (nonatomic) BOOL isPlayed; ///< 是否调用过`play`方法
@property (nonatomic) BOOL isPlaybackFinished;                        ///< 播放结束
@property (nonatomic, nullable) SJFinishedReason finishedReason;      ///< 播放结束的reason
@property (nonatomic) BOOL firstVideoFrameRendered;
@property (nonatomic, strong, nullable) NSTimer *refreshTimer;
@property (nonatomic) NSTimeInterval previousPlayableDuration;
@property (nonatomic, readonly) BOOL isPlayedToTrialEndPosition;
@end

@implementation SJKSYMediaPlayer
@synthesize volume = _volume;

- (instancetype)initWithURL:(NSURL *)URL startPosition:(NSTimeInterval)startPosition options:(nullable id)options {
    self = [super init];
    if ( self ) {
        _URL = URL;
        _volume = 1.0;
        _assetStatus = SJAssetStatusPreparing;
        _startPosition = startPosition;
        _needsSeekToStartPosition = startPosition != 0;
        
        _player = [KSYMoviePlayerController.alloc initWithContentURL:URL];
        _player.shouldAutoplay = NO;
        _player.scalingMode = (NSInteger)SJKSYMovieScalingModeAspectFit;
        _player.shouldEnableVideoPostProcessing = YES;
        _player.bufferTimeMax = 5;
#ifdef DEBUG
        _player.shouldEnableKSYStatModule = YES;
#else
        _player.shouldEnableKSYStatModule = NO;
#endif
        _player.videoDecoderMode = MPMovieVideoDecoderMode_AUTO;
        _player.shouldLoop = NO;
        [_player setTimeout:5 readTimeout:30];
        
        // https://github.com/ksvc/KSYMediaPlayer_iOS/wiki/notification
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_isPreparedToPlayDidChange:) name:MPMediaPlaybackIsPreparedToPlayDidChangeNotification object:_player];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_playbackStateDidChange:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:_player];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_playbackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:_player];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_loadStateDidChange:) name:MPMoviePlayerLoadStateDidChangeNotification object:_player];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_naturalSizeAvailable:) name:MPMovieNaturalSizeAvailableNotification object:_player];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_firstVideoFrameRendered:) name:MPMoviePlayerFirstVideoFrameRenderedNotification object:_player];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_suggestReload:) name:MPMoviePlayerSuggestReloadNotification object:_player];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_seekComplete:) name:MPMoviePlayerSeekCompleteNotification object:_player];
        
        [_player prepareToPlay];
    }
    return self;
}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%d \t %s", (int)__LINE__, __func__);
#endif
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)replay {
    _isReplayed = YES;
    __weak typeof(self) _self = self;
    [self seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        __strong typeof(_self) self = _self;
        if ( !self ) return ;
        if ( self.player.playbackState != MPMoviePlaybackStatePlaying )
            [self play];
        
        [self _postNotification:SJMediaPlayerDidReplayNotification];
    }];
}

- (void)report {
    [self _postNotification:SJMediaPlayerAssetStatusDidChangeNotification];
    [self _postNotification:SJMediaPlayerTimeControlStatusDidChangeNotification];
    [self _postNotification:SJMediaPlayerDurationDidChangeNotification];
    [self _postNotification:SJMediaPlayerPlayableDurationDidChangeNotification];
}

- (void)play {
    _isPlayed = YES;
    
    if ( self.isPlaybackFinished ) {
        [self replay];
    }
    else {
        self.reasonForWaitingToPlay = SJWaitingWhileEvaluatingBufferingRateReason;
        self.timeControlStatus = SJPlaybackTimeControlStatusWaitingToPlay;
        
        [_player play];
    }
}

- (void)pause {
    self.reasonForWaitingToPlay = nil;
    self.timeControlStatus = SJPlaybackTimeControlStatusPaused;
    [self.player pause];
}

- (void)stop {
    self.reasonForWaitingToPlay = nil;
    self.timeControlStatus = SJPlaybackTimeControlStatusPaused;
    [self.player stop];
}

- (void)seekToTime:(CMTime)time completionHandler:(nullable void (^)(BOOL))completionHandler {
    if ( self.assetStatus != SJAssetStatusReadyToPlay ) {
        if ( completionHandler ) completionHandler(NO);
        return;
    }

    time = [self _adjustSeekTimeIfNeeded:time];
    BOOL isPlaybackEnded = _playbackFinishedInfo.isFinished;
    [self _willSeeking:time];
    _seekCompletionHandler = completionHandler;

    NSTimeInterval secs = CMTimeGetSeconds(time);
    if ( ceil(secs) == ceil(self.duration) ) secs = secs * 0.98;
    if ( isPlaybackEnded ) {
        [self play];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.player.currentPlaybackTime = secs;
        });
    }
    else {
        self.player.currentPlaybackTime = secs;
        [self play];
    }
}

- (UIView *)view {
    return _player.view;
}

- (nullable UIImage *)screenshot {
    return [_player thumbnailImageAtCurrentTime];
}

- (nullable NSError *)error {
    return _playbackFinishedInfo.isFinished && _playbackFinishedInfo.reason == MPMovieFinishReasonPlaybackError ? _error : nil;
}

- (void)setRate:(float)rate {
    _player.playbackSpeed = rate;
}

- (float)rate {
    return _player.playbackSpeed;
}

- (void)setVolume:(float)volume {
    _volume = volume;
    [_player setVolume:volume rigthVolume:volume];
}

- (void)setMuted:(BOOL)muted {
    _player.shouldMute = muted;
}
- (BOOL)isMuted {
    return _player.shouldMute;
}

- (NSTimeInterval)duration {
    return _player.duration;
}

#pragma mark -

- (void)setIsPlaybackFinished:(BOOL)isPlaybackFinished {
    if ( isPlaybackFinished != _isPlaybackFinished ) {
        if ( !isPlaybackFinished ) _finishedReason = nil;
        _isPlaybackFinished = isPlaybackFinished;
        if ( isPlaybackFinished ) {
            [self _postNotification:SJMediaPlayerPlaybackDidFinishNotification];
        }
    }
}

- (NSTimeInterval)currentTime {
    if ( self.isPlaybackFinished ) {
        if ( self.finishedReason == SJFinishedReasonToEndTimePosition )
            return self.duration;
        else if ( self.finishedReason == SJFinishedReasonToTrialEndPosition )
            return self.trialEndPosition;
    }
    return self.player.currentPlaybackTime;
}

- (NSTimeInterval)playableDuration {
    NSTimeInterval playableDuration = self.player.playableDuration;
    if ( self.trialEndPosition != 0 && playableDuration >= self.trialEndPosition ) {
        return self.trialEndPosition;
    }
    return playableDuration;
}

#pragma mark -

- (void)_isPreparedToPlayDidChange:(NSNotification *)note {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.isPreparedToPlay = YES;
        [self _toEvaluating];
        [self _postNotification:SJMediaPlayerDurationDidChangeNotification];
        if ( self.assetStatus == SJAssetStatusReadyToPlay && self.needsSeekToStartPosition ) {
            self.needsSeekToStartPosition = NO;
            [self seekToTime:CMTimeMakeWithSeconds(self.startPosition, NSEC_PER_SEC) completionHandler:nil];
        }
    });
}

- (void)_playbackStateDidChange:(NSNotification *)note {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _toEvaluating];
    });
}

- (void)_loadStateDidChange:(NSNotification *)note {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _toEvaluating];
    });
}

- (void)_playbackDidFinish:(NSNotification *)note {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _updatePlaybackFinishedInfo:note];
        [self _toEvaluating];
    });
}

- (void)_naturalSizeAvailable:(NSNotification *)note {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _updatePresentationSize];
    });
}

- (void)_suggestReload:(NSNotification *)note {
    [self.player reload:_URL];
}

- (void)_seekComplete:(NSNotification *)note {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _didEndSeeking:YES];
    });
}
 
- (void)_firstVideoFrameRendered:(NSNotification *)note {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.firstVideoFrameRendered = YES;
    });
}
 
#pragma mark -

- (void)_toEvaluating {
    // update asset status
    SJAssetStatus status = self.assetStatus;
    if ( _playbackFinishedInfo.isFinished && _playbackFinishedInfo.reason == MPMovieFinishReasonPlaybackError ) {
        status = SJAssetStatusFailed;
    }
    else if ( self.isPreparedToPlay ) {
        status = SJAssetStatusReadyToPlay;
    }
    
    if ( status != self.assetStatus ) {
        self.assetStatus = status;
    }
    
    if ( status == SJAssetStatusFailed ) {
        self.reasonForWaitingToPlay = nil;
        self.timeControlStatus = SJPlaybackTimeControlStatusPaused;
        return;
    }

    if ( self.isPlayedToTrialEndPosition ) {
        [self _didPlayToTrialEndPosition];
        return;
    }
    
    // finished info
    if ( _playbackFinishedInfo.isFinished && self.timeControlStatus != SJPlaybackTimeControlStatusPaused ) {
        if ( _playbackFinishedInfo.reason == MPMovieFinishReasonPlaybackEnded ) {
            self.finishedReason = SJFinishedReasonToEndTimePosition;
            self.isPlaybackFinished = YES;
            [self pause];
        }
        if ( self.timeControlStatus != SJPlaybackTimeControlStatusPaused ) {
            self.reasonForWaitingToPlay = nil;
            self.timeControlStatus = SJPlaybackTimeControlStatusPaused;
        }
        return;
    }

    // update timeControl status
    if ( self.timeControlStatus != SJPlaybackTimeControlStatusPaused ) {
        SJPlaybackTimeControlStatus status = self.timeControlStatus;
        SJWaitingReason _Nullable  reason = self.reasonForWaitingToPlay;
        if ( self.player.loadState & MPMovieLoadStateStalled ) {
            reason = SJWaitingToMinimizeStallsReason;
            status = SJPlaybackTimeControlStatusWaitingToPlay;
        }
        else if ( self.player.loadState & MPMovieLoadStatePlayable ) {
            reason = nil;
            status = SJPlaybackTimeControlStatusPlaying;
        }
        
        if ( status != self.timeControlStatus || reason != self.reasonForWaitingToPlay ) {
            self.reasonForWaitingToPlay = reason;
            self.timeControlStatus = status;
        }
    }
    
    // resume playback
    if ( self.assetStatus == SJAssetStatusReadyToPlay ) {
        if ( self.timeControlStatus != SJPlaybackTimeControlStatusPaused &&
             self.player.playbackState == MPMoviePlaybackStatePaused ) {
            [self.player play];
        }
    }
}

- (void)_updatePresentationSize {
    CGSize oldSize = self.presentationSize;
    CGSize newSize = self.player.naturalSize;
    if ( !CGSizeEqualToSize(oldSize, newSize) ) {
        _presentationSize = newSize;
        [self _postNotification:SJMediaPlayerPresentationSizeDidChangeNotification];
    }
}

- (void)_updatePlaybackFinishedInfo:(NSNotification *)note {
    MPMovieFinishReason reason = [note.userInfo[MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] integerValue];
    if ( reason == MPMovieFinishReasonPlaybackError ) {
        _error = [NSError errorWithDomain:SJKSYMediaPlayerErrorDomain code:reason userInfo:@{ @"ksyerror" : note }];
    }
    _playbackFinishedInfo.isFinished = YES;
    _playbackFinishedInfo.reason = reason;
    [self _toEvaluating];
}

- (void)_postNotification:(NSNotificationName)name {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSNotificationCenter.defaultCenter postNotificationName:name object:self];
    });
}

- (void)_willSeeking:(CMTime)time {
    _playbackFinishedInfo.reason = 0;
    _playbackFinishedInfo.isFinished = NO;
    self.isPlaybackFinished = NO;
    _seekingInfo.time = time;
    _seekingInfo.isSeeking = YES;
}

- (void)_didEndSeeking:(BOOL)finished {
    if ( _seekingInfo.isSeeking ) {
        _seekingInfo.time = kCMTimeZero;
        _seekingInfo.isSeeking = NO;
        if ( _seekCompletionHandler != nil ) _seekCompletionHandler(finished);
        _seekCompletionHandler = nil;
    }
}

#pragma mark - log

- (void)setAssetStatus:(SJAssetStatus)assetStatus {
    _assetStatus = assetStatus;
    
#ifdef SJDEBUG
    switch ( assetStatus ) {
        case SJAssetStatusUnknown:
            printf("SJMediaPlayer.assetStatus.Unknown\n");
            break;
        case SJAssetStatusPreparing:
            printf("SJMediaPlayer.assetStatus.Preparing\n");
            break;
        case SJAssetStatusReadyToPlay:
            printf("SJMediaPlayer.assetStatus.ReadyToPlay\n");
            break;
        case SJAssetStatusFailed:
            printf("SJMediaPlayer.assetStatus.Failed\n");
            break;
    }
#endif
    
    [self _postNotification:SJMediaPlayerAssetStatusDidChangeNotification];
}

- (void)setTimeControlStatus:(SJPlaybackTimeControlStatus)timeControlStatus {
    _timeControlStatus = timeControlStatus;

    [self _refreshPlayableDuration];
    
#ifdef SJDEBUG
    switch ( timeControlStatus ) {
        case SJPlaybackTimeControlStatusPaused:
            printf("SJMediaPlayer.timeControlStatus.Pause\n");
            break;
        case SJPlaybackTimeControlStatusWaitingToPlay:
            printf("SJMediaPlayer.timeControlStatus.WaitingToPlay.reason(%s)\n", _reasonForWaitingToPlay.UTF8String);
            break;
        case SJPlaybackTimeControlStatusPlaying:
            printf("SJMediaPlayer.timeControlStatus.Playing\n");
            break;
    }
#endif
    
    [self _postNotification:SJMediaPlayerTimeControlStatusDidChangeNotification];
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

- (void)_didPlayToEndPosition {
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

- (void)_refreshPlayableDuration {
    
    if ( self.timeControlStatus == SJPlaybackTimeControlStatusPaused ) {
        if ( _refreshTimer != nil ) {
            [_refreshTimer invalidate];
            _refreshTimer = nil;
        }
    }
    else if ( _refreshTimer == nil ) {
        __weak typeof(self) _self = self;
        _refreshTimer = [NSTimer sj_timerWithTimeInterval:0.5 repeats:YES usingBlock:^(NSTimer * _Nonnull timer) {
            __strong typeof(_self) self = _self;
            if ( !self ) {
                [timer invalidate];
                return ;
            }
            
            if ( self.isPlayedToTrialEndPosition ) {
                [self _didPlayToTrialEndPosition];
                return;
            }
            
            NSTimeInterval playableDuration = self.playableDuration;
            if ( floor(self.previousPlayableDuration + 0.5) != floor(playableDuration + 0.5) ) {
                self.previousPlayableDuration = playableDuration;
                [self _postNotification:SJMediaPlayerPlayableDurationDidChangeNotification];
            }
        }];
        
        [_refreshTimer sj_fire];
        [NSRunLoop.mainRunLoop addTimer:_refreshTimer forMode:NSRunLoopCommonModes];
    }
}
@end
#pragma clang diagnostic pop
