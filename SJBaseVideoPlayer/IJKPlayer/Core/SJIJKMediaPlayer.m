//
//  SJIJKMediaPlayer.m
//  SJBaseVideoPlayer.common-IJKPlayer
//
//  Created by 畅三江 on 2022/8/15.
//

#import "SJIJKMediaPlayer.h"
#if __has_include(<IJKMediaFramework/IJKMediaFramework.h>)
#import <IJKMediaFramework/IJKMediaFramework.h>
#else
#import <PodIJKPlayer/PodIJKPlayer.h>
#endif
#import "NSTimer+SJAssetAdd.h"

NS_ASSUME_NONNULL_BEGIN
NSErrorDomain const SJIJKMediaPlayerErrorDomain = @"SJIJKMediaPlayerErrorDomain";

typedef struct {
    BOOL isFinished;
    IJKMPMovieFinishReason reason;
} SJIJKMediaPlaybackFinishedInfo;


@interface SJIJKMediaPlayer ()
@property (nonatomic, strong) IJKFFMoviePlayerController *player;
@property (nonatomic, strong, nullable) NSError *error;
@property (nonatomic) SJIJKMediaPlaybackFinishedInfo playbackFinishedInfo;
@property (nonatomic, nullable) SJWaitingReason reasonForWaitingToPlay;
@property (nonatomic) SJPlaybackTimeControlStatus timeControlStatus;
@property (nonatomic) SJSeekingInfo seekingInfo;
@property (nonatomic, copy, nullable) void(^seekCompletionHandler)(BOOL);
@property (nonatomic) SJAssetStatus assetStatus;
@property (nonatomic) NSTimeInterval startPosition;
@property (nonatomic) BOOL needsSeekToStartPosition;
@property (nonatomic) BOOL firstVideoFrameRendered;
@property (nonatomic) BOOL isPlaybackFinished;                        ///< 播放结束
@property (nonatomic, nullable) SJFinishedReason finishedReason;      ///< 播放结束的reason

@property (nonatomic, strong, nullable) NSTimer *refreshTimer;
@property (nonatomic) NSTimeInterval pre_playbaleTime;
@property (nonatomic, readonly) BOOL isPlayedToTrialEndPosition;
@end

@implementation SJIJKMediaPlayer
@synthesize isPlayed = _isPlayed;
@synthesize isReplayed = _isReplayed;
@synthesize rate = _rate;
@synthesize volume = _volume;
@synthesize muted = _muted;
@synthesize pauseWhenAppDidEnterBackground = _pauseWhenAppDidEnterBackground;
@synthesize presentationSize = _presentationSize;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#ifdef SJDEBUG
        [IJKFFMoviePlayerController setLogReport:YES];
#else
        [IJKFFMoviePlayerController setLogReport:NO];
        [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_INFO];
#endif
    });
}

