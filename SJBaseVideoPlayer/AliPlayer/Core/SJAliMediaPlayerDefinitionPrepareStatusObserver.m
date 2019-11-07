//
//  SJAliMediaPlayerDefinitionPrepareStatusObserver.m
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2019/11/7.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

#import "SJAliMediaPlayerDefinitionPrepareStatusObserver.h"
#import "SJAliMediaPlayer.h"

NS_ASSUME_NONNULL_BEGIN
@implementation SJAliMediaPlayerDefinitionPrepareStatusObserver
- (instancetype)initWithPlayer:(SJAliMediaPlayer *)player {
    self = [super init];
    if ( self ) {
        _player = player;
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(statusDidChange) name:SJAliMediaPlayerAssetStatusDidChangeNotification object:player];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(statusDidChange) name:SJAliMediaPlayerReadyForDisplayNotification object:player];
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
