//
//  SJKSYMediaPlayer.h
//  SJBaseVideoPlayer
//
//  Created by 畅三江 on 2021/9/9.
//

#import "SJMediaPlaybackController.h"
#import <MediaPlayer/MPMoviePlayerController.h>

typedef NS_ENUM(NSInteger, SJKSYMovieScalingMode) {
    SJKSYMovieScalingModeNone,       // No scaling
    SJKSYMovieScalingModeAspectFit,  // Uniform scale until one dimension fits
    SJKSYMovieScalingModeAspectFill, // Uniform scale until the movie fills the visible bounds. One dimension may have clipped contents
    SJKSYMovieScalingModeFill        // Non-uniform scale. Both render dimensions will exactly match the visible bounds
};

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSErrorDomain const SJKSYMediaPlayerErrorDomain;

/// 内部封装了 KSYMediaPlayer
///
///
@interface SJKSYMediaPlayer : NSObject<SJMediaPlayer>
- (instancetype)initWithURL:(NSURL *)URL startPosition:(NSTimeInterval)startPosition options:(nullable id)options;

@property (nonatomic) NSTimeInterval trialEndPosition;                          ///< 试用结束的位置, 单位秒
@property (nonatomic, strong, readonly) UIView *view;
@property (nonatomic) SJKSYMovieScalingMode scalingMode;
@property (nonatomic, readonly) BOOL firstVideoFrameRendered;
- (void)stop;
@end
NS_ASSUME_NONNULL_END
