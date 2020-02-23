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
@property (nonatomic) BOOL isPlayedToEndTime;
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
@property (nonatomic, strong, nullable) NSTimer *playableDurationRefreshTimer;
@property (nonatomic) NSTimeInterval previousPlayableDuration;
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
        [self _refreshPlaybaleDuration];
    }
    return self;
}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%d \t %s", (int)__LINE__, __func__);
#endif
    [_playableDurationRefreshTimer invalidate];
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
    
    _seekCompletionHandler = completionHandler;
    [self _willSeeking:time];
    if ( _isPlayedToEndTime ) {
        [self replay];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.player seekToTime:CMTimeGetSeconds(time)];
        });
    }
    else {
        [_player seekToTime:CMTimeGetSeconds(time)];
        [self play];
    }
}

- (void)play {
    if ( _isPlayedToEndTime ) {
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
    _isPlayedToEndTime = NO;
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
        _isPlayedToEndTime = NO;
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
    
    if ( self.eventType == AliyunVodPlayerEventFirstFrame ) {
        self.presentationSize = CGSizeMake(self.player.videoWidth, self.player.videoHeight);
    }
    
    if ( status == SJAssetStatusFailed )
        return;
    
    if ( self.eventType == AliyunVodPlayerEventSeekDone && self.seekingInfo.isSeeking ) {
        [self _didEndSeeking:YES];
    }
    else if ( self.playerStatus == AliyunVodPlayerStateFinish ) {
        self.isPlayedToEndTime = YES;
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

- (void)setIsPlayedToEndTime:(BOOL)isPlayedToEndTime {
    _isPlayedToEndTime = isPlayedToEndTime;
    if ( isPlayedToEndTime ) {
        [self _postNotification:SJMediaPlayerDidPlayToEndTimeNotification];
    }
}

- (void)setPresentationSize:(CGSize)presentationSize {
    if ( !CGSizeEqualToSize(presentationSize, _presentationSize) ) {
        _presentationSize = presentationSize;
        [self _postNotification:SJMediaPlayerPresentationSizeDidChangeNotification];
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
    if ( _isPlayedToEndTime ) return _player.duration;
    return _seekingInfo.isSeeking ? CMTimeGetSeconds(_seekingInfo.time) : _player.currentTime;
}

- (NSTimeInterval)playableDuration {
    return _player.loadedTime;
}

- (void)applicationDidEnterBackground {
    if ( self.pauseWhenAppDidEnterBackground ) [self pause];
}
@end
NS_ASSUME_NONNULL_END
