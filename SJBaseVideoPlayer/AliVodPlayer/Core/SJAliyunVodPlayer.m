//
//  SJMediaPlayer.m
//  Demo
//
//  Created by BlueDancer on 2019/11/13.
//  Copyright © 2019 SanJiang. All rights reserved.
//

#import "SJAliyunVodPlayer.h"
#import "NSTimer+SJAssetAdd.h"

NS_ASSUME_NONNULL_BEGIN
@interface SJAliyunVodPlayer ()<AliyunVodPlayerDelegate>
@property (nonatomic, copy, nullable) void(^seekCompletionHandler)(BOOL);
@property (nonatomic) NSTimeInterval startPosition;
@property (nonatomic) BOOL needSeekToStartPosition;
@property (nonatomic, nullable) SJWaitingReason reasonForWaitingToPlay;
@property (nonatomic) SJPlaybackTimeControlStatus timeControlStatus;
@property (nonatomic) SJSeekingInfo seekingInfo;
@property (nonatomic) SJAssetStatus assetStatus;
@property (nonatomic) CGSize presentationSize;
@property (nonatomic) BOOL firstVideoFrameRendered;
@property (nonatomic, strong, readonly) AliyunVodPlayer *player;
@property (nonatomic) AliyunVodPlayerState playerStatus;
@property (nonatomic) AliyunVodPlayerEvent eventType;

@property (nonatomic) NSTimeInterval duration;
@property (nonatomic, strong, nullable) NSTimer *refreshTimer;
@property (nonatomic) NSTimeInterval prePlaybaclDuration;

@property (nonatomic) BOOL isPlaybackFinished;                      ///< 播放结束
@property (nonatomic, nullable) SJFinishedReason finishedReason;    ///< 播放结束的reason
@property (nonatomic, readonly) BOOL isPlayedToTrialEndPosition;
@end

@implementation SJAliyunVodPlayer
@synthesize pauseWhenAppDidEnterBackground = _pauseWhenAppDidEnterBackground;
@synthesize isPlayed = _isPlayed;
@synthesize isReplayed = _isReplayed;
@synthesize rate = _rate;
@synthesize volume = _volume;
@synthesize muted = _muted;

- (instancetype)initWithMedia:(__kindof SJAliyunVodModel *)media startPosition:(NSTimeInterval)time {
    self = [super init];
    if ( self ) {
        _media = media;
        _startPosition = time;
        _assetStatus = SJAssetStatusPreparing;
        _player.delegate = self;
        _pauseWhenAppDidEnterBackground = YES;
        _needSeekToStartPosition = time != 0;
        
        _player = AliyunVodPlayer.alloc.init;
        _player.delegate = self;
        if ( media.saveDir.length != 0 ) {
            [_player setPlayingCache:YES saveDir:media.saveDir maxSize:media.maxSize maxDuration:media.maxDuration];
        }
        
        if ( [media isKindOfClass:SJAliyunVodURLModel.class] ) {
            SJAliyunVodURLModel *urlMedia = media;
            [_player prepareWithURL:urlMedia.URL];
        }
        else if ( [media isKindOfClass:SJAliyunVodStsModel.class] ) {
            SJAliyunVodStsModel *stsMedia = media;
            [_player prepareWithVid:stsMedia.vid accessKeyId:stsMedia.accessKeyId accessKeySecret:stsMedia.accessKeySecret securityToken:stsMedia.securityToken region:stsMedia.region];
        }
        else if ( [media isKindOfClass:SJAliyunVodAuthModel.class] ) {
            SJAliyunVodAuthModel *authMedia = media;
            [_player prepareWithVid:authMedia.vid playAuth:authMedia.playAuth];
        }
        else if ( [media isKindOfClass:SJAliyunVodMpsModel.class] ) {
            SJAliyunVodMpsModel *mpsMedia = media;
            [_player prepareWithVid:mpsMedia.vid accId:mpsMedia.accId accSecret:mpsMedia.accSecret stsToken:mpsMedia.stsToken authInfo:mpsMedia.authInfo region:mpsMedia.region playDomain:mpsMedia.playDomain mtsHlsUriToken:mpsMedia.mtsHlsUriToken];
        }
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%d \t %s", (int)__LINE__, __func__);
#endif
    [_refreshTimer invalidate];
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_player releasePlayer];
}

- (UIView *)view {
    return self.player.playerView;
}

