//
//  SJAVMediaPlayer.m
//  Pods
//
//  Created by BlueDancer on 2019/4/9.
//

#import "SJAVMediaPlayer.h"
#if __has_include(<SJUIKit/NSObject+SJObserverHelper.h>)
#import <SJUIKit/NSObject+SJObserverHelper.h>
#else
#import "NSObject+SJObserverHelper.h"
#endif
#import "SJReachability.h"

NS_ASSUME_NONNULL_BEGIN
typedef struct SJAVMediaPlaybackInfo {
    BOOL isPrerolling;      ///< 简单的讲 preroll 是传输速率与解码或者显示需要的数据速度不匹配而产生的buffer需求
    BOOL isPaused;
    BOOL isError;
    BOOL isPlayedToEndTime;
    
    NSTimeInterval specifyStartTime;
    NSTimeInterval playableDuration;
    NSTimeInterval duration;
    NSInteger bufferingProgress;
    SJPlayerBufferStatus bufferStatus;
    SJVideoPlayerInactivityReason inactivityReason;
    SJVideoPlayerPausedReason pausedReason;
    SJVideoPlayerPlayStatus playbackStatus;
    
    enum SJAVMediaPrepareStatus: int {
        SJAVMediaPrepareStatusUnknown,
        SJAVMediaPrepareStatusPreparing,
        SJAVMediaPrepareStatusSuccessfullyToPrepare,
        SJAVMediaPrepareStatusFailedToPrepare
    } prepareStatus;
    
    struct SJAVMediaPlayerSeekingInfo {
        BOOL isSeeking;
        CMTime time;
    } seekingInfo;
} SJAVMediaPlaybackInfo;

static NSString *kDuration = @"duration";
static NSString *kLoadedTimeRanges = @"loadedTimeRanges";
static NSString *kPlaybackBufferEmpty = @"playbackBufferEmpty";
static NSString *kPresentationSize = @"presentationSize";
static NSString *kPlayerItemStatus = @"status";

static NSString *kPlaybackLikelyToKeeyUp = @"playbackLikelyToKeepUp";
static NSString *kPlaybackBufferFull = @"playbackBufferFull";
static NSString *kRate = @"rate";

// resume play after stall
static const float kMaxHighWaterMarkMilli = 15 * 1000;

inline static bool isFloatZero(float value) {
    return fabsf(value) <= 0.00001f;
}

@interface SJAVMediaPlayer ()
@property (nonatomic, readonly) SJAVMediaPlaybackInfo *sj_playbackInfo;
@property (nonatomic, strong, nullable) NSError *sj_error;
@end

@implementation SJAVMediaPlayer
@synthesize sj_playbackRate = _sj_playbackRate;

- (instancetype)initWithURL:(NSURL *)URL {
    return [self initWithURL:URL specifyStartTime:0];
}
- (instancetype)initWithURL:(NSURL *)URL specifyStartTime:(NSTimeInterval)specifyStartTime {
    AVAsset *asset = [AVAsset assetWithURL:URL];
    return [self initWithAVAsset:asset specifyStartTime:specifyStartTime];
}
- (instancetype)initWithAVAsset:(__kindof AVAsset *)asset specifyStartTime:(NSTimeInterval)specifyStartTime {
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:asset];
    return [self initWithPlayerItem:playerItem specifyStartTime:specifyStartTime];
}
- (instancetype)initWithPlayerItem:(AVPlayerItem *_Nullable)item specifyStartTime:(NSTimeInterval)specifyStartTime {
    self = [super initWithPlayerItem:item];
    if ( self ) {
        _sj_playbackRate = 1.0;
        _sj_playbackInfo = (SJAVMediaPlaybackInfo *)malloc(sizeof(SJAVMediaPlaybackInfo));
        _sj_playbackInfo->isPrerolling = NO;
        _sj_playbackInfo->isPaused = NO;
        _sj_playbackInfo->isError = NO;
        _sj_playbackInfo->isPlayedToEndTime = NO;
        
        _sj_playbackInfo->specifyStartTime = specifyStartTime;
        _sj_playbackInfo->playableDuration = 0;
        _sj_playbackInfo->duration = 0;
        _sj_playbackInfo->bufferingProgress = 0;
        _sj_playbackInfo->bufferStatus = SJPlayerBufferStatusUnknown;
        
        _sj_playbackInfo->prepareStatus = SJAVMediaPrepareStatusUnknown;
        _sj_playbackInfo->seekingInfo = (struct SJAVMediaPlayerSeekingInfo){NO, kCMTimeZero};
        
        if (@available(iOS 10.0, *) ) {
            AVURLAsset *asset = (AVURLAsset *)item.asset;
            if ( [asset respondsToSelector:@selector(URL)] ) {
                self.automaticallyWaitsToMinimizeStalling = [asset.URL.pathExtension isEqualToString:@"m3u8"];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _sj_prepareToPlay];
        });
    }
    return self;
}
- (void)dealloc {
    if ( _sj_playbackInfo->seekingInfo.isSeeking )
        [self.currentItem cancelPendingSeeks];
    free(_sj_playbackInfo);
}

