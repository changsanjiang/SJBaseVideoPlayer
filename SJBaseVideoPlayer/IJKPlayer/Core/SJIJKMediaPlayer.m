//
//  SJIJKMediaPlayer.m
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2019/10/12.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

#import "SJIJKMediaPlayer.h"

NS_ASSUME_NONNULL_BEGIN
NSNotificationName const SJIJKMediaPlayerAssetStatusDidChangeNotification = @"SJIJKMediaPlayerAssetStatusDidChangeNotification";
NSNotificationName const SJIJKMediaPlayerTimeControlStatusDidChangeNotification = @"SJIJKMediaPlayerTimeControlStatusDidChangeNotification";
NSNotificationName const SJIJKMediaPlayerPresentationSizeDidChangeNotification = @"SJIJKMediaPlayerPresentationSizeDidChangeNotification";
NSNotificationName const SJIJKMediaPlayerDidPlayToEndTimeNotification = @"SJIJKMediaPlayerDidPlayToEndTimeNotification";
NSNotificationName const SJIJKMediaPlayerReadyForDisplayNotification = @"SJIJKMediaPlayerReadyForDisplayNotification";

@interface SJIJKPeriodicTimeObserver : NSObject
- (instancetype)initWithInterval:(NSTimeInterval)interval player:(__weak SJIJKMediaPlayer *)player currentTimeDidChangeExeBlock:(nonnull void (^)(NSTimeInterval))currentTimeDidChangeExeBlock playableDurationDidChangeExeBlock:(nonnull void (^)(NSTimeInterval))playableDurationDidChangeExeBlock durationDidChangeExeBlock:(nonnull void (^)(NSTimeInterval))durationDidChangeExeBlock;
- (void)invalidate;
@end

@interface SJIJKMediaPlayer ()
@property (nonatomic, strong, readonly) NSMutableArray<SJIJKPeriodicTimeObserver *> *timeObservers;
@property (nonatomic, copy, nullable) void(^seekCompletionHandler)(BOOL);
@property (nonatomic, nullable) SJWaitingReason reasonForWaitingToPlay;
@property (nonatomic) SJPlaybackTimeControlStatus timeControlStatus;
@property (nonatomic) SJSeekingInfo seekingInfo;
@property (nonatomic) SJAssetStatus assetStatus;
@property (nonatomic) BOOL needSeekToSpecifyStartTime;
@end

@implementation SJIJKMediaPlayer
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

- (instancetype)initWithURL:(NSURL *)URL specifyStartTime:(NSTimeInterval)specifyStartTime options:(nonnull IJKFFOptions *)ops {
    self = [super initWithContentURL:URL withOptions:ops];
    if ( self ) {
        _volume = 1;
        _rate = 1;
        _URL = URL;
        _specifyStartTime = specifyStartTime;
        _timeObservers = NSMutableArray.new;
        _needSeekToSpecifyStartTime = specifyStartTime != 0;
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_preparedToPlayDidChange:) name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification object:self];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_playbackDidFinish:) name:IJKMPMoviePlayerPlaybackDidFinishNotification object:self];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_playbackStateDidChange:) name:IJKMPMoviePlayerPlaybackStateDidChangeNotification object:self];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_loadStateDidChange:) name:IJKMPMoviePlayerLoadStateDidChangeNotification object:self];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_naturalSizeAvailable:) name:IJKMPMovieNaturalSizeAvailableNotification object:self];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_didSeekComplete:) name:IJKMPMoviePlayerDidSeekCompleteNotification object:self];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_audioSessionInterruption:) name:AVAudioSessionInterruptionNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_audioSessionRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_firstVideoFrameRendered:) name:IJKMPMoviePlayerFirstVideoFrameRenderedNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
        
        [self setPauseInBackground:NO];
        self.shouldAutoplay = NO;
        self.assetStatus = SJAssetStatusPreparing;
        [self prepareToPlay];
    }
    return self;
}

- (void)dealloc {
#ifdef DEBUG
    printf("%d - %s", (int)__LINE__, __func__);
#endif
    for ( SJIJKPeriodicTimeObserver *observer in self.timeObservers ) {
        [observer invalidate];
    }
    [self.timeObservers removeAllObjects];
    [self.view removeFromSuperview];
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [super stop];
}

