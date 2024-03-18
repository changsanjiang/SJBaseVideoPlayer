//
//  SJAVPlayerObservation.m
//  player
//
//  Created by 畅三江 on 2023/8/7.
//

#import "SJAVPlayerObservation.h"

static NSString *kStatus = @"status";
static NSString *kTimeControlStatus = @"timeControlStatus";
static NSString *kReasonForWaitingToPlay = @"reasonForWaitingToPlay";

@implementation SJAVPlayerObservation {
    AVPlayer *_player;
}
- (instancetype)initWithPlayer:(AVPlayer *)player observer:(nonnull id<SJAVPlayerObserver>)observer {
    self = [super init];
    _player = player;
    _observer = observer;
    [self _registerObserver];
    return self;
}

- (void)dealloc {
    [_player removeObserver:self forKeyPath:kStatus context:&kStatus];
    if ( @available(iOS 10.0, *) ) {
        [_player removeObserver:self forKeyPath:kTimeControlStatus context:&kTimeControlStatus];
        [_player removeObserver:self forKeyPath:kReasonForWaitingToPlay context:&kReasonForWaitingToPlay];
    }
}

- (void)_registerObserver {
    NSKeyValueObservingOptions options = NSKeyValueObservingOptionNew;
    [_player addObserver:self forKeyPath:kStatus options:options context:&kStatus];
    if ( @available(iOS 10.0, *) ) {
        [_player addObserver:self forKeyPath:kTimeControlStatus options:options context:&kTimeControlStatus];
        [_player addObserver:self forKeyPath:kReasonForWaitingToPlay options:options context:&kReasonForWaitingToPlay];
    }
}

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context {
#ifdef SJDEBUG
    NSLog(@"KVO_CHANGE: keyPath: %@, object: %@, value: %@", keyPath, [object class], [object valueForKey:keyPath]);
#endif
    id newValue = change[NSKeyValueChangeNewKey];
    BOOL isNonNull = newValue != nil && ![newValue isKindOfClass:NSNull.class];
    
    if      ( context == &kStatus ) {
        [_observer player:_player playerStatusDidChange:isNonNull ? [newValue integerValue] : _player.status];
    }
    else if ( @available(iOS 10.0, *) ) {
        if ( context == &kTimeControlStatus ) {
            [_observer player:_player playerTimeControlStatusDidChange:isNonNull ? [newValue integerValue] : _player.timeControlStatus];
        }
        else if ( context == &kReasonForWaitingToPlay ) {
            [_observer player:_player reasonForWaitingToPlayDidChange:isNonNull ? newValue : _player.reasonForWaitingToPlay];
        }
    }
}
@end