- (instancetype)initWithURL:(NSURL *)URL startPosition:(NSTimeInterval)startPosition options:(nonnull IJKFFOptions *)ops {
    self = [super init];
    if ( self ) {
        _volume = 1;
        _rate = 1;
        _URL = URL;
        _startPosition = startPosition;
        _needsSeekToStartPosition = startPosition != 0;
        _assetStatus = SJAssetStatusPreparing;

        _player = [IJKFFMoviePlayerController.alloc initWithContentURL:URL withOptions:ops];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_preparedToPlayDidChange:) name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification object:_player];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_playbackDidFinish:) name:IJKMPMoviePlayerPlaybackDidFinishNotification object:_player];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_playbackStateDidChange:) name:IJKMPMoviePlayerPlaybackStateDidChangeNotification object:_player];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_loadStateDidChange:) name:IJKMPMoviePlayerLoadStateDidChangeNotification object:_player];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_naturalSizeAvailable:) name:IJKMPMovieNaturalSizeAvailableNotification object:_player];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_didSeekComplete:) name:IJKMPMoviePlayerDidSeekCompleteNotification object:_player];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_seekRenderingStart:) name:IJKMPMoviePlayerSeekAudioStartNotification object:_player];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_seekRenderingStart:) name:IJKMPMoviePlayerSeekVideoStartNotification object:_player];

        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_firstVideoFrameRendered:) name:IJKMPMoviePlayerFirstVideoFrameRenderedNotification object:_player];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_audioSessionInterruption:) name:AVAudioSessionInterruptionNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_audioSessionRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
        
        [_player setPauseInBackground:NO];
        [_player setShouldAutoplay:NO];
        [_player prepareToPlay];
    }
    return self;
}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%d \t %s", (int)__LINE__, __func__);
#endif
    [_refreshTimer invalidate];
    [_player.view performSelectorOnMainThread:@selector(removeFromSuperview) withObject:nil waitUntilDone:YES];
    [_player stop];
    [_player shutdown];
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)replay {
    _isReplayed = YES;
    __weak typeof(self) _self = self;
    [self seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        if ( self.player.playbackState != IJKMPMoviePlaybackStatePlaying )
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
    
    _player.playbackRate = _rate;
}

- (void)pause {
    self.reasonForWaitingToPlay = nil;
    self.timeControlStatus = SJPlaybackTimeControlStatusPaused;
    
    [_player pause];
    _player.playbackRate = 0;
}

- (void)stop {
    self.reasonForWaitingToPlay = nil;
    self.timeControlStatus = SJPlaybackTimeControlStatusPaused;
    [_player stop];
    [_player shutdown];

//    https://github.com/bilibili/ijkplayer/blob/cced91e3ae3730f5c63f3605b00d25eafcf5b97b/ios/IJKMediaPlayer/IJKMediaPlayer/IJKFFMoviePlayerController.m#L434
//
//    - (void)setScreenOn: (BOOL)on {
//        [IJKMediaModule sharedModule].mediaModuleIdleTimerDisabled = on;
//        // [UIApplication sharedApplication].idleTimerDisabled = on;
//    }
//
//    - (void)shutdown {
//        if (!_mediaPlayer)
//            return;
//
//        [self stopHudTimer];
//        [self unregisterApplicationObservers];
//        [self setScreenOn:NO];
//
//        [self performSelectorInBackground:@selector(shutdownWaitStop:) withObject:self];
//    }
//
//    - (void)shutdownWaitStop:(IJKFFMoviePlayerController *) mySelf  {
//        if (!_mediaPlayer)
//            return;
//
//        ijkmp_stop(_mediaPlayer);
//        ijkmp_shutdown(_mediaPlayer);
//
//        [self performSelectorOnMainThread:@selector(shutdownClose:) withObject:self waitUntilDone:YES];
//    }
//
//    - (void)stop {
//        if (!_mediaPlayer)
//            return;
//
//        [self setScreenOn:NO];
//
//        [self stopHudTimer];
//        ijkmp_stop(_mediaPlayer);
//    }
//
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

- (nullable UIImage *)screenshot {
    return _player.thumbnailImageAtCurrentTime;
}

- (nullable NSError *)error {
    return _playbackFinishedInfo.isFinished && _playbackFinishedInfo.reason == IJKMPMovieFinishReasonPlaybackError ? _error : nil;
}

#pragma mark -

- (UIView *)view {
    return _player.view;
}

@synthesize videoGravity = _videoGravity;
- (void)setVideoGravity:(SJVideoGravity)videoGravity {
    _videoGravity = videoGravity;
    IJKMPMovieScalingMode mode = IJKMPMovieScalingModeNone;
    if ( videoGravity == AVLayerVideoGravityResize )
        mode = IJKMPMovieScalingModeFill;
    else if ( videoGravity == AVLayerVideoGravityResizeAspect )
        mode = IJKMPMovieScalingModeAspectFit;
    else if ( videoGravity == AVLayerVideoGravityResizeAspectFill )
        mode = IJKMPMovieScalingModeAspectFill;
    _player.scalingMode = mode;
}
 
- (SJVideoGravity)videoGravity {
    return _videoGravity ? : AVLayerVideoGravityResizeAspect;
}

- (void)setRate:(float)rate {
    _rate = rate;
    if ( self.timeControlStatus != SJPlaybackTimeControlStatusPaused )
        _player.playbackRate = rate;
}

- (void)setVolume:(float)volume {
    _volume = volume;
    _player.playbackVolume = _muted ? 0 : _volume;
}

- (void)setMuted:(BOOL)muted {
    _muted = muted;
    _player.playbackVolume = _muted ? 0 : _volume;
}

- (void)setPauseWhenAppDidEnterBackground:(BOOL)pauseWhenAppDidEnterBackground {
    _pauseWhenAppDidEnterBackground = pauseWhenAppDidEnterBackground;
    [_player setPauseInBackground:pauseWhenAppDidEnterBackground];
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

- (NSTimeInterval)currentTime {
    if ( self.isPlaybackFinished ) {
        if ( self.finishedReason == SJFinishedReasonToEndTimePosition )
            return self.duration;
        else if ( self.finishedReason == SJFinishedReasonToTrialEndPosition )
            return self.trialEndPosition;
    }
    return _player.currentPlaybackTime;
}

- (NSTimeInterval)duration {
    return _player.duration;
}

- (NSTimeInterval)playableDuration {
    NSTimeInterval playableDuration = [_player playableDuration];
    if ( self.trialEndPosition != 0 && playableDuration >= self.trialEndPosition ) {
        return self.trialEndPosition;
    }
    return playableDuration;
}

#pragma mark -

- (void)_preparedToPlayDidChange:(NSNotification *)note {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _toEvaluating];
        [self _postNotification:SJMediaPlayerDurationDidChangeNotification];
        if ( self.player.isPreparedToPlay && self.assetStatus == SJAssetStatusReadyToPlay && self.needsSeekToStartPosition ) {
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

- (void)_didSeekComplete:(NSNotification *)note {
    if ( [note.userInfo[IJKMPMoviePlayerDidSeekCompleteErrorKey] boolValue] ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _didEndSeeking:NO];
        });
    }
}

- (void)_seekRenderingStart:(NSNotification *)note {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _didEndSeeking:YES];
    });

}
 