- (void)_sj_prepareToPlay {
    if ( _sj_playbackInfo->prepareStatus != SJAVMediaPrepareStatusUnknown )
        return;
    
    _sj_playbackInfo->prepareStatus = SJAVMediaPrepareStatusPreparing;
    
    AVPlayerItem *item = self.currentItem;
    __weak typeof(self) _self = self;
    // - prepare -
    sjkvo_observe(item, kPlayerItemStatus, ^(id  _Nonnull target, NSDictionary<NSKeyValueChangeKey,id> * _Nullable change) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        [self _playerItemStatusDidChange];
    });
    
    // - did play to end time -
    [self sj_observeWithNotification:AVPlayerItemDidPlayToEndTimeNotification target:item usingBlock:^(SJAVMediaPlayer  *self, NSNotification * _Nonnull note) {
        [self _successfullyToPlayEndTime:note];
    }];
    
    [self sj_observeWithNotification:AVPlayerItemFailedToPlayToEndTimeNotification target:item usingBlock:^(SJAVMediaPlayer  *self, NSNotification * _Nonnull note) {
        [self _failedToPlayEndTime:note];
    }];
    
    // - buffer -
    sjkvo_observe(item, kLoadedTimeRanges, ^(id  _Nonnull target, NSDictionary<NSKeyValueChangeKey,id> * _Nullable change) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        [self _playerItemLoadedTimeRangesDidChange];
    });
    sjkvo_observe(item, kPlaybackBufferEmpty, ^(id  _Nonnull target, NSDictionary<NSKeyValueChangeKey,id> * _Nullable change) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        [self _bufferStatusDidChange];
    });
    sjkvo_observe(item, kPlaybackLikelyToKeeyUp, ^(id  _Nonnull target, NSDictionary<NSKeyValueChangeKey,id> * _Nullable change) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        [self _bufferStatusDidChange];
    });
    sjkvo_observe(item, kPlaybackBufferEmpty, NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld, ^(AVPlayerItem *target, NSDictionary<NSKeyValueChangeKey,id> * _Nullable change) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        self.sj_playbackInfo->isPrerolling = target.isPlaybackBufferEmpty;
        [self _bufferStatusDidChange];
    });
    sjkvo_observe(item, kPlaybackBufferFull, ^(id  _Nonnull target, NSDictionary<NSKeyValueChangeKey,id> * _Nullable change) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        [self _bufferStatusDidChange];
    });
    sjkvo_observe(item, kRate, ^(id  _Nonnull target, NSDictionary<NSKeyValueChangeKey,id> * _Nullable change) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        [self _rateDidChange];
    });
    
    // - interruption -
    [self sj_observeWithNotification:AVAudioSessionInterruptionNotification target:nil usingBlock:^(SJAVMediaPlayer *self, NSNotification * _Nonnull note) {
        NSDictionary *info = note.userInfo;
        if( (AVAudioSessionInterruptionType)[info[AVAudioSessionInterruptionTypeKey] integerValue] == AVAudioSessionInterruptionTypeBegan ) {
            [self pause];
        }
    }];
}

