//
//  SJIJKMediaPlayer.m
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2019/10/12.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

#import "SJIJKMediaPlayer.h"
#import "NSTimer+SJAssetAdd.h"

NS_ASSUME_NONNULL_BEGIN

typedef struct {
    BOOL isFinished;
    IJKMPMovieFinishReason reason;
} SJIJKMediaPlaybackFinishedInfo;


@interface SJIJKMediaPlayer ()
@property (nonatomic, copy, nullable) void(^seekCompletionHandler)(BOOL);
@property (nonatomic, nullable) SJWaitingReason reasonForWaitingToPlay;
@property (nonatomic) SJPlaybackTimeControlStatus timeControlStatus;
@property (nonatomic) SJIJKMediaPlaybackFinishedInfo finishedInfo;
@property (nonatomic) SJSeekingInfo seekingInfo;
@property (nonatomic) SJAssetStatus assetStatus;
@property (nonatomic) NSTimeInterval startPosition;
@property (nonatomic) BOOL needSeekToStartPosition;
@property (nonatomic) BOOL firstVideoFrameRendered;
@property (nonatomic, strong, nullable) NSTimer *playableDurationRefreshTimer;
@property (nonatomic) NSTimeInterval previousPlayableDuration;
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
    self = [super initWithContentURL:URL withOptions:ops];
    if ( self ) {
        _volume = 1;
        _rate = 1;
        _URL = URL;
        _startPosition = startPosition;
        _needSeekToStartPosition = startPosition != 0;
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_preparedToPlayDidChange:) name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification object:self];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_playbackDidFinish:) name:IJKMPMoviePlayerPlaybackDidFinishNotification object:self];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_playbackStateDidChange:) name:IJKMPMoviePlayerPlaybackStateDidChangeNotification object:self];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_loadStateDidChange:) name:IJKMPMoviePlayerLoadStateDidChangeNotification object:self];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_naturalSizeAvailable:) name:IJKMPMovieNaturalSizeAvailableNotification object:self];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_didSeekComplete:) name:IJKMPMoviePlayerDidSeekCompleteNotification object:self];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_seekRenderingStart:) name:IJKMPMoviePlayerSeekAudioStartNotification object:self];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_seekRenderingStart:) name:IJKMPMoviePlayerSeekVideoStartNotification object:self];

        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_firstVideoFrameRendered:) name:IJKMPMoviePlayerFirstVideoFrameRenderedNotification object:self];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_audioSessionInterruption:) name:AVAudioSessionInterruptionNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_audioSessionRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
        
        [self setPauseInBackground:NO];
        self.shouldAutoplay = NO;
        self.assetStatus = SJAssetStatusPreparing;
        [self prepareToPlay];
        [self _refreshPlaybaleDuration];
    }
    return self;
}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%d \t %s", (int)__LINE__, __func__);
#endif
    [_playableDurationRefreshTimer invalidate];
    [self.view removeFromSuperview];
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [super stop];
}

- (NSTimeInterval)currentTime {
    return self.currentPlaybackTime;
}

- (BOOL)isPlayedToEndTime {
    return self.finishedInfo.isFinished &&
           self.finishedInfo.reason == IJKMPMovieFinishReasonPlaybackEnded;
}

- (void)replay {
    _finishedInfo.reason = 0;
    _finishedInfo.isFinished = NO;
    
    _isReplayed = YES;
    __weak typeof(self) _self = self;
    [self seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        if ( self.playbackState != IJKMPMoviePlaybackStatePlaying )
            [self play];
        
        [self _postNotification:SJMediaPlayerDidReplayNotification];
    }];
}

- (void)report {
    [self _postNotification:SJMediaPlayerAssetStatusDidChangeNotification];
    [self _postNotification:SJMediaPlayerTimeControlStatusDidChangeNotification];
    [self _postNotification:SJMediaPlayerPresentationSizeDidChangeNotification];
}

- (void)play {
    _isPlayed = YES;
    
    if ( _finishedInfo.isFinished ) {
        [self replay];
    }
    else {
        self.reasonForWaitingToPlay = SJWaitingWhileEvaluatingBufferingRateReason;
        self.timeControlStatus = SJPlaybackTimeControlStatusWaitingToPlay;
        
        [super play];
    }
    
    self.playbackRate = _rate;
}

- (void)pause {
    self.reasonForWaitingToPlay = nil;
    self.timeControlStatus = SJPlaybackTimeControlStatusPaused;
    
    [super pause];
    self.playbackRate = 0;
}

- (void)stop {
    self.reasonForWaitingToPlay = nil;
    self.timeControlStatus = SJPlaybackTimeControlStatusPaused;
    
    [super stop];
}

