//
//  SJVideoPlayerURLAsset+SJAliMediaPlaybackAdd.h
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2019/11/7.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

#import "SJVideoPlayerURLAsset.h"
#import <AliyunPlayer/AVPSource.h>
#import <AliyunPlayer/AVPConfig.h>
#import <AliyunPlayer/AVPCacheConfig.h>
#import <AliyunPlayer/AVPMediaInfo.h>
#import <AliyunPlayer/AVPDef.h>

NS_ASSUME_NONNULL_BEGIN
/// 阿里播放器播放资源配置
@interface SJAliMediaSource : NSObject
@property (nonatomic, strong, nullable) NSString *traceID;
@property (nonatomic, strong, nullable) __kindof AVPSource *source;
@property (nonatomic, strong, nullable) AVPConfig *config;
@property (nonatomic, strong, nullable) AVPCacheConfig *cacheConfig;
/// 切换清晰度时使用
@property (nonatomic, strong, nullable) AVPTrackInfo *trackInfo;
@property (nonatomic, copy, nullable) AVPStsStatus (^verifyStsCallback)(AVPStsInfo info, void(^callback)(AVPStsInfo stsInfo));

- (instancetype)initWithSource:(__kindof AVPSource *)source;
@end

@interface SJVideoPlayerURLAsset (SJAliMediaPlaybackAdd)
- (instancetype)initWithSource:(SJAliMediaSource *)source;
- (instancetype)initWithSource:(SJAliMediaSource *)source playModel:(__kindof SJPlayModel *)playModel;
- (instancetype)initWithSource:(SJAliMediaSource *)source startPosition:(NSTimeInterval)startPosition;
- (instancetype)initWithSource:(SJAliMediaSource *)source startPosition:(NSTimeInterval)startPosition playModel:(__kindof SJPlayModel *)playModel;

@property (nonatomic, strong, readonly, nullable) SJAliMediaSource *source;
@end

NS_ASSUME_NONNULL_END
