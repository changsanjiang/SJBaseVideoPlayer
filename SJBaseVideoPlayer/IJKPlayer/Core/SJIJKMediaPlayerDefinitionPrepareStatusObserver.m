//
//  SJIJKMediaPlayerDefinitionPrepareStatusObserver.m
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2019/10/16.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

#import "SJIJKMediaPlayerDefinitionPrepareStatusObserver.h"
#import "SJIJKMediaPlayer.h"

NS_ASSUME_NONNULL_BEGIN
@implementation SJIJKMediaPlayerDefinitionPrepareStatusObserver
- (instancetype)initWithPlayer:(SJIJKMediaPlayer *)player {
    self = [super init];
    if ( self ) {
        _player = player;
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(statusDidChange) name:SJIJKMediaPlayerAssetStatusDidChangeNotification object:player];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(statusDidChange) name:SJIJKMediaPlayerReadyForDisplayNotification object:player];
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)statusDidChange {
    if ( _statusDidChangeExeBlock ) _statusDidChangeExeBlock(self);
}
@end
NS_ASSUME_NONNULL_END
