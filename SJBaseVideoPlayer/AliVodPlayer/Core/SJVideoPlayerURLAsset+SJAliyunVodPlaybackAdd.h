//
//  SJVideoPlayerURLAsset+SJAliyunVodPlaybackAdd.h
//  Demo
//
//  Created by BlueDancer on 2019/11/14.
//  Copyright © 2019 SanJiang. All rights reserved.
//

#import "SJVideoPlayerURLAsset.h"
#import "SJAliyunVodModel.h"

NS_ASSUME_NONNULL_BEGIN
@interface SJVideoPlayerURLAsset (SJAliyunVodPlaybackAdd)
- (instancetype)initWithAliyunVodModel:(SJAliyunVodModel *)media;
- (instancetype)initWithAliyunVodModel:(SJAliyunVodModel *)media playModel:(__kindof SJPlayModel *)playModel;
- (instancetype)initWithAliyunVodModel:(SJAliyunVodModel *)media specifyStartTime:(NSTimeInterval)specifyStartTime;
- (instancetype)initWithAliyunVodModel:(SJAliyunVodModel *)media specifyStartTime:(NSTimeInterval)specifyStartTime playModel:(__kindof SJPlayModel *)playModel;

@property (nonatomic, strong, readonly, nullable) __kindof SJAliyunVodModel *aliyunMedia;
@end
NS_ASSUME_NONNULL_END
