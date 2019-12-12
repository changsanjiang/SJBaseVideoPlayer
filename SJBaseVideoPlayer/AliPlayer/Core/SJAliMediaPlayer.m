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
NSNotificationName const SJAliMediaPlayerAssetStatusDidChangeNotification = @"SJAliMediaPlayerAssetStatusDidChangeNotification";
NSNotificationName const SJAliMediaPlayerTimeControlStatusDidChangeNotification = @"SJAliMediaPlayerTimeControlStatusDidChangeNotification";
NSNotificationName const SJAliMediaPlayerPresentationSizeDidChangeNotification = @"SJAliMediaPlayerPresentationSizeDidChangeNotification";
NSNotificationName const SJAliMediaPlayerDidPlayToEndTimeNotification = @"SJAliMediaPlayerDidPlayToEndTimeNotification";
NSNotificationName const SJAliMediaPlayerReadyForDisplayNotification = @"SJAliMediaPlayerReadyForDisplayNotification";
NSNotificationName const SJAliMediaPlayerDidReplayNotification = @"SJAliMediaPlayerDidReplayNotification";

@interface SJAliTimeObserverItem : NSObject
- (instancetype)initWithCurrentTimeDidChangeExeBlock:(void (^)(NSTimeInterval time))block
                   playableDurationDidChangeExeBlock:(void (^)(NSTimeInterval time))block1
                           durationDidChangeExeBlock:(void (^)(NSTimeInterval time))block2;
@property (nonatomic, copy, nullable) void (^currentTimeDidChangeExeBlock)(NSTimeInterval time);
@property (nonatomic, copy, nullable) void (^playableDurationDidChangeExeBlock)(NSTimeInterval time);
@property (nonatomic, copy, nullable) void (^durationDidChangeExeBlock)(NSTimeInterval time);
@end

@implementation SJAliTimeObserverItem
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

@interface SJAliMediaPlayer ()<AVPDelegate>
@property (nonatomic, strong, readonly) NSMutableArray<SJAliTimeObserverItem *> *observerItems;
@property (nonatomic) BOOL isPlayedToEndTime;
@property (nonatomic, getter=isReadyForDisplay) BOOL readyForDisplay;
@property (nonatomic, copy, nullable) void(^seekCompletionHandler)(BOOL);
@property (nonatomic) BOOL needSeekToSpecifyStartTime;
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
@end

@implementation SJAliMediaPlayer
- (instancetype)initWithSource:(__kindof AVPSource *)source specifyStartTime:(NSTimeInterval)time {
    self = [super init];
    if ( self ) {
        _source = source;
        _specifyStartTime = time;
        _assetStatus = SJAssetStatusPreparing;
        _player = AliPlayer.alloc.init;
        _player.delegate = self;
        _player.playerView = UIView.new;
        _videoGravity = AVLayerVideoGravityResizeAspect;
        _pauseWhenAppDidEnterBackground = YES;
        _seekMode = AVP_SEEKMODE_INACCURATE;
        _needSeekToSpecifyStartTime = time != 0;
        
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
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_player destroy];
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
    [_player seekToTime:CMTimeGetSeconds(time) * 1000 seekMode:_seekMode];
    [self play];
}

- (void)play {
    _isPlayed = YES;
    
    if ( _isPlayedToEndTime ) {
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
        [self _postNotification:SJAliMediaPlayerDidReplayNotification];
    }];
}
- (void)report {
    [self _postNotification:SJAliMediaPlayerAssetStatusDidChangeNotification];
    [self _postNotification:SJAliMediaPlayerTimeControlStatusDidChangeNotification];
    [self _postNotification:SJAliMediaPlayerPresentationSizeDidChangeNotification];
}

- (id)addTimeObserverWithCurrentTimeDidChangeExeBlock:(void (^)(NSTimeInterval time))block
                    playableDurationDidChangeExeBlock:(void (^)(NSTimeInterval time))block1
                            durationDidChangeExeBlock:(void (^)(NSTimeInterval time))block2 {
    SJAliTimeObserverItem *item = [SJAliTimeObserverItem.alloc initWithCurrentTimeDidChangeExeBlock:block playableDurationDidChangeExeBlock:block1 durationDidChangeExeBlock:block2];
    [self.observerItems addObject:item];
    return item;
}
- (void)removeTimeObserver:(id)observer {
    if ( observer != nil ) {
        [self.observerItems removeObject:observer];
    }
}

#pragma mark -

-(void)onPlayerEvent:(AliPlayer*)player eventType:(AVPEventType)eventType {
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

- (void)onError:(AliPlayer*)player errorModel:(AVPErrorModel *)errorModel {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.playerStatus = AVPStatusError;
        [self _toEvaluating];
    });
}

- (void)onVideoSizeChanged:(AliPlayer*)player width:(int)width height:(int)height rotation:(int)rotation {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.presentationSize = CGSizeMake(width, height);
    });
}

