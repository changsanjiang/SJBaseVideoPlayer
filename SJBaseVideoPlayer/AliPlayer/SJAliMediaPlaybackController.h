//
//  SJAliMediaPlaybackController.h
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2019/11/7.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

#import "SJMediaPlaybackController.h"
#import "SJVideoPlayerURLAsset+SJAliMediaPlaybackAdd.h"
#import "SJAliMediaPlayer.h"
#import <AliyunPlayer/AVPDef.h>

NS_ASSUME_NONNULL_BEGIN
@interface SJAliMediaPlaybackController : SJMediaPlaybackController
@property (nonatomic) AVPSeekMode seekMode;
@property (nonatomic, strong, readonly, nullable) SJAliMediaPlayer *currentPlayer;
@end
NS_ASSUME_NONNULL_END
