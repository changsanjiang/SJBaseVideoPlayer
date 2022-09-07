//
//  SJIJKMediaPlayer.h
//  SJBaseVideoPlayer.common-IJKPlayer
//
//  Created by 畅三江 on 2022/8/15.
//

#import "SJMediaPlaybackController.h"
@class IJKFFOptions;

NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXTERN NSErrorDomain const SJIJKMediaPlayerErrorDomain;

@interface SJIJKMediaPlayer : NSObject<SJMediaPlayer>
- (instancetype)initWithURL:(NSURL *)URL startPosition:(NSTimeInterval)startPosition options:(IJKFFOptions *)ops;

@property (nonatomic, readonly, strong) NSURL *URL;

@property (nonatomic) NSTimeInterval trialEndPosition;

@property (nonatomic) BOOL pauseWhenAppDidEnterBackground;

@property (nonatomic, readonly) BOOL firstVideoFrameRendered;

@property (nonatomic, readonly) UIView *view;

@property (nonatomic) SJVideoGravity videoGravity;
@end
NS_ASSUME_NONNULL_END