- (id)addPeriodicTimeObserverForInterval:(CMTime)interval
            currentTimeDidChangeExeBlock:(void (^)(NSTimeInterval time))block
       playableDurationDidChangeExeBlock:(void (^)(NSTimeInterval time))block1
               durationDidChangeExeBlock:(void (^)(NSTimeInterval time))block2 {
    SJIJKPeriodicTimeObserver *observer = [SJIJKPeriodicTimeObserver.alloc initWithInterval:CMTimeGetSeconds(interval) player:self currentTimeDidChangeExeBlock:block playableDurationDidChangeExeBlock:block1 durationDidChangeExeBlock:block2];
    [self.timeObservers addObject:observer];
    return observer;
}

- (void)removeTimeObserver:(id)observer {
    if ( observer != nil ) {
        [observer invalidate];
        [self.timeObservers removeObject:observer];
    }
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
    }];
}

- (void)report {
    [self _postNotification:SJIJKMediaPlayerAssetStatusDidChangeNotification];
    [self _postNotification:SJIJKMediaPlayerTimeControlStatusDidChangeNotification];
    [self _postNotification:SJIJKMediaPlayerPresentationSizeDidChangeNotification];
}

- (void)play {
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
    if ( _finishedInfo.isFinished ) {
        [self play];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.currentPlaybackTime = CMTimeGetSeconds(time);
        });
    }
    else {
        self.currentPlaybackTime = CMTimeGetSeconds(time);
    }
}

#pragma mark -

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
    self.scalingMode = mode;
}

- (SJVideoGravity)videoGravity {
    return _videoGravity ? : AVLayerVideoGravityResize;
}

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

#pragma mark -

- (void)_preparedToPlayDidChange:(NSNotification *)note {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _toEvaluating];
        if ( self.isPreparedToPlay && self.assetStatus == SJAssetStatusReadyToPlay && self.needSeekToSpecifyStartTime ) {
            self.needSeekToSpecifyStartTime = NO;
            [self seekToTime:CMTimeMakeWithSeconds(self.specifyStartTime, NSEC_PER_SEC) completionHandler:nil];
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
    [self _didEndSeeking:note.userInfo[IJKMPMoviePlayerDidSeekCompleteErrorKey] != nil];
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
        [self _mediaReadyForDisplay];
    });
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
    
    // resume playback
    if ( self.assetStatus == SJAssetStatusReadyToPlay ) {
        if ( self.timeControlStatus != SJPlaybackTimeControlStatusPaused &&
             self.playbackState == IJKMPMoviePlaybackStatePaused ) {
            [super play];
        }
    }
    
    // update timeControl status
    if ( self.timeControlStatus == SJPlaybackTimeControlStatusWaitingToPlay ) {
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
}

- (void)_updatePresentationSize {
    CGSize oldSize = self.presentationSize;
    CGSize newSize = self.naturalSize;
    if ( !CGSizeEqualToSize(oldSize, newSize) ) {
        _presentationSize = newSize;
        [self _postNotification:SJIJKMediaPlayerPresentationSizeDidChangeNotification];
    }
}

- (void)_updatePlaybackFinishedInfo:(NSNotification *)note {
    IJKMPMovieFinishReason reason = [note.userInfo[IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] integerValue];
    _finishedInfo.isFinished = YES;
    _finishedInfo.reason = reason;

    if ( _finishedInfo.reason == IJKMPMovieFinishReasonPlaybackEnded ) {
        [self _postNotification:SJIJKMediaPlayerDidPlayToEndTimeNotification];
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
    _seekingInfo.time = kCMTimeZero;
    _seekingInfo.isSeeking = NO;
    if ( _seekCompletionHandler != nil ) _seekCompletionHandler(finished);
    _seekCompletionHandler = nil;
}

- (void)_mediaReadyForDisplay {
    _readyForDisplay = YES;
    [self _postNotification:SJIJKMediaPlayerReadyForDisplayNotification];
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
            printf("SJIJKMediaPlayer.assetStatus.Unknown\n");
            break;
        case SJAssetStatusPreparing:
            printf("SJIJKMediaPlayer.assetStatus.Preparing\n");
            break;
        case SJAssetStatusReadyToPlay:
            printf("SJIJKMediaPlayer.assetStatus.ReadyToPlay\n");
            break;
        case SJAssetStatusFailed:
            printf("SJIJKMediaPlayer.assetStatus.Failed\n");
            break;
    }
#endif
    
    [self _postNotification:SJIJKMediaPlayerAssetStatusDidChangeNotification];
}

