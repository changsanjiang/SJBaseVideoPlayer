//
//  SJAliyunVodPlayerDefinitionLoader.h
//  SJBaseVideoPlayer
//
//  Created by BlueDancer on 2019/11/20.
//

#import "SJAliyunVodPlayer.h"
@protocol SJAliyunVodPlayerDefinitionLoaderDataSource;

NS_ASSUME_NONNULL_BEGIN
@interface SJAliyunVodPlayerDefinitionLoader : NSObject
- (instancetype)initWithMedia:(__kindof SJAliyunVodModel *)media dataSource:(id<SJAliyunVodPlayerDefinitionLoaderDataSource>)dataSource completionHandler:(void(^)(SJAliyunVodPlayerDefinitionLoader *loader))completionHandler;
@property (nonatomic, strong, readonly) SJAliyunVodModel *media;
@property (nonatomic, strong, readonly, nullable) SJAliyunVodPlayer *player;
@property (nonatomic, weak, readonly, nullable) id<SJAliyunVodPlayerDefinitionLoaderDataSource> dataSource;
- (void)cancel;
@end

@protocol SJAliyunVodPlayerDefinitionLoaderDataSource <NSObject>
@property (nonatomic, strong, readonly, nullable) SJAliyunVodPlayer *player;
@property (nonatomic, strong, readonly) UIView *superview;
@end
NS_ASSUME_NONNULL_END
