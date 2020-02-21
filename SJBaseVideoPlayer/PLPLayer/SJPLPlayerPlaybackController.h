//
//  SJPLPlayerPlaybackController.h
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2020/2/20.
//  Copyright © 2020 changsanjiang. All rights reserved.
//

#import "SJMediaPlaybackController.h"
#import <PLPlayerKit/PLPlayerKit.h>
#import "SJPLMediaPlayer.h"
#import "SJVideoPlayerURLAsset+SJPLMediaPlaybackAdd.h"

NS_ASSUME_NONNULL_BEGIN
@interface SJPLPlayerPlaybackController : SJMediaPlaybackController
@property (nonatomic, getter=isAutoReconnectEnable) BOOL autoReconnectEnable;

@property (nonatomic, strong, readonly, nullable) SJPLMediaPlayer *currentPlayer;
@end
NS_ASSUME_NONNULL_END
