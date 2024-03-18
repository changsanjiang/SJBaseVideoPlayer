//
//  SJAVMediaPlayer.m
//  SJBaseVideoPlayer
//
//  Created by 畅三江 on 2024/3/18.
//

#import "SJAVMediaPlayer.h"
#import "AVAsset+SJAVMediaExport.h"
#import "NSTimer+SJAssetAdd.h"
#import "SJAVPlayerItemObservation.h"
#import "SJAVPlayerObservation.h"
#import "SJApplicationObservation.h"

@interface SJAVMediaPlayer ()<SJAVPlayerItemObserver, SJAVPlayerObserver, SJApplicationObserver> {
    NSTimeInterval mStartPosition;
    AVPlayer *mPlayer;
    
    SJAVPlayerObservation *mPlayerObservation;
    SJAVPlayerItemObservation *mPlayerItemObservation;
    SJApplicationObservation *mAppObservation;
    SJSeekingInfo mSeekingInfo;
    SJFinishedReason mFinishedReason;
    NSTimeInterval mPlayableDuration;
    id _Nullable mTimeObserver;
    CMTime mLastTimePosition;
    BOOL mNeedsFixTimePosition;
    BOOL mReplayed; // 是否调用过`replay`方法
    BOOL mPlayed; // 是否调用过`play`方法
    BOOL mPlaybackFinished;
}
@end

@implementation SJAVMediaPlayer

- (instancetype)initWithAVPlayer:(AVPlayer *)player startPosition:(NSTimeInterval)time {
    self = [super init];
    _rate = 1;
    _minBufferedDuration = 8;
    if      ( @available(iOS 15.0, *) ) { }
    else if ( @available(iOS 14.0, *) ) {
        player.currentItem.preferredForwardBufferDuration = 5.0;
    }
    mStartPosition = time;
    mPlayer = player;
    if ( time != 0 ) {
        mNeedsFixTimePosition = time != 0;
        mLastTimePosition = CMTimeMakeWithSeconds(time, NSEC_PER_SEC);
    }
    
    mPlayerItemObservation = [SJAVPlayerItemObservation.alloc initWithPlayerItem:player.currentItem observer:self];
    mPlayerObservation = [SJAVPlayerObservation.alloc initWithPlayer:player observer:self];
    mAppObservation = [SJApplicationObservation.alloc initWithObserver:self];
    return self;
}

- (void)dealloc {
    if ( mTimeObserver != nil ) [mPlayer removeTimeObserver:mTimeObserver];
    if ( mSeekingInfo.isSeeking ) [mPlayer.currentItem cancelPendingSeeks];
}

- (AVPlayer *)avPlayer {
    return mPlayer;
}

- (nullable NSError *)error {
    return mPlayer.error ?: mPlayer.currentItem.error;
}

- (nullable SJWaitingReason)reasonForWaitingToPlay {
    if ( mPlayer.reasonForWaitingToPlay == AVPlayerWaitingToMinimizeStallsReason ) return SJWaitingToMinimizeStallsReason;
    if ( mPlayer.reasonForWaitingToPlay == AVPlayerWaitingWhileEvaluatingBufferingRateReason ) return SJWaitingWhileEvaluatingBufferingRateReason;
    if ( mPlayer.reasonForWaitingToPlay == AVPlayerWaitingWithNoItemToPlayReason ) return SJWaitingWithNoAssetToPlayReason;
    return nil;
}

- (SJPlaybackTimeControlStatus)timeControlStatus {
    switch (mPlayer.timeControlStatus) {
        case AVPlayerTimeControlStatusPaused: return SJPlaybackTimeControlStatusPaused;
        case AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate: return SJPlaybackTimeControlStatusWaitingToPlay;
        case AVPlayerTimeControlStatusPlaying: return SJPlaybackTimeControlStatusPlaying;
    }
    return SJPlaybackTimeControlStatusPaused;
}

