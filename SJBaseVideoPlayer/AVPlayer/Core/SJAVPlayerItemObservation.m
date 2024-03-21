//
//  SJAVPlayerItemObservation.m
//  player
//
//  Created by 畅三江 on 2023/8/8.
//

#import "SJAVPlayerItemObservation.h"

static NSString *kStatus = @"status";
static NSString *kLoadedTimeRanges = @"loadedTimeRanges";

@implementation SJAVPlayerItemObservation {
    AVAsset *_asset;
    AVPlayerItem *_playerItem;
}

- (instancetype)initWithPlayerItem:(AVPlayerItem *)playerItem observer:(id<SJAVPlayerItemObserver>)observer {
    self = [super init];
    _asset = playerItem.asset;
    _playerItem = playerItem;
    _observer = observer;
    [self _registerObserver];
    return self;
}

- (void)dealloc {
    [_playerItem removeObserver:self forKeyPath:kStatus context:&kStatus];
    [_playerItem removeObserver:self forKeyPath:kLoadedTimeRanges context:&kLoadedTimeRanges];
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)_registerObserver {
    NSKeyValueObservingOptions options = NSKeyValueObservingOptionNew;
    [_playerItem addObserver:self forKeyPath:kStatus options:options context:&kStatus];
    [_playerItem addObserver:self forKeyPath:kLoadedTimeRanges options:options context:&kLoadedTimeRanges];

    __weak typeof(self) _self = self;
    [NSNotificationCenter.defaultCenter addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        __strong typeof(_self) self = _self;
        if ( self == nil ) return;
        [self playerItemDidPlayToEndTime:note];
    }];
    
    [NSNotificationCenter.defaultCenter addObserverForName:AVPlayerItemNewAccessLogEntryNotification object:_playerItem queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            __strong typeof(_self) self = _self;
            if ( self == nil ) return;
            [self newAccessLogDidEntry:note];
        });
    }];

}

- (void)newAccessLogDidEntry:(NSNotification *)note {
#ifdef SJDEBUG
     NSLog(@"NOTIFY: note: %@, isMainThread: %d", note, NSThread.currentThread.isMainThread);
#endif
    [_observer playerItemNewAccessLogDidEntry:_playerItem];
}

- (void)playerItemDidPlayToEndTime:(NSNotification *)note {
#ifdef SJDEBUG
     NSLog(@"NOTIFY: note: %@, isMainThread: %d", note, NSThread.currentThread.isMainThread);
#endif
    [_observer playerItem:_playerItem didPlayToEndTime:note];
}

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context {
#ifdef SJDEBUG
     NSLog(@"KVO_CHANGE: keyPath: %@, object: %@, value: %@", keyPath, [object class], [object valueForKey:keyPath]);
#endif
    id newValue = change[NSKeyValueChangeNewKey];
    BOOL isNonNull = newValue != nil && ![newValue isKindOfClass:NSNull.class];
    if      ( context == &kStatus ) {
        [_observer playerItem:_playerItem statusDidChange:isNonNull ? [newValue integerValue] : _playerItem.status];
    }
    else if ( context == &kLoadedTimeRanges ) {
        [_observer playerItem:_playerItem loadedTimeRangesDidChange:isNonNull ? newValue : _playerItem.loadedTimeRanges];
    }
}
@end
