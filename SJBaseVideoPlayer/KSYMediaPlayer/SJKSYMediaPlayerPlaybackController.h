//
//  SJKSYMediaPlayerPlaybackController.h
//  SJBaseVideoPlayer
//
//  Created by 畅三江 on 2021/9/9.
//

#import "SJMediaPlaybackController.h"
#import "SJKSYMediaPlayer.h"

NS_ASSUME_NONNULL_BEGIN
@interface SJKSYMediaPlayerPlaybackController : SJMediaPlaybackController

@property (nonatomic, strong, readonly, nullable) SJKSYMediaPlayer *currentPlayer;

@end
NS_ASSUME_NONNULL_END