- (void)_playerItemStatusDidChange {
    if ( _sj_playbackInfo->prepareStatus == SJAVMediaPrepareStatusPreparing ) {
        AVPlayerItem *item = self.currentItem;
        AVPlayerItemStatus status = item.status;
        switch ( status ) {
            case AVPlayerItemStatusUnknown:
                break;
            case AVPlayerItemStatusReadyToPlay: {
                NSTimeInterval specifyStartTime = _sj_playbackInfo->specifyStartTime;
                if ( isFloatZero(specifyStartTime) ) {
                    [self _successfullyToPrepare:item];
                }
                else {
                    __weak typeof(self) _self = self;
                    [item seekToTime:CMTimeMakeWithSeconds(specifyStartTime, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
                        __strong typeof(_self) self = _self;
                        if ( !self ) return;
                        [self _successfullyToPrepare:item];
                    }];
                }
            }
                break;
            case AVPlayerItemStatusFailed: {
                [self _failedToPrepare:item.error];
            }
                break;
        }
    }
}

- (void)_playerItemLoadedTimeRangesDidChange {
    AVPlayerItem *playerItem = self.currentItem;
    NSArray *timeRangeArray = playerItem.loadedTimeRanges;
    CMTime currentTime = [self currentTime];
    
    BOOL foundRange = NO;
    CMTimeRange aTimeRange = {0};
    
    if ( timeRangeArray.count > 0 ) {
        aTimeRange = [[timeRangeArray objectAtIndex:0] CMTimeRangeValue];
        if( CMTimeRangeContainsTime(aTimeRange, currentTime) ) {
            foundRange = YES;
        }
    }
    
    if ( foundRange ) {
        CMTime maxTime = CMTimeRangeGetEnd(aTimeRange);
        NSTimeInterval playableDuration = CMTimeGetSeconds(maxTime);
        if ( playableDuration > 0 ) {
            [self _playableDurationDidChange:playableDuration];
        }
    }
}

- (void)_bufferStatusDidChange {
    SJPlayerBufferStatus bufferStatus = self.sj_bufferStatus;
    if ( _sj_playbackInfo->bufferStatus != bufferStatus ) {
        _sj_playbackInfo->bufferStatus = bufferStatus;
        [self _postNotificationWithName:SJAVMediaPlayerBufferStatusDidChangeNotification];
    }
}

- (void)_rateDidChange {
    if ( !isFloatZero(self.rate) )
        _sj_playbackInfo->isPrerolling = NO;
    
    [self _playbackStatusDidChange];
    [self _bufferStatusDidChange];
}

- (void)_playbackStatusDidChange {
    SJVideoPlayerInactivityReason inactivityReason = self.sj_inactivityReason;
    SJVideoPlayerPausedReason pausedReason = self.sj_pausedReason;
    SJVideoPlayerPlayStatus playbackStatus = self.sj_playbackStatus;
    
    if ( _sj_playbackInfo->inactivityReason != inactivityReason || _sj_playbackInfo->pausedReason != pausedReason || _sj_playbackInfo->playbackStatus ) {
        _sj_playbackInfo->inactivityReason = inactivityReason;
        _sj_playbackInfo->pausedReason = pausedReason;
        _sj_playbackInfo->playbackStatus = playbackStatus;
        [self _postNotificationWithName:SJAVMediaPlayerPlaybackStatusDidChangeNotification];
    }
}

- (void)_successfullyToPrepare:(AVPlayerItem *)item {
    _sj_playbackInfo->prepareStatus = SJAVMediaPrepareStatusSuccessfullyToPrepare;
    _sj_playbackInfo->duration = CMTimeGetSeconds(item.duration);
    [self _playbackStatusDidChange];
}

- (void)_failedToPrepare:(NSError *)error {
    _sj_playbackInfo->prepareStatus = SJAVMediaPrepareStatusFailedToPrepare;
    [self _onError:error];
}

- (void)_playableDurationDidChange:(NSTimeInterval)playableDuration {
    _sj_playbackInfo->playableDuration = playableDuration;

    NSTimeInterval currentPlaybackTime = [self sj_getCurrentPlaybackTime];
    int playableDurationMilli = (int)(playableDuration * 1000);
    int currentPlaybackTimeMilli = (int)(currentPlaybackTime * 1000);
    
    int bufferedDurationMilli = playableDurationMilli - currentPlaybackTimeMilli;
    if ( bufferedDurationMilli > 0 ) {
        _sj_playbackInfo->bufferingProgress = bufferedDurationMilli * 100 / kMaxHighWaterMarkMilli;
        if (_sj_playbackInfo->bufferingProgress > 100) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self->_sj_playbackInfo->bufferingProgress > 100) {
                    if ( [self _sj_isPlaying] ) {
                        self.rate = self->_sj_playbackRate;
                    }
                }
            });
        }
    }
}

