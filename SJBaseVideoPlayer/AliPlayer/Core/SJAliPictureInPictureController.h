//
//  SJAliPictureInPictureController.h
//  SJBaseVideoPlayer.common-AliPlayer-IJKPlayer
//
//  Created by 畅三江 on 2022/9/15.
//

#import "SJPictureInPictureControllerDefines.h"
@class SJAliMediaPlayer;

NS_ASSUME_NONNULL_BEGIN
/// 目前仅支持配置: canStartPictureInPictureAutomaticallyFromInline(App进入后台是否自动进入画中画)
///
API_AVAILABLE(ios(15.0)) @interface SJAliPictureInPictureController : NSObject<SJPictureInPictureController>
+ (BOOL)isPictureInPictureSupported;
- (instancetype)initWithPlayer:(SJAliMediaPlayer *)player delegate:(id<SJPictureInPictureControllerDelegate>)delegate;

@property (nonatomic, weak, readonly, nullable) SJAliMediaPlayer *player;

@property (nonatomic) BOOL requiresLinearPlayback;
@property (nonatomic) BOOL canStartPictureInPictureAutomaticallyFromInline;
@property (nonatomic, weak, nullable) id<SJPictureInPictureControllerDelegate> delegate;
@property (nonatomic, readonly) SJPictureInPictureStatus status;
- (void)startPictureInPicture;
- (void)stopPictureInPicture;
@end
NS_ASSUME_NONNULL_END
