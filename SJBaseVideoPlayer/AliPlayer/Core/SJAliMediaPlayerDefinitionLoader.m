//
//  SJAliMediaPlayerDefinitionLoader.m
//  SJBaseVideoPlayer
//
//  Created by BlueDancer on 2019/11/20.
//

#import "SJAliMediaPlayerDefinitionLoader.h"

NS_ASSUME_NONNULL_BEGIN
@interface SJAliMediaPlayerDefinitionLoader ()
@property (nonatomic, strong) SJAliMediaPlayer *innerPlayer;
@end

@implementation SJAliMediaPlayerDefinitionLoader {
    void(^_completionHandler)(SJAliMediaPlayerDefinitionLoader *loader);
    BOOL _isSeeking;
}

- (instancetype)initWithSource:(__kindof AVPSource *)source dataSource:(id<SJAliMediaPlayerDefinitionLoaderDataSource>)dataSource completionHandler:(void(^)(SJAliMediaPlayerDefinitionLoader *loader))completionHandler {
    self = [super init];
    if ( self ) {
        _source = source;
        _completionHandler = completionHandler;
        _dataSource = dataSource;
        
        UIView *superview = self.dataSource.superview;
        _innerPlayer = [SJAliMediaPlayer.alloc initWithSource:source specifyStartTime:0];
        _innerPlayer.seekMode = AVP_SEEKMODE_ACCURATE;
        _innerPlayer.shouldAutoplay = YES;
        _innerPlayer.muted = YES;
        _innerPlayer.view.frame = superview.bounds;
        _innerPlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [superview insertSubview:_innerPlayer.view atIndex:0];
        [_innerPlayer play];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_statusDidChange) name:SJAliMediaPlayerAssetStatusDidChangeNotification object:_innerPlayer];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_statusDidChange) name:SJAliMediaPlayerReadyForDisplayNotification object:_innerPlayer];
    }
    return self;
}

- (void)_statusDidChange {
    switch ( _innerPlayer.assetStatus ) {
        case SJAssetStatusUnknown:
        case SJAssetStatusPreparing:
            break;
        case SJAssetStatusReadyToPlay: {
            if ( _innerPlayer.isReadyForDisplay && _isSeeking == NO ) {
                [self _seekToCurPos];
            }
        }
            break;
        case SJAssetStatusFailed:
            [self _didCompleteLoad:NO];
            break;
    }
}

- (void)_seekToCurPos {
    _isSeeking = YES;
    __weak typeof(self) _self = self;
    [_innerPlayer seekToTime:self.dataSource.player ? CMTimeMakeWithSeconds(self.dataSource.player.currentTime, NSEC_PER_SEC) : kCMTimeZero completionHandler:^(BOOL finished) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        [self _didCompleteLoad:finished];
    }];
}

- (void)_didCompleteLoad:(BOOL)result {
    if ( result ) {
        [_innerPlayer.view removeFromSuperview];
        _innerPlayer.view.alpha = 1;
        _innerPlayer.muted = NO;
        _player = _innerPlayer;
    }
    else {
        [_innerPlayer.view removeFromSuperview];
        [_innerPlayer pause];
        _innerPlayer = nil;
    }
    if ( _completionHandler ) _completionHandler(self);
    _completionHandler = nil;
}

- (void)cancel {
    _completionHandler = nil;
    [_innerPlayer.view removeFromSuperview];
    _innerPlayer = nil;
}
@end
NS_ASSUME_NONNULL_END

