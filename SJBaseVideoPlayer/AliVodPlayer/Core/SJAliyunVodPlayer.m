//
//  SJAliyunVodPlayer.m
//  Demo
//
//  Created by BlueDancer on 2019/11/13.
//  Copyright © 2019 SanJiang. All rights reserved.
//

#import "SJAliyunVodPlayer.h"
#import <AliyunVodPlayerSDK/AliyunVodPlayerSDK.h>
#import "NSTimer+SJAssetAdd.h"

NS_ASSUME_NONNULL_BEGIN
NSNotificationName const SJAliyunVodPlayerAssetStatusDidChangeNotification = @"SJAliyunVodPlayerAssetStatusDidChangeNotification";
NSNotificationName const SJAliyunVodPlayerTimeControlStatusDidChangeNotification = @"SJAliyunVodPlayerTimeControlStatusDidChangeNotification";
NSNotificationName const SJAliyunVodPlayerPresentationSizeDidChangeNotification = @"SJAliyunVodPlayerPresentationSizeDidChangeNotification";
NSNotificationName const SJAliyunVodPlayerDidPlayToEndTimeNotification = @"SJAliyunVodPlayerDidPlayToEndTimeNotification";
NSNotificationName const SJAliyunVodPlayerReadyForDisplayNotification = @"SJAliyunVodPlayerReadyForDisplayNotification";
NSNotificationName const SJAliyunVodPlayerDidReplayNotification = @"SJAliyunVodPlayerDidReplayNotification";

@interface SJAliyunVodPlayerTimeObserverItem : NSObject
- (instancetype)initWithCurrentTimeDidChangeExeBlock:(void (^)(NSTimeInterval time))block
                   playableDurationDidChangeExeBlock:(void (^)(NSTimeInterval time))block1
                           durationDidChangeExeBlock:(void (^)(NSTimeInterval time))block2;
@property (nonatomic, copy, nullable) void (^currentTimeDidChangeExeBlock)(NSTimeInterval time);
@property (nonatomic, copy, nullable) void (^playableDurationDidChangeExeBlock)(NSTimeInterval time);
@property (nonatomic, copy, nullable) void (^durationDidChangeExeBlock)(NSTimeInterval time);
@end

@implementation SJAliyunVodPlayerTimeObserverItem
- (instancetype)initWithCurrentTimeDidChangeExeBlock:(void (^)(NSTimeInterval))block playableDurationDidChangeExeBlock:(void (^)(NSTimeInterval))block1 durationDidChangeExeBlock:(void (^)(NSTimeInterval))block2 {
    self = [super init];
    if ( self ) {
        _currentTimeDidChangeExeBlock = block;
        _playableDurationDidChangeExeBlock = block1;
        _durationDidChangeExeBlock = block2;
    }
    return self;
}
@end

@interface SJAliRefreshTimer : NSObject
- (instancetype)initWithUsingBlock:(void(^)(void))usingBlock;
@property (nonatomic, copy, readonly) void(^usingBlock)(void);
- (void)start;
- (void)stop;
@end

@implementation SJAliRefreshTimer {
    NSTimer *_Nullable _timer; 
}

- (instancetype)initWithUsingBlock:(void (^)(void))usingBlock {
    self = [super init];
    if ( self ) {
        _usingBlock = usingBlock;
    }
    return self;
}
- (void)start {
    if ( _timer == nil ) {
        __weak typeof(self) _self = self;
        _timer = [NSTimer assetAdd_timerWithTimeInterval:0.5 block:^(NSTimer *timer) {
            __strong typeof(_self) self = _self;
            if ( !self ) {
                [timer invalidate];
                return ;
            }
            if ( self.usingBlock ) self.usingBlock();
        } repeats:YES];
        [_timer assetAdd_fire];
        [NSRunLoop.mainRunLoop addTimer:_timer forMode:NSRunLoopCommonModes];
    }
}
- (void)stop {
    [_timer invalidate];
    _timer = nil;
}
@end