- (void)seekToTime:(CMTime)time completionHandler:(nullable void (^)(BOOL finished))completionHandler {
    if ( self.assetStatus != SJAssetStatusReadyToPlay ) {
        if ( completionHandler ) completionHandler(NO);
        return;
    }
    
    if ( self.seekingInfo.isSeeking ) {
        [self _didEndSeeking:NO];
    }
    
    time = [self _adjustSeekTimeIfNeeded:time];
    
    _seekCompletionHandler = completionHandler;
    BOOL isPlaybackEnded = self.isPlaybackFinished;
    [self _willSeeking:time];
    
    NSTimeInterval secs = CMTimeGetSeconds(time);
    if ( isPlaybackEnded ) {
        [self replay];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.player seekToTime:secs];
        });
    }
    else {
        [_player seekToTime:secs];
        [self play];
    }
}

- (void)play {
    if ( self.isPlaybackFinished ) {
        [self replay];
    }
    else {
        self.reasonForWaitingToPlay = SJWaitingWhileEvaluatingBufferingRateReason;
        self.timeControlStatus = SJPlaybackTimeControlStatusWaitingToPlay;

        _isPlayed ? [_player resume] : [_player start];
    }
    
    _isPlayed = YES;
}

- (void)pause {
    self.reasonForWaitingToPlay = nil;
    self.timeControlStatus = SJPlaybackTimeControlStatusPaused;

    [_player pause];
}

- (void)replay {
    _isReplayed = YES;
    self.isPlaybackFinished = NO;
    self.reasonForWaitingToPlay = SJWaitingWhileEvaluatingBufferingRateReason;
    self.timeControlStatus = SJPlaybackTimeControlStatusWaitingToPlay;
    [_player replay];
    [self _postNotification:SJMediaPlayerDidReplayNotification];
}
- (void)report {
    [self _postNotification:SJMediaPlayerAssetStatusDidChangeNotification];
    [self _postNotification:SJMediaPlayerTimeControlStatusDidChangeNotification];
    [self _postNotification:SJMediaPlayerDurationDidChangeNotification];
    [self _postNotification:SJMediaPlayerPlayableDurationDidChangeNotification];
}

- (nullable UIImage *)screenshot {
    return self.player.snapshot;
}

#pragma mark -

- (void)vodPlayer:(AliyunVodPlayer *)vodPlayer onEventCallback:(AliyunVodPlayerEvent)event {
#ifdef SJDEBUG
    __auto_type toString = ^NSString *(AliyunVodPlayerEvent event) {
        switch ( event ) {
            case AliyunVodPlayerEventPrepareDone:
                return @"AliyunVodPlayerEventPrepareDone";
            case AliyunVodPlayerEventPlay:
                return @"AliyunVodPlayerEventPlay";
            case AliyunVodPlayerEventFirstFrame:
                return @"AliyunVodPlayerEventFirstFrame";
            case AliyunVodPlayerEventPause:
                return @"AliyunVodPlayerEventPause";
            case AliyunVodPlayerEventStop:
                return @"AliyunVodPlayerEventStop";
            case AliyunVodPlayerEventFinish:
                return @"AliyunVodPlayerEventFinish";
            case AliyunVodPlayerEventBeginLoading:
                return @"AliyunVodPlayerEventBeginLoading";
            case AliyunVodPlayerEventEndLoading:
                return @"AliyunVodPlayerEventEndLoading";
            case AliyunVodPlayerEventSeekDone:
                return @"AliyunVodPlayerEventSeekDone";
        }
    };
    NSLog(@"eventType: %@", toString(event));
#endif
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.eventType = event;
        [self _toEvaluating];
    });
}

- (void)vodPlayer:(AliyunVodPlayer *)vodPlayer playBackErrorModel:(AliyunPlayerVideoErrorModel *)errorModel {
#ifdef DEBUG
    NSLog(@"%@", errorModel.errorMsg);
#endif
}

