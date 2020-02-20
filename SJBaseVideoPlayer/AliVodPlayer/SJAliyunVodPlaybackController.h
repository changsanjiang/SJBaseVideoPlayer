//
//  SJAliyunVodPlaybackController.h
//  Demo
//
//  Created by BlueDancer on 2019/11/13.
//  Copyright © 2019 SanJiang. All rights reserved.
//

#import "SJMediaPlaybackController.h"
#import "SJVideoPlayerURLAsset+SJAliyunVodPlaybackAdd.h"
#import "SJAliyunVodPlayer.h"

NS_ASSUME_NONNULL_BEGIN
@interface SJAliyunVodPlaybackController : SJMediaPlaybackController

@property (nonatomic, strong, readonly, nullable) SJAliyunVodPlayer *currentPlayer;

@end
NS_ASSUME_NONNULL_END