- (void)_audioSessionInterruption:(NSNotification *)note {
    NSDictionary *info = note.userInfo;
    if( (AVAudioSessionInterruptionType)[info[AVAudioSessionInterruptionTypeKey] integerValue] == AVAudioSessionInterruptionTypeBegan ) {
        [self pause];
    }
}

- (void)_audioSessionRouteChange:(NSNotification *)note {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *interuptionDict = note.userInfo;
        NSInteger reason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
        if ( reason == AVAudioSessionRouteChangeReasonOldDeviceUnavailable ) {
            [self pause];
        }
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
    if ( _playbackFinishedInfo.isFinished && _playbackFinishedInfo.reason == IJKMPMovieFinishReasonPlaybackError ) {
        status = SJAssetStatusFailed;
    }
    else if ( _player.isPreparedToPlay ) {
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
        if ( _playbackFinishedInfo.reason == IJKMPMovieFinishReasonPlaybackEnded ) {
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
        if ( _player.loadState & IJKMPMovieLoadStateStalled ) {
            reason = SJWaitingToMinimizeStallsReason;
            status = SJPlaybackTimeControlStatusWaitingToPlay;
        }
        else if ( _player.loadState & IJKMPMovieLoadStatePlayable ) {
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
            _player.playbackState == IJKMPMoviePlaybackStatePaused ) {
            [_player play];
        }
    }
}

- (void)_updatePresentationSize {
    CGSize oldSize = self.presentationSize;
    CGSize newSize = _player.naturalSize;
    if ( !CGSizeEqualToSize(oldSize, newSize) ) {
        _presentationSize = newSize;
        [self _postNotification:SJMediaPlayerPresentationSizeDidChangeNotification];
    }
}

- (void)_updatePlaybackFinishedInfo:(NSNotification *)note {
    IJKMPMovieFinishReason reason = [note.userInfo[IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] integerValue];
    if ( reason == IJKMPMovieFinishReasonPlaybackError ) {
        _error = [NSError errorWithDomain:SJIJKMediaPlayerErrorDomain code:reason userInfo:@{
            @"ijkerror" : note
        }];
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

- (void)_willEnterForeground {
    if ( self.timeControlStatus == SJPlaybackTimeControlStatusPaused )
        [self pause];
    else
        [self play];
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

    [self _refreshOrStop];
    
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
            if ( floor(self.pre_playbaleTime + 0.5) != floor(playableDuration + 0.5) ) {
                self.pre_playbaleTime = playableDuration;
                [self _postNotification:SJMediaPlayerPlayableDurationDidChangeNotification];
            }
        }];
        
        [_refreshTimer sj_fire];
        [NSRunLoop.mainRunLoop addTimer:_refreshTimer forMode:NSRunLoopCommonModes];
    }
}
@end
NS_ASSUME_NONNULL_END