- (SJAssetStatus)assetStatus {
    switch ( mPlayer.status ) {
        case AVPlayerStatusUnknown: return SJAssetStatusUnknown;
        case AVPlayerStatusReadyToPlay: break;
        case AVPlayerStatusFailed: return SJAssetStatusFailed;
    }
    switch ( mPlayer.currentItem.status ) {
        case AVPlayerItemStatusUnknown: return SJAssetStatusUnknown;
        case AVPlayerItemStatusReadyToPlay: return SJAssetStatusReadyToPlay;
        case AVPlayerItemStatusFailed: return SJAssetStatusFailed;
    }
    return SJAssetStatusUnknown;
}

- (SJSeekingInfo)seekingInfo {
    return mSeekingInfo;
}

- (CGSize)presentationSize {
    return mPlayer.currentItem.presentationSize;
}

- (BOOL)isReplayed {
    return mReplayed;
}

- (BOOL)isPlayed {
    return mPlayed;
}

- (BOOL)isPlaybackFinished {
    return mPlaybackFinished;
}

- (SJFinishedReason)finishedReason {
    return mFinishedReason;
}

// 试用结束的位置, 单位秒
@synthesize trialEndPosition = _trialEndPosition;
- (void)setTrialEndPosition:(NSTimeInterval)trialEndPosition {
    if ( trialEndPosition != _trialEndPosition ) {
        _trialEndPosition = trialEndPosition;
        [self _onTrailEndPositionChanged];
    }
}

@synthesize rate = _rate;
- (void)setRate:(float)rate {
    if ( rate != _rate ) {
        _rate = rate;
        if ( self.timeControlStatus != SJPlaybackTimeControlStatusPaused ) mPlayer.rate = rate;
        [self _postNotification:SJMediaPlayerRateDidChangeNotification];
    }
}

- (void)setVolume:(float)volume {
    mPlayer.volume = volume;
    [self _postNotification:SJMediaPlayerVolumeDidChangeNotification];
}
- (float)volume {
    return mPlayer.volume;
}
 
- (void)setMuted:(BOOL)muted {
    mPlayer.muted = muted;
    [self _postNotification:SJMediaPlayerMutedDidChangeNotification];
}
- (BOOL)isMuted {
    return mPlayer.isMuted;
}

- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL))completionHandler {
    CMTime tolerance = _accurateSeeking ? kCMTimeZero : kCMTimePositiveInfinity;
    [self seekToTime:time toleranceBefore:tolerance toleranceAfter:tolerance completionHandler:completionHandler];
}

- (void)seekToTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter completionHandler:(void (^)(BOOL))completionHandler {
    if ( self.assetStatus != SJAssetStatusReadyToPlay ) {
        if ( completionHandler != nil ) completionHandler(NO);
        return;
    }
    
    time = [self _adjustSeekTimeIfNeeded:time];
    
    [self _willSeeking:time];
    __weak typeof(self) _self = self;
    [mPlayer seekToTime:time toleranceBefore:toleranceBefore toleranceAfter:toleranceAfter completionHandler:^(BOOL finished) {
        __strong typeof(_self) self = _self;
        if ( self == nil ) return;
        [self _didEndSeeking];
        if ( completionHandler != nil ) completionHandler(finished);
    }];
}

- (NSTimeInterval)currentTime {
    if ( mSeekingInfo.isSeeking ) return CMTimeGetSeconds(mSeekingInfo.time);
    AVPlayerItem *playerItem = mPlayer.currentItem;
    return playerItem.status == AVPlayerStatusReadyToPlay ? CMTimeGetSeconds(playerItem.currentTime) : 0;
}

- (NSTimeInterval)duration {
    AVPlayerItem *playerItem = mPlayer.currentItem;
    return playerItem.status == AVPlayerStatusReadyToPlay ? CMTimeGetSeconds(playerItem.duration) : 0;
}

- (NSTimeInterval)playableDuration {
    return mPlayableDuration;
}

- (void)play {
    if ( mPlaybackFinished ) [self replay];
    else {
        mPlayed = YES;
        [mPlayer playImmediatelyAtRate:_rate];
    }
}
- (void)pause {
    [mPlayer pause];
}