- (void)_successfullyToPlayEndTime:(NSNotification *)note {
    _sj_playbackInfo->isPlayedToEndTime = YES;
    [self _didFinishPlayingWithSuccessfullyFlag:YES];
}

- (void)_failedToPlayEndTime:(NSNotification *)note {
    [self _onError:note.userInfo[@"error"]];
}

- (void)_onError:(NSError *)error {
    _sj_playbackInfo->isError = YES;
    _sj_error = error;
    [self _didFinishPlayingWithSuccessfullyFlag:NO];
}

- (void)_didFinishPlayingWithSuccessfullyFlag:(BOOL)flag {
    if ( flag ) {
        [self _postNotificationWithName:SJAVMediaPlayerPlayDidToEndTimeNotification];
    }
    else {
        [self _playbackStatusDidChange];
    }
}

- (void)_postNotificationWithName:(NSNotificationName)name {
    [NSNotificationCenter.defaultCenter postNotificationName:name object:self];
}

- (void)setSj_playbackRate:(float)sj_playbackRate {
    _sj_playbackRate = sj_playbackRate;
    if ( !isFloatZero(self.rate) ) {
        self.rate = sj_playbackRate;
    }
}

- (void)setSj_playbackVolume:(float)sj_playbackVolume {
    self.volume = sj_playbackVolume;
}

- (float)sj_playbackVolume {
    return self.volume;
}

- (void)setSj_muted:(BOOL)sj_muted {
    self.muted = sj_muted;
}

- (BOOL)isSJMuted {
    return self.isMuted;
}

- (void)play {
    if ( _sj_playbackInfo->isPlayedToEndTime ) {
        _sj_playbackInfo->isPlayedToEndTime = NO;
        [self seekToTime:kCMTimeZero];
    }
    [super play];
    _sj_playbackInfo->isPrerolling = NO;
    _sj_playbackInfo->isPaused = NO;
}
- (void)pause {
    [super pause];
    _sj_playbackInfo->isPrerolling = NO;
    _sj_playbackInfo->isPaused = YES;
}
- (BOOL)_sj_isPlaying {
    if ( !isFloatZero(self.rate) )
        return YES;
    if ( _sj_playbackInfo->isPrerolling )
        return YES;
    
    return NO;
}
- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL))completionHandler {
    if ( _sj_playbackInfo->prepareStatus != SJAVMediaPrepareStatusSuccessfullyToPrepare ) {
        if ( completionHandler ) completionHandler(NO);
        return;
    }
    
    [self _willSeekingToTime:time];
    __weak typeof(self) _self = self;
    [super seekToTime:time completionHandler:^(BOOL finished) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(_self) self = _self;
            if ( !self ) return;
            [self _didEndSeeking];
            if ( completionHandler ) completionHandler(finished);
        });
    }];
}
- (void)seekToTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter completionHandler:(void (^)(BOOL))completionHandler {
    if ( _sj_playbackInfo->prepareStatus != SJAVMediaPrepareStatusSuccessfullyToPrepare ) {
        if ( completionHandler ) completionHandler(NO);
        return;
    }
    
    [self _willSeekingToTime:time];
    
    __weak typeof(self) _self = self;
    [super seekToTime:time toleranceBefore:toleranceBefore toleranceAfter:toleranceAfter completionHandler:^(BOOL finished) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(_self) self = _self;
            if ( !self ) return;
            [self _didEndSeeking];
            if ( completionHandler ) completionHandler(finished);
        });
    }];
}
- (void)_willSeekingToTime:(CMTime)time {
    if ( _sj_playbackInfo->seekingInfo.isSeeking ) {
        [self.currentItem cancelPendingSeeks];
    }
    _sj_playbackInfo->seekingInfo.isSeeking = YES;
    _sj_playbackInfo->seekingInfo.time = time;
    if ( _sj_playbackInfo->isPrerolling )
        [self pause];
}
- (void)_didEndSeeking {
    if ( _sj_playbackInfo->isPrerolling )
        [self play];
    _sj_playbackInfo->seekingInfo.isSeeking = NO;
    _sj_playbackInfo->seekingInfo.time = kCMTimeZero;
}
- (NSTimeInterval)sj_getDuration {
    return _sj_playbackInfo->duration;
}
- (NSTimeInterval)sj_getCurrentPlaybackTime {
    if ( _sj_playbackInfo->seekingInfo.isSeeking )
        return CMTimeGetSeconds(_sj_playbackInfo->seekingInfo.time);
    return CMTimeGetSeconds(self.currentTime);
}

