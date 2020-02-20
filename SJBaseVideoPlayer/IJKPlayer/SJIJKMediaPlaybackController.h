//
//  SJIJKMediaPlaybackController.h
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2019/10/12.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJMediaPlaybackController.h"
#import "SJIJKMediaPlayer.h"
@class IJKFFOptions;

NS_ASSUME_NONNULL_BEGIN
@interface SJIJKMediaPlaybackController : SJMediaPlaybackController

@property (nonatomic, strong, null_resettable) IJKFFOptions *options;

@property (nonatomic, strong, readonly, nullable) SJIJKMediaPlayer *currentPlayer;

@end
NS_ASSUME_NONNULL_END