- (void)replay {
    if ( self.assetStatus == SJAssetStatusFailed ) return;
    
    mReplayed = YES;
    __weak typeof(self) _self = self;
    [self seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        __strong typeof(_self) self = _self;
        if ( self == nil ) return;
        [self _postNotification:SJMediaPlayerDidReplayNotification];
        [self play];
    }];
}
- (void)report {
    [self _postNotification:SJMediaPlayerAssetStatusDidChangeNotification];
    [self _postNotification:SJMediaPlayerTimeControlStatusDidChangeNotification];
    [self _postNotification:SJMediaPlayerDurationDidChangeNotification];
    [self _postNotification:SJMediaPlayerPlayableDurationDidChangeNotification];
    [self _postNotification:SJMediaPlayerPlaybackTypeDidChangeNotification];
}

- (nullable UIImage *)screenshot {
    return [mPlayer.currentItem.asset sj_screenshotWithTime:mPlayer.currentTime];
}

#pragma mark - SJApplicationObserver

- (void)onReceivedApplicationDidEnterBackgroundNotification {
    if ( _pauseWhenAppDidEnterBackground ) {
        [self pause];
        
        if      ( @available(iOS 15.0, *) ) { }
        else if ( @available(iOS 14.0, *) ) {
            if ( self.assetStatus == SJAssetStatusReadyToPlay ) {
                // Fix: https://github.com/changsanjiang/SJVideoPlayer/issues/535
                // Fix: https://github.com/changsanjiang/SJVideoPlayer/issues/339
                mLastTimePosition = mPlayer.currentTime;
                mNeedsFixTimePosition = YES;
            }
        }
    }
}
- (void)onReceivedApplicationDidBecomeActiveNotification {
    if      ( @available(iOS 15.0, *) ) { }
    else if ( @available(iOS 14.0, *) ) {
        // Fix: https://github.com/changsanjiang/SJVideoPlayer/issues/535
        // Fix: https://github.com/changsanjiang/SJVideoPlayer/issues/339
        if ( mNeedsFixTimePosition ) mPlayer.currentItem.preferredForwardBufferDuration = 5.0;
    }
}

#pragma mark - SJAVPlayerItemObserver, SJAVPlayerObserver

- (void)playerItem:(AVPlayerItem *)playerItem statusDidChange:(AVPlayerItemStatus)playerItemStatus {
    if ( playerItemStatus == AVPlayerItemStatusReadyToPlay && mNeedsFixTimePosition ) {
        mNeedsFixTimePosition = NO;
        [playerItem seekToTime:mLastTimePosition toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:nil];
    }
    
    [self _postNotification:SJMediaPlayerAssetStatusDidChangeNotification];
    if ( self.assetStatus == SJAssetStatusReadyToPlay ) {
        [self _postNotification:SJMediaPlayerPresentationSizeDidChangeNotification];
        [self _postNotification:SJMediaPlayerDurationDidChangeNotification];
    }
}
- (void)playerItem:(AVPlayerItem *)playerItem loadedTimeRangesDidChange:(NSArray<NSValue *> *)loadedTimeRanges {
    if ( loadedTimeRanges.count > 0 ) {
        CMTimeRange bufferRange = [[loadedTimeRanges firstObject] CMTimeRangeValue];
        CMTime currentTime = playerItem.currentTime;
        if ( CMTimeRangeContainsTime(bufferRange, currentTime) ) {
            NSTimeInterval playableDuration = CMTimeGetSeconds(CMTimeRangeGetEnd(bufferRange));
            if ( playableDuration != mPlayableDuration ) {
                mPlayableDuration = playableDuration;
                [self _onPlayableDurationChanged:playableDuration];
            }
        }
    }
}
- (void)playerItem:(AVPlayerItem *)playerItem didPlayToEndTime:(NSNotification *)notification {
    mFinishedReason = SJFinishedReasonToEndTimePosition;
    mPlaybackFinished = YES;
    [self pause];
    [self _postNotification:SJMediaPlayerPlaybackDidFinishNotification];
}

