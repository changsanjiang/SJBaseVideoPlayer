//
//  SJVideoPlayerURLAsset+SJAliMediaPlaybackAdd.h
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2019/11/7.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

#import "SJVideoPlayerURLAsset.h"
#import <AliyunPlayer/AVPSource.h>

NS_ASSUME_NONNULL_BEGIN
@interface SJVideoPlayerURLAsset (SJAliMediaPlaybackAdd)
- (instancetype)initWithSource:(__kindof AVPSource *)source;
- (instancetype)initWithSource:(__kindof AVPSource *)source playModel:(__kindof SJPlayModel *)playModel;
- (instancetype)initWithSource:(__kindof AVPSource *)source startPosition:(NSTimeInterval)startPosition;
- (instancetype)initWithSource:(__kindof AVPSource *)source startPosition:(NSTimeInterval)startPosition playModel:(__kindof SJPlayModel *)playModel;

@property (nonatomic, strong, readonly, nullable) __kindof AVPSource *source;
@end
NS_ASSUME_NONNULL_END