- (NSError *_Nullable)sj_getError {
    return _sj_error;
}
- (SJVideoPlayerPlayStatus)sj_playbackStatus {
    if      ( _sj_playbackInfo->isPlayedToEndTime )
        return SJVideoPlayerPlayStatusInactivity;
    else if ( _sj_playbackInfo->prepareStatus == SJAVMediaPrepareStatusUnknown )
        return SJVideoPlayerPlayStatusUnknown;
    else if ( _sj_playbackInfo->prepareStatus == SJAVMediaPrepareStatusPreparing )
        return SJVideoPlayerPlayStatusPrepare;
    else if ( _sj_playbackInfo->prepareStatus == SJAVMediaPrepareStatusFailedToPrepare )
        return SJVideoPlayerPlayStatusInactivity;
    else if ( _sj_playbackInfo->isError )
        return SJVideoPlayerPlayStatusInactivity;
    else if ( _sj_playbackInfo->seekingInfo.isSeeking )
        return SJVideoPlayerPlayStatusPaused;
    else if ( [self _sj_isPlaying] )
        return SJVideoPlayerPlayStatusPlaying;
    
    return SJVideoPlayerPlayStatusPaused;
}
- (SJVideoPlayerPausedReason)sj_pausedReason {
    if      ( [self sj_playbackStatus] != SJVideoPlayerPlayStatusPaused )
        return SJVideoPlayerPausedReasonUnknown;
    else if ( _sj_playbackInfo->seekingInfo.isSeeking )
        return SJVideoPlayerPausedReasonSeeking;
    else if ( [self sj_bufferStatus] == SJPlayerBufferStatusUnplayable && !_sj_playbackInfo->isPaused )
        return SJVideoPlayerPausedReasonBuffering;
    
    return SJVideoPlayerPausedReasonPause;
}
- (SJVideoPlayerInactivityReason)sj_inactivityReason {
    if      ( [self sj_playbackStatus] != SJVideoPlayerPlayStatusInactivity )
        return SJVideoPlayerInactivityReasonUnknown;
    else if ( _sj_playbackInfo->isPlayedToEndTime )
        return SJVideoPlayerInactivityReasonPlayEnd;
    else if ( _sj_playbackInfo->isError )
        return SJVideoPlayerInactivityReasonPlayFailed;
    else if ( [self sj_bufferStatus] == SJPlayerBufferStatusUnplayable && SJReachability.shared.networkStatus == SJNetworkStatus_NotReachable )
        return SJVideoPlayerInactivityReasonNotReachableAndPlaybackStalled;
    
    return SJVideoPlayerInactivityReasonPlayEnd;
}
- (SJPlayerBufferStatus)sj_bufferStatus {
    AVPlayerItem *item = self.currentItem;
    
    if      ( _sj_playbackInfo->seekingInfo.isSeeking )
        return SJPlayerBufferStatusUnplayable;
    else if ( [self _sj_isPlaying] )
        return SJPlayerBufferStatusPlayable;
    else if ( [item isPlaybackBufferFull] )
        return SJPlayerBufferStatusPlayable;
    else if ( [item isPlaybackLikelyToKeepUp] )
        return SJPlayerBufferStatusPlayable;
    else if ( [item isPlaybackBufferEmpty] )
        return SJPlayerBufferStatusUnplayable;
    
    return SJPlayerBufferStatusUnknown;
}
@end

NS_ASSUME_NONNULL_END