- (void)vodPlayer:(AliyunVodPlayer *)vodPlayer newPlayerState:(AliyunVodPlayerState)newState {
#ifdef SJDEBUG
    __auto_type toString = ^NSString *(AliyunVodPlayerState state) {
        switch ( state ) {
            case AliyunVodPlayerStateIdle:
                return @"AliyunVodPlayerStateIdle";
            case AliyunVodPlayerStateError:
                return @"AliyunVodPlayerStateError";
            case AliyunVodPlayerStatePrepared:
                return @"AliyunVodPlayerStatePrepared";
            case AliyunVodPlayerStatePlay:
                return @"AliyunVodPlayerStatePlay";
            case AliyunVodPlayerStatePause:
                return @"AliyunVodPlayerStatePause";
            case AliyunVodPlayerStateStop:
                return @"AliyunVodPlayerStateStop";
            case AliyunVodPlayerStateFinish:
                return @"AliyunVodPlayerStateFinish";
            case AliyunVodPlayerStateLoading:
                return @"AliyunVodPlayerStateLoading";
        }
    };
    
    NSLog(@"newState: %@", toString(newState));
#endif
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.playerStatus = newState;
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
    if ( self.playerStatus == AliyunVodPlayerStatePrepared ) {
        status = SJAssetStatusReadyToPlay;
        self.isPlaybackFinished = NO;
        self.reasonForWaitingToPlay = SJWaitingWhileEvaluatingBufferingRateReason;
        self.timeControlStatus = SJPlaybackTimeControlStatusWaitingToPlay;
    }
    else if ( self.playerStatus == AliyunVodPlayerStateError ) {
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
    
    if ( self.isPlayedToTrialEndPosition ) {
        [self _didPlayToTrialEndPosition];
        return;
    }
    
    if ( self.eventType == AliyunVodPlayerEventFirstFrame ) {
        self.presentationSize = CGSizeMake(self.player.videoWidth, self.player.videoHeight);
    }
    
    if ( status == SJAssetStatusFailed )
        return;
    
    if ( self.eventType == AliyunVodPlayerEventSeekDone && self.seekingInfo.isSeeking ) {
        [self _didEndSeeking:YES];
    }
    else if ( self.playerStatus == AliyunVodPlayerStateFinish ) {
        self.finishedReason = SJFinishedReasonToEndTimePosition;
        self.isPlaybackFinished = YES;
        self.reasonForWaitingToPlay = nil;
        self.timeControlStatus = SJPlaybackTimeControlStatusPaused;
        return;
    }
    
    if ( self.eventType == AliyunVodPlayerEventFirstFrame ) {
        self.firstVideoFrameRendered = YES;
    }
    
    if ( self.timeControlStatus != SJPlaybackTimeControlStatusPaused ) {
        SJPlaybackTimeControlStatus status = self.timeControlStatus;
        SJWaitingReason _Nullable reason = self.reasonForWaitingToPlay;
        if ( self.playerStatus == AliyunVodPlayerStateLoading ) {
            reason = SJWaitingToMinimizeStallsReason;
            status = SJPlaybackTimeControlStatusWaitingToPlay;
        }
        else if ( self.playerStatus == AliyunVodPlayerStatePlay ) {
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

    if ( assetStatus == SJAssetStatusReadyToPlay ) self.duration = _player.duration;
    
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

- (void)setPresentationSize:(CGSize)presentationSize {
    if ( !CGSizeEqualToSize(presentationSize, _presentationSize) ) {
        _presentationSize = presentationSize;
        [self _postNotification:SJMediaPlayerPresentationSizeDidChangeNotification];
    }
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

- (void)setRate:(float)rate {
    _rate = rate;
    _player.playSpeed = rate;
}

- (void)setVolume:(float)volume {
    _volume = volume;
    
#ifdef DEBUG
    NSLog(@"AliVodPlayer 暂未找到修改播放器音量的接口");
#endif
}

- (void)setMuted:(BOOL)muted {
    _muted = muted;
    _player.muteMode = muted;
}

- (void)setDisplayMode:(AliyunVodPlayerDisplayMode)displayMode {
    _player.displayMode = displayMode;
}
- (AliyunVodPlayerDisplayMode)displayMode {
    return _player.displayMode;
}

- (void)setDuration:(NSTimeInterval)duration {
    _duration = duration;
    [self _postNotification:SJMediaPlayerDurationDidChangeNotification];
}

- (NSTimeInterval)currentTime {
    if ( _isPlaybackFinished ) {
        if ( _finishedReason == SJFinishedReasonToEndTimePosition )
            return _duration;
        else if ( _finishedReason == SJFinishedReasonToTrialEndPosition )
            return _trialEndPosition;
    }
    return _seekingInfo.isSeeking ? CMTimeGetSeconds(_seekingInfo.time) : _player.currentTime;
}

- (NSTimeInterval)playableDuration {
    if ( _trialEndPosition != 0 && _player.loadedTime >= _trialEndPosition ) {
        return _trialEndPosition;
    }
    return _player.loadedTime;
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

- (void)_refreshOrStop {
    if ( _timeControlStatus == SJPlaybackTimeControlStatusPaused ) {
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
            if ( floor(self.prePlaybaclDuration + 0.5) != floor(playableDuration + 0.5) ) {
                self.prePlaybaclDuration = playableDuration;
                [self _postNotification:SJMediaPlayerPlayableDurationDidChangeNotification];
            }
        }];
        
        [_refreshTimer sj_fire];
        [NSRunLoop.mainRunLoop addTimer:_refreshTimer forMode:NSRunLoopCommonModes];
    }
}
@end
NS_ASSUME_NONNULL_END
