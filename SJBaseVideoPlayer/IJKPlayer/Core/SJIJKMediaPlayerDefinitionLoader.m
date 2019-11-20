//
//  SJIJKMediaPlayerDefinitionLoader.m
//  SJBaseVideoPlayer
//
//  Created by BlueDancer on 2019/11/20.
//

#import "SJIJKMediaPlayerDefinitionLoader.h"

NS_ASSUME_NONNULL_BEGIN
@interface SJIJKMediaPlayerDefinitionLoader ()
@property (nonatomic, strong) SJIJKMediaPlayer *innerPlayer;
@end

@implementation SJIJKMediaPlayerDefinitionLoader {
    void(^_completionHandler)(SJIJKMediaPlayerDefinitionLoader *loader);
    BOOL _isSeeking;
}

- (instancetype)initWithURL:(NSURL *)URL options:(IJKFFOptions *)ops dataSource:(id<SJIJKMediaPlayerDefinitionLoaderDataSource>)dataSource completionHandler:(void(^)(SJIJKMediaPlayerDefinitionLoader *loader))completionHandler {
    self = [super init];
    if ( self ) {
        _URL = URL;
        _completionHandler = completionHandler;
        _dataSource = dataSource;
        
        UIView *superview = self.dataSource.superview;
        _innerPlayer = [SJIJKMediaPlayer.alloc initWithURL:URL specifyStartTime:0 options:ops];
        _innerPlayer.shouldAutoplay = YES;
        _innerPlayer.muted = YES;
        _innerPlayer.view.frame = superview.bounds;
        _innerPlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [superview insertSubview:_innerPlayer.view atIndex:0];
        [_innerPlayer play];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_statusDidChange) name:SJIJKMediaPlayerAssetStatusDidChangeNotification object:_innerPlayer];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_statusDidChange) name:SJIJKMediaPlayerReadyForDisplayNotification object:_innerPlayer];
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
    [_innerPlayer seekToTime:self.dataSource.player ? CMTimeMakeWithSeconds(self.dataSource.player.currentPlaybackTime, NSEC_PER_SEC) : kCMTimeZero completionHandler:^(BOOL finished) {
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
        [_innerPlayer stop];
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
