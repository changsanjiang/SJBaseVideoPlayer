//
//  SJAliMediaPlayer.h
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2019/11/7.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

#import "SJMediaPlaybackController.h"
#import <AliyunPlayer/AVPMediaInfo.h>
#import <AliyunPlayer/AVPSource.h>
#import <AliyunPlayer/AVPConfig.h>
#import <AliyunPlayer/AVPDef.h>
#import <AliyunPlayer/AVPCacheConfig.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSErrorDomain const SJAliMediaPlayerErrorDomain;

///
/// 内部封装了 AliPlayer
///
@interface SJAliMediaPlayer : NSObject<SJMediaPlayer>
- (instancetype)initWithSource:(__kindof AVPSource *)source config:(nullable AVPConfig *)config cacheConfig:(nullable AVPCacheConfig *)cacheConfig startPosition:(NSTimeInterval)time;

@property (nonatomic) NSTimeInterval trialEndPosition;
@property (nonatomic) AVPScalingMode scalingMode;
@property (nonatomic) AVPSeekMode seekMode;

@property (nonatomic, strong, readonly) __kindof AVPSource *source;
@property (nonatomic, readonly) BOOL firstVideoFrameRendered;
@property (nonatomic, strong, readonly) UIView *view;
@property (nonatomic, readonly, nullable) NSArray<AVPTrackInfo *> *trackInfos;
- (nullable AVPTrackInfo *)currentTrackInfo:(AVPTrackType)type;
- (void)selectTrack:(int)trackIndex accurateSeeking:(BOOL)accurateSeeking completed:(void(^)(BOOL finished))completionHandler;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end

extern NSNotificationName const SJAliMediaPlayerOnTrackReadyNotification;
NS_ASSUME_NONNULL_END
