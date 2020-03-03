//
//  SJAliyunVodPlayer.h
//  Demo
//
//  Created by BlueDancer on 2019/11/13.
//  Copyright © 2019 SanJiang. All rights reserved.
//

#import "SJMediaPlaybackController.h"
#import "SJAliyunVodModel.h"
#import <AliyunVodPlayerSDK/AliyunVodPlayerSDK.h>

NS_ASSUME_NONNULL_BEGIN
///
/// 内部封装了 AliyunVodPlayer
///
@interface SJAliyunVodPlayer : NSObject<SJMediaPlayer>
- (instancetype)initWithMedia:(__kindof SJAliyunVodModel *)media startPosition:(NSTimeInterval)time;

@property (nonatomic) NSTimeInterval trialEndPosition;
@property (nonatomic) AliyunVodPlayerDisplayMode displayMode;
@property (nonatomic) BOOL pauseWhenAppDidEnterBackground;
@property (nonatomic, strong, readonly) SJAliyunVodModel *media;
@property (nonatomic, strong, readonly) UIView *view;
@property (nonatomic, readonly) BOOL firstVideoFrameRendered;
@end
NS_ASSUME_NONNULL_END
