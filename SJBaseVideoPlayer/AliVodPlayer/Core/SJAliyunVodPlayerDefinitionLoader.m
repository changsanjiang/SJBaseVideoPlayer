//
//  SJAliyunVodPlayerDefinitionLoader.m
//  SJBaseVideoPlayer
//
//  Created by BlueDancer on 2019/11/20.
//

#import "SJAliyunVodPlayerDefinitionLoader.h"

NS_ASSUME_NONNULL_BEGIN
@interface SJAliyunVodPlayerDefinitionLoader ()
@property (nonatomic, strong) SJAliyunVodPlayer *innerPlayer;
@end

@implementation SJAliyunVodPlayerDefinitionLoader {
    void(^_completionHandler)(SJAliyunVodPlayerDefinitionLoader *loader);
    BOOL _isSeeking;
}

- (instancetype)initWithMedia:(__kindof SJAliyunVodModel *)media dataSource:(id<SJAliyunVodPlayerDefinitionLoaderDataSource>)dataSource completionHandler:(void(^)(SJAliyunVodPlayerDefinitionLoader *loader))completionHandler {
    self = [super init];
    if ( self ) {
        _media = media;
        _completionHandler = completionHandler;
        _dataSource = dataSource;
        
        UIView *superview = self.dataSource.superview;
        _innerPlayer = [SJAliyunVodPlayer.alloc initWithMedia:media specifyStartTime:0];
        _innerPlayer.shouldAutoplay = YES;
        _innerPlayer.muted = YES;
        _innerPlayer.view.frame = superview.bounds;
        _innerPlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [superview insertSubview:_innerPlayer.view atIndex:0];
        [_innerPlayer play];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_statusDidChange) name:SJAliyunVodPlayerAssetStatusDidChangeNotification object:_innerPlayer];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_statusDidChange) name:SJAliyunVodPlayerReadyForDisplayNotification object:_innerPlayer];
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
