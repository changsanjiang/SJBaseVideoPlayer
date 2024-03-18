//
//  SJApplicationObservation.m
//  player
//
//  Created by 畅三江 on 2023/9/19.
//

#import "SJApplicationObservation.h"

@implementation SJApplicationObservation
- (instancetype)initWithObserver:(id<SJApplicationObserver>)observer {
    self = [super init];
    _observer = observer;
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didEnterBackgroundWithNote:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(willEnterForegroundWithNote:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didBecomeActiveWithNote:) name:UIApplicationDidBecomeActiveNotification object:nil];
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)didEnterBackgroundWithNote:(NSNotification *)note {
    if ( [_observer respondsToSelector:@selector(onReceivedApplicationDidEnterBackgroundNotification)] )
        [_observer onReceivedApplicationDidEnterBackgroundNotification];
}

- (void)willEnterForegroundWithNote:(NSNotification *)note {
    if ( [_observer respondsToSelector:@selector(onReceivedApplicationWillEnterForegroundNotification)] )
        [_observer onReceivedApplicationWillEnterForegroundNotification];
}

- (void)didBecomeActiveWithNote:(NSNotification *)note {
    if ( [_observer respondsToSelector:@selector(onReceivedApplicationDidBecomeActiveNotification)] )
        [_observer onReceivedApplicationDidBecomeActiveNotification];
}
@end