@interface SJAliyunVodPlayer ()<AliyunVodPlayerDelegate>
@property (nonatomic, strong, readonly) NSMutableArray<SJAliyunVodPlayerTimeObserverItem *> *observerItems;
@property (nonatomic) BOOL isPlayedToEndTime;
@property (nonatomic, getter=isReadyForDisplay) BOOL readyForDisplay;
@property (nonatomic, copy, nullable) void(^seekCompletionHandler)(BOOL);
@property (nonatomic) BOOL needSeekToSpecifyStartTime;
@property (nonatomic, nullable) SJWaitingReason reasonForWaitingToPlay;
@property (nonatomic) SJPlaybackTimeControlStatus timeControlStatus;
@property (nonatomic) SJSeekingInfo seekingInfo;
@property (nonatomic) SJAssetStatus assetStatus;
@property (nonatomic) CGSize presentationSize;

@property (nonatomic, strong, readonly) AliyunVodPlayer *player;
@property (nonatomic) AliyunVodPlayerState playerStatus;
@property (nonatomic) AliyunVodPlayerEvent eventType;

@property (nonatomic) NSTimeInterval currentTime;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic) NSTimeInterval playableDuration;
@property (nonatomic, strong, readonly) SJAliRefreshTimer *timer;
@end

@implementation SJAliyunVodPlayer
- (instancetype)initWithMedia:(__kindof SJAliyunVodModel *)media specifyStartTime:(NSTimeInterval)time {
    self = [super init];
    if ( self ) {
        _media = media;
        _specifyStartTime = time;
        _assetStatus = SJAssetStatusPreparing;
        _player.delegate = self;
        _videoGravity = AVLayerVideoGravityResizeAspect;
        _pauseWhenAppDidEnterBackground = YES;
        _needSeekToSpecifyStartTime = time != 0;
        
        __weak typeof(self) _self = self;
        _timer = [SJAliRefreshTimer.alloc initWithUsingBlock:^{
            __strong typeof(_self) self = _self;
            if ( !self ) return;
            self.currentTime = self.player.currentTime;
            self.playableDuration = self.player.loadedTime;
        }];

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
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_player releasePlayer];
    [_timer stop];
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
    [self _postNotification:SJAliyunVodPlayerDidReplayNotification];
}
- (void)report {
    [self _postNotification:SJAliyunVodPlayerAssetStatusDidChangeNotification];
    [self _postNotification:SJAliyunVodPlayerTimeControlStatusDidChangeNotification];
    [self _postNotification:SJAliyunVodPlayerPresentationSizeDidChangeNotification];
}

- (id)addTimeObserverWithCurrentTimeDidChangeExeBlock:(void (^)(NSTimeInterval time))block
                    playableDurationDidChangeExeBlock:(void (^)(NSTimeInterval time))block1
                            durationDidChangeExeBlock:(void (^)(NSTimeInterval time))block2 {
    SJAliyunVodPlayerTimeObserverItem *item = [SJAliyunVodPlayerTimeObserverItem.alloc initWithCurrentTimeDidChangeExeBlock:block playableDurationDidChangeExeBlock:block1 durationDidChangeExeBlock:block2];
    [self.observerItems addObject:item];
    return item;
}
- (void)removeTimeObserver:(id)observer {
    if ( observer != nil ) {
        [self.observerItems removeObject:observer];
    }
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
    NSLog(@"%@", errorModel.errorMsg);
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

- (void)_fristVideoFrameRender {
    _readyForDisplay = YES;
    [self _postNotification:SJAliyunVodPlayerReadyForDisplayNotification];
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
            if ( self.needSeekToSpecifyStartTime ) {
                self.needSeekToSpecifyStartTime = NO;
                [self seekToTime:CMTimeMakeWithSeconds(self.specifyStartTime, NSEC_PER_SEC) completionHandler:nil];
            }
            
            if ( self.shouldAutoplay ) {
                [self play];
            }
        }
    }
    
    if ( self.eventType == AliyunVodPlayerEventFirstFrame ) {
        self.duration = self.player.duration;
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
        self.readyForDisplay = YES;
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

#ifdef SJDEBUG
    switch ( assetStatus ) {
        case SJAssetStatusUnknown:
            printf("SJAliyunVodPlayer.assetStatus.Unknown\n");
            break;
        case SJAssetStatusPreparing:
            printf("SJAliyunVodPlayer.assetStatus.Preparing\n");
            break;
        case SJAssetStatusReadyToPlay:
            printf("SJAliyunVodPlayer.assetStatus.ReadyToPlay\n");
            break;
        case SJAssetStatusFailed:
            printf("SJAliyunVodPlayer.assetStatus.Failed\n");
            break;
    }
#endif
    
    [self _postNotification:SJAliyunVodPlayerAssetStatusDidChangeNotification];
}