- (void)onCurrentPositionUpdate:(AliPlayer*)player position:(int64_t)position {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSTimeInterval time = 1.0 * position / 1000;
        self.currentTime = time;
    });
}

- (void)onBufferedPositionUpdate:(AliPlayer*)player position:(int64_t)position {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSTimeInterval time = 1.0 * position / 1000;
        self.playableDuration = time;
    });
}

- (void)onPlayerStatusChanged:(AliPlayer*)player oldStatus:(AVPStatus)oldStatus newStatus:(AVPStatus)newStatus {
    
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

- (void)_fristVideoFrameRender {
    _readyForDisplay = YES;
    [self _postNotification:SJAliMediaPlayerReadyForDisplayNotification];
}

- (void)_willSeeking:(CMTime)time {
    _isPlayedToEndTime = NO;
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
            if ( self.needSeekToSpecifyStartTime ) {
                self.needSeekToSpecifyStartTime = NO;
                [self seekToTime:CMTimeMakeWithSeconds(self.specifyStartTime, NSEC_PER_SEC) completionHandler:nil];
            }
            
            if ( self.shouldAutoplay ) {
                [self play];
            }
        }
    }
    
    if ( self.eventType == AVPEventFirstRenderedStart ) {
        self.duration = self.player.duration * 1.0 / 1000;
    }
    
    if ( status == SJAssetStatusFailed )
        return;
    
    if ( self.eventType == AVPEventSeekEnd && self.seekingInfo.isSeeking ) {
        [self _didEndSeeking:YES];
    }
    else if ( self.playerStatus == AVPStatusCompletion ) {
        self.isPlayedToEndTime = YES;
        self.reasonForWaitingToPlay = nil;
        self.timeControlStatus = SJPlaybackTimeControlStatusPaused;
        return;
    }
    
    if ( self.eventType == AVPEventFirstRenderedStart ) {
        self.readyForDisplay = YES;
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
    
    [self _postNotification:SJAliMediaPlayerAssetStatusDidChangeNotification];
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
    
    [self _postNotification:SJAliMediaPlayerTimeControlStatusDidChangeNotification];
}

- (void)setIsPlayedToEndTime:(BOOL)isPlayedToEndTime {
    _isPlayedToEndTime = isPlayedToEndTime;
    if ( isPlayedToEndTime ) {
        [self _postNotification:SJAliMediaPlayerDidPlayToEndTimeNotification];
    }
}

- (void)setPresentationSize:(CGSize)presentationSize {
    _presentationSize = presentationSize;
    [self _postNotification:SJAliMediaPlayerPresentationSizeDidChangeNotification];
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

@synthesize videoGravity = _videoGravity;
- (void)setVideoGravity:(SJVideoGravity)videoGravity {
    _videoGravity = videoGravity ?: AVLayerVideoGravityResizeAspect;
    if ( _videoGravity == AVLayerVideoGravityResize ) {
        _player.scalingMode = AVP_SCALINGMODE_SCALETOFILL;
    }
    else if ( _videoGravity == AVLayerVideoGravityResizeAspect ) {
        _player.scalingMode = AVP_SCALINGMODE_SCALEASPECTFIT;
    }
    else if ( _videoGravity == AVLayerVideoGravityResizeAspectFill ) {
        _player.scalingMode = AVP_SCALINGMODE_SCALEASPECTFILL;
    }
}

- (void)setReadyForDisplay:(BOOL)readyForDisplay {
    if ( _readyForDisplay != readyForDisplay ) {
        _readyForDisplay = readyForDisplay;
        [self _postNotification:SJAliMediaPlayerReadyForDisplayNotification];
    }
}

@synthesize currentTime = _currentTime;
- (void)setCurrentTime:(NSTimeInterval)currentTime {
    _currentTime = currentTime;
    for ( SJAliTimeObserverItem *item in _observerItems ) {
        if ( item.currentTimeDidChangeExeBlock != nil )
            item.currentTimeDidChangeExeBlock(currentTime);
    }
}

- (NSTimeInterval)currentTime {
    return _seekingInfo.isSeeking ? CMTimeGetSeconds(_seekingInfo.time) : _currentTime;
}

- (void)setPlayableDuration:(NSTimeInterval)playableDuration {
    _playableDuration = playableDuration;
    for ( SJAliTimeObserverItem *item in _observerItems ) {
        if ( item.playableDurationDidChangeExeBlock != nil )
            item.playableDurationDidChangeExeBlock(playableDuration);
    }
}

- (void)setDuration:(NSTimeInterval)duration {
    _duration = duration;
    for ( SJAliTimeObserverItem *item in _observerItems ) {
        if ( item.durationDidChangeExeBlock != nil )
            item.durationDidChangeExeBlock(duration);
    }
}

@synthesize observerItems = _observerItems;
- (NSMutableArray<SJAliTimeObserverItem *> *)observerItems {
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
