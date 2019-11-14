//
//  SJVideoPlayerURLAsset+SJAliyunVodPlaybackAdd.m
//  Demo
//
//  Created by BlueDancer on 2019/11/14.
//  Copyright © 2019 SanJiang. All rights reserved.
//

#import "SJVideoPlayerURLAsset+SJAliyunVodPlaybackAdd.h"
#import <objc/message.h>

NS_ASSUME_NONNULL_BEGIN
@implementation SJVideoPlayerURLAsset (SJAliyunVodPlaybackAdd)
- (instancetype)initWithAliyunVodModel:(SJAliyunVodModel *)media {
    return [self initWithAliyunVodModel:media playModel:SJPlayModel.new];
}
- (instancetype)initWithAliyunVodModel:(SJAliyunVodModel *)media playModel:(__kindof SJPlayModel *)playModel {
    return [self initWithAliyunVodModel:media specifyStartTime:0 playModel:playModel];
}
- (instancetype)initWithAliyunVodModel:(SJAliyunVodModel *)media specifyStartTime:(NSTimeInterval)specifyStartTime {
    return [self initWithAliyunVodModel:media specifyStartTime:specifyStartTime playModel:SJPlayModel.new];
}
- (instancetype)initWithAliyunVodModel:(SJAliyunVodModel *)media specifyStartTime:(NSTimeInterval)specifyStartTime playModel:(__kindof SJPlayModel *)playModel {
    self = [super init];
    if ( self ) {
        self.aliyunMedia = media;
        self.playModel = playModel;
        self.specifyStartTime = specifyStartTime;
    }
    return self;
}

- (void)setAliyunMedia:(__kindof SJAliyunVodModel * _Nullable)aliyunMedia {
    objc_setAssociatedObject(self, @selector(aliyunMedia), aliyunMedia, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (nullable SJAliyunVodModel *)aliyunMedia {
    __kindof SJAliyunVodModel *media = objc_getAssociatedObject(self, _cmd);
    if ( media == nil ) {
        if ( self.mediaURL != nil ) {
            media = [SJAliyunVodURLModel.alloc initWithURL:self.mediaURL];
            [self setAliyunMedia:media];
        }
    }
    return media;
}
@end
NS_ASSUME_NONNULL_END