- (void)setTimeControlStatus:(SJPlaybackTimeControlStatus)timeControlStatus {
    _timeControlStatus = timeControlStatus;

    timeControlStatus == SJPlaybackTimeControlStatusPaused ? [self.timer stop] : [self.timer start];
    
#ifdef SJDEBUG
    switch ( timeControlStatus ) {
        case SJPlaybackTimeControlStatusPaused:
            printf("SJAliyunVodPlayer.timeControlStatus.Pause\n");
            break;
        case SJPlaybackTimeControlStatusWaitingToPlay:
            printf("SJAliyunVodPlayer.timeControlStatus.WaitingToPlay.reason(%s)\n", _reasonForWaitingToPlay.UTF8String);
            break;
        case SJPlaybackTimeControlStatusPlaying:
            printf("SJAliyunVodPlayer.timeControlStatus.Playing\n");
            break;
    }
#endif
    
    [self _postNotification:SJAliyunVodPlayerTimeControlStatusDidChangeNotification];
}

- (void)setIsPlayedToEndTime:(BOOL)isPlayedToEndTime {
    _isPlayedToEndTime = isPlayedToEndTime;
    if ( isPlayedToEndTime ) {
        [self _postNotification:SJAliyunVodPlayerDidPlayToEndTimeNotification];
    }

    self.currentTime = self.duration;
}

- (void)setPresentationSize:(CGSize)presentationSize {
    if ( !CGSizeEqualToSize(presentationSize, _presentationSize) ) {
        _presentationSize = presentationSize;
        [self _postNotification:SJAliyunVodPlayerPresentationSizeDidChangeNotification];
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

@synthesize videoGravity = _videoGravity;
- (void)setVideoGravity:(SJVideoGravity)videoGravity {
    _videoGravity = videoGravity ?: AVLayerVideoGravityResizeAspect;
    if ( _videoGravity == AVLayerVideoGravityResize ||
         _videoGravity == AVLayerVideoGravityResizeAspect ) {
        _player.displayMode = AliyunVodPlayerDisplayModeFit;
    }
    else if ( _videoGravity == AVLayerVideoGravityResizeAspectFill ) {
        _player.displayMode = AliyunVodPlayerDisplayModeFitWithCropping;
    }
}

- (void)setReadyForDisplay:(BOOL)readyForDisplay {
    if ( _readyForDisplay != readyForDisplay ) {
        _readyForDisplay = readyForDisplay;
        [self _postNotification:SJAliyunVodPlayerReadyForDisplayNotification];
    }
}

@synthesize currentTime = _currentTime;
- (void)setCurrentTime:(NSTimeInterval)currentTime {
    if ( currentTime != _currentTime ) {
        _currentTime = currentTime;
        for ( SJAliyunVodPlayerTimeObserverItem *item in _observerItems ) {
            if ( item.currentTimeDidChangeExeBlock != nil )
                item.currentTimeDidChangeExeBlock(currentTime);
        }
    }
}
- (NSTimeInterval)currentTime {
    return _seekingInfo.isSeeking ? CMTimeGetSeconds(_seekingInfo.time) : _currentTime;
}

- (void)setPlayableDuration:(NSTimeInterval)playableDuration {
    if ( _playableDuration != playableDuration ) {
        _playableDuration = playableDuration;
        for ( SJAliyunVodPlayerTimeObserverItem *item in _observerItems ) {
            if ( item.playableDurationDidChangeExeBlock != nil )
                item.playableDurationDidChangeExeBlock(playableDuration);
        }
    }
}

- (void)setDuration:(NSTimeInterval)duration {
    _duration = duration;
    for ( SJAliyunVodPlayerTimeObserverItem *item in _observerItems ) {
        if ( item.durationDidChangeExeBlock != nil )
            item.durationDidChangeExeBlock(duration);
    }
}

@synthesize observerItems = _observerItems;
- (NSMutableArray<SJAliyunVodPlayerTimeObserverItem *> *)observerItems {
    if ( _observerItems == nil ) {
        _observerItems = NSMutableArray.array;
    }
    return _observerItems;
}

- (void)applicationDidEnterBackground {
    if ( self.pauseWhenAppDidEnterBackground ) [self pause];
}
@end
NS_ASSUME_NONNULL_END