- (void)playerItemNewAccessLogDidEntry:(AVPlayerItem *)playerItem {
    __auto_type event = playerItem.accessLog.events.firstObject;
    __auto_type type = SJPlaybackTypeUnknown;
    if ( [event.playbackType isEqualToString:@"LIVE"] ) {
        type = SJPlaybackTypeLIVE;
    }
    else if ( [event.playbackType isEqualToString:@"VOD"] ) {
        type = SJPlaybackTypeVOD;
    }
    else if ( [event.playbackType isEqualToString:@"FILE"] ) {
        type = SJPlaybackTypeFILE;
    }
    __weak typeof(self) _self = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(_self) self = _self;
        if ( self == nil ) return;
        if ( type != self->_playbackType ) {
            self->_playbackType = type;
            [self _postNotification:SJMediaPlayerPlaybackTypeDidChangeNotification];
        }
    });
}

- (void)player:(AVPlayer *)player playerStatusDidChange:(AVPlayerStatus)playerStatus {
    [self _postNotification:SJMediaPlayerAssetStatusDidChangeNotification];
}
- (void)player:(AVPlayer *)player playerTimeControlStatusDidChange:(AVPlayerTimeControlStatus)timeControlStatus API_AVAILABLE(ios(10.0)) {
    [self _postNotification:SJMediaPlayerTimeControlStatusDidChangeNotification];
}
- (void)player:(AVPlayer *)player reasonForWaitingToPlayDidChange:(nullable AVPlayerWaitingReason)reasonForWaitingToPlay API_AVAILABLE(ios(10.0)) {
    
}

#pragma mark - mark

- (void)_onTrailEndPositionChanged {
    if ( _trialEndPosition != 0 ) {
        if ( mTimeObserver == nil ) {
            __weak typeof(self) _self = self;
            mTimeObserver = [mPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.5, NSEC_PER_SEC) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
                __strong typeof(_self) self = _self;
                if ( self == nil ) return;
                [self _onCheckTrailEndPosition:CMTimeGetSeconds(time)];
            }];
        }
        [self _onCheckTrailEndPosition:self.currentTime];
    }
    else if ( mTimeObserver != nil ) {
        [mPlayer removeTimeObserver:mTimeObserver];
        mTimeObserver = nil;
    }
}

- (void)_onCheckTrailEndPosition:(NSTimeInterval)currentTime {
    if ( _trialEndPosition != 0 && currentTime >= _trialEndPosition ) {
        mFinishedReason = SJFinishedReasonToTrialEndPosition;
        mPlaybackFinished = YES;
        [self pause];
        [self _postNotification:SJMediaPlayerPlaybackDidFinishNotification];
    }
}

- (void)_onPlayableDurationChanged:(NSTimeInterval)playableDuration {
    if ( self.timeControlStatus == SJPlaybackTimeControlStatusWaitingToPlay ) {
        NSTimeInterval currentTime = self.currentTime;
        if ( (playableDuration - currentTime) >= _minBufferedDuration ) {
            [self play];
        }
    }
    
    [self _postNotification:SJMediaPlayerPlayableDurationDidChangeNotification];
}

- (CMTime)_adjustSeekTimeIfNeeded:(CMTime)time {
    if ( _trialEndPosition != 0 && CMTimeGetSeconds(time) >= _trialEndPosition ) {
        time = CMTimeMakeWithSeconds(_trialEndPosition * 0.98, NSEC_PER_SEC);
    }
    return time;
}

- (void)_willSeeking:(CMTime)time {
    [mPlayer.currentItem cancelPendingSeeks];
    
    mPlaybackFinished = NO;
    mSeekingInfo.time = time;
    mSeekingInfo.isSeeking = YES;
}

- (void)_didEndSeeking {
    mSeekingInfo.time = kCMTimeZero;
    mSeekingInfo.isSeeking = NO;
}

- (void)_postNotification:(NSNotificationName)name {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSNotificationCenter.defaultCenter postNotificationName:name object:self];
    });
}
@end
