//
//  SJAliMediaPlayer.h
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2019/11/7.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

#import "SJMediaPlaybackController.h"
#import <AliyunPlayer/AVPSource.h>
#import <AliyunPlayer/AVPDef.h>

NS_ASSUME_NONNULL_BEGIN
///
/// 内部封装了 AliPlayer
///
@interface SJAliMediaPlayer : NSObject<SJMediaPlayer>
- (instancetype)initWithSource:(__kindof AVPSource *)source startPosition:(NSTimeInterval)time;

@property (nonatomic) NSTimeInterval trialEndPosition;
@property (nonatomic) BOOL pauseWhenAppDidEnterBackground;
@property (nonatomic) AVPScalingMode scalingMode;
@property (nonatomic) AVPSeekMode seekMode;

@property (nonatomic, strong, readonly) __kindof AVPSource *source;
@property (nonatomic, readonly) BOOL firstVideoFrameRendered;
@property (nonatomic, strong, readonly) UIView *view;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end
NS_ASSUME_NONNULL_END