- (void)seekToTime:(CMTime)time completionHandler:(nullable void (^)(BOOL))completionHandler {
    if ( self.assetStatus != SJAssetStatusReadyToPlay ) {
        if ( completionHandler ) completionHandler(NO);
        return;
    }
    
    [self _willSeeking:time];
    _seekCompletionHandler = completionHandler;
    NSTimeInterval secs = CMTimeGetSeconds(time);
    if ( ceil(secs) == ceil(self.duration) ) secs = secs * 0.98;
    if ( _finishedInfo.isFinished ) {
        [self play];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.currentPlaybackTime = secs;
        });
    }
    else {
        self.currentPlaybackTime = secs;
        [self play];
    }
}

- (nullable UIImage *)screenshot {
    return self.screenshot;
}


#pragma mark -

- (void)setRate:(float)rate {
    _rate = rate;
    if ( self.timeControlStatus != SJPlaybackTimeControlStatusPaused )
        self.playbackRate = rate;
}

- (void)setVolume:(float)volume {
    _volume = volume;
    self.playbackVolume = _muted ? 0 : _volume;
}

- (void)setMuted:(BOOL)muted {
    _muted = muted;
    self.playbackVolume = _muted ? 0 : _volume;
}

- (void)setPauseWhenAppDidEnterBackground:(BOOL)pauseWhenAppDidEnterBackground {
    _pauseWhenAppDidEnterBackground = pauseWhenAppDidEnterBackground;
    [self setPauseInBackground:pauseWhenAppDidEnterBackground];
}

#pragma mark -

- (void)_preparedToPlayDidChange:(NSNotification *)note {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _toEvaluating];
        [self _postNotification:SJMediaPlayerDurationDidChangeNotification];
        if ( self.isPreparedToPlay && self.assetStatus == SJAssetStatusReadyToPlay && self.needSeekToStartPosition ) {
            self.needSeekToStartPosition = NO;
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
 
- (void)_refreshPlaybaleDuration {
    __weak typeof(self) _self = self;
    _playableDurationRefreshTimer = [NSTimer sj_timerWithTimeInterval:1 repeats:YES usingBlock:^(NSTimer * _Nonnull timer) {
        __strong typeof(_self) self = _self;
        if ( !self ) {
            [timer invalidate];
            return ;
        }
        
        NSTimeInterval playableDuration = self.playableDuration;
        if ( floor(self.previousPlayableDuration + 0.5) != floor(playableDuration + 0.5) ) {
            self.previousPlayableDuration = playableDuration;
            [self _postNotification:SJMediaPlayerPlayableDurationDidChangeNotification];
        }
    }];
    
    [_playableDurationRefreshTimer sj_fire];
    [NSRunLoop.mainRunLoop addTimer:_playableDurationRefreshTimer forMode:NSRunLoopCommonModes];
}

#pragma mark -

- (void)_toEvaluating {
    // update asset status
    SJAssetStatus status = self.assetStatus;
    if ( self.finishedInfo.isFinished ) {
        switch ( self.finishedInfo.reason ) {
            case IJKMPMovieFinishReasonPlaybackEnded: break;
            case IJKMPMovieFinishReasonUserExited: break;
            case IJKMPMovieFinishReasonPlaybackError: {
                status = SJAssetStatusFailed;
            }
                break;
        }
    }
    else if ( self.isPreparedToPlay ) {
        status = SJAssetStatusReadyToPlay;
    }
    
    if ( status != self.assetStatus ) {
        self.assetStatus = status;
    }

    // finished info
    if ( _finishedInfo.isFinished ) {
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
        if ( self.loadState & IJKMPMovieLoadStateStalled ) {
            reason = SJWaitingToMinimizeStallsReason;
            status = SJPlaybackTimeControlStatusWaitingToPlay;
        }
        else if ( self.loadState & IJKMPMovieLoadStatePlayable ) {
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
             self.playbackState == IJKMPMoviePlaybackStatePaused ) {
            [super play];
        }
    }
}

- (void)_updatePresentationSize {
    CGSize oldSize = self.presentationSize;
    CGSize newSize = self.naturalSize;
    if ( !CGSizeEqualToSize(oldSize, newSize) ) {
        _presentationSize = newSize;
        [self _postNotification:SJMediaPlayerPresentationSizeDidChangeNotification];
    }
}

- (void)_updatePlaybackFinishedInfo:(NSNotification *)note {
    IJKMPMovieFinishReason reason = [note.userInfo[IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] integerValue];
    _finishedInfo.isFinished = YES;
    _finishedInfo.reason = reason;

    if ( _finishedInfo.reason == IJKMPMovieFinishReasonPlaybackEnded ) {
        [self _postNotification:SJMediaPlayerDidPlayToEndTimeNotification];
    }
}

- (void)_postNotification:(NSNotificationName)name {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSNotificationCenter.defaultCenter postNotificationName:name object:self];
    });
}

- (void)_willSeeking:(CMTime)time {
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

- (NSTimeInterval)currentPlaybackTime {
    BOOL isFinished = self.finishedInfo.isFinished && self.finishedInfo.reason == IJKMPMovieFinishReasonPlaybackEnded;
    return isFinished ? self.duration : [super currentPlaybackTime];
}
@end
NS_ASSUME_NONNULL_END