- (void)setTimeControlStatus:(SJPlaybackTimeControlStatus)timeControlStatus {
    _timeControlStatus = timeControlStatus;

#ifdef SJDEBUG
    switch ( timeControlStatus ) {
        case SJPlaybackTimeControlStatusPaused:
            printf("SJIJKMediaPlayer.timeControlStatus.Pause\n");
            break;
        case SJPlaybackTimeControlStatusWaitingToPlay:
            printf("SJIJKMediaPlayer.timeControlStatus.WaitingToPlay.reason(%s)\n", _reasonForWaitingToPlay.UTF8String);
            break;
        case SJPlaybackTimeControlStatusPlaying:
            printf("SJIJKMediaPlayer.timeControlStatus.Playing\n");
            break;
    }
#endif
    
    [self _postNotification:SJIJKMediaPlayerTimeControlStatusDidChangeNotification];
}
@end

@implementation SJIJKPeriodicTimeObserver {
    void (^_currentTimeDidChangeExeBlock)(NSTimeInterval);
    void (^_playableDurationDidChangeExeBlock)(NSTimeInterval);
    void (^_durationDidChangeExeBlock)(NSTimeInterval);
    __weak SJIJKMediaPlayer *_player;
    NSTimeInterval _interval;
    
    NSTimer *_timer;
    NSTimeInterval _currentTime;
    NSTimeInterval _duration;
    NSTimeInterval _playableDuration;
}

- (instancetype)initWithInterval:(NSTimeInterval)interval player:(__weak SJIJKMediaPlayer *)player currentTimeDidChangeExeBlock:(nonnull void (^)(NSTimeInterval))currentTimeDidChangeExeBlock playableDurationDidChangeExeBlock:(nonnull void (^)(NSTimeInterval))playableDurationDidChangeExeBlock durationDidChangeExeBlock:(nonnull void (^)(NSTimeInterval))durationDidChangeExeBlock {
    self = [super init];
    if ( self ) {
        _interval = interval;
        _player = player;
        _currentTimeDidChangeExeBlock = currentTimeDidChangeExeBlock;
        _playableDurationDidChangeExeBlock = playableDurationDidChangeExeBlock;
        _durationDidChangeExeBlock = durationDidChangeExeBlock;
        
        [self resumeOrPause];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(resumeOrPause) name:SJIJKMediaPlayerTimeControlStatusDidChangeNotification object:player];
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)invalidate {
    [_timer invalidate];
    _timer = nil;
}

- (void)resumeOrPause {
    if ( _player.timeControlStatus == SJPlaybackTimeControlStatusPaused ) {
        [self invalidate];
    }
    else if ( _timer == nil ) {
        _timer = [NSTimer timerWithTimeInterval:_interval target:self selector:@selector(exeBlock) userInfo:nil repeats:YES];
        _timer.fireDate = [NSDate dateWithTimeIntervalSinceNow:_interval];
        [NSRunLoop.mainRunLoop addTimer:_timer forMode:NSRunLoopCommonModes];
    }
}
 
- (void)exeBlock {
    NSTimeInterval currentTime = _player.currentPlaybackTime;
    NSTimeInterval duration = _player.duration;
    NSTimeInterval playableDuration = _player.playableDuration;
    
    if ( _currentTime != currentTime ) {
        _currentTime = currentTime;
        if ( _currentTimeDidChangeExeBlock ) _currentTimeDidChangeExeBlock(currentTime);
    }
    
    if ( _duration != duration ) {
        _duration = duration;
        if ( _durationDidChangeExeBlock ) _durationDidChangeExeBlock(duration);
    }
    
    if ( _playableDuration != playableDuration ) {
        _playableDuration = playableDuration;
        if ( _playableDurationDidChangeExeBlock ) _playableDurationDidChangeExeBlock(playableDuration);
    }
}
@end
NS_ASSUME_NONNULL_END
