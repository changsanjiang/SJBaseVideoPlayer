//
//  SJAliMediaPlayerDefinitionLoader.h
//  SJBaseVideoPlayer
//
//  Created by BlueDancer on 2019/11/20.
//

#import "SJAliMediaPlayer.h"
@protocol SJAliMediaPlayerDefinitionLoaderDataSource;

NS_ASSUME_NONNULL_BEGIN
@interface SJAliMediaPlayerDefinitionLoader : NSObject
- (instancetype)initWithSource:(__kindof AVPSource *)source dataSource:(id<SJAliMediaPlayerDefinitionLoaderDataSource>)dataSource completionHandler:(void(^)(SJAliMediaPlayerDefinitionLoader *loader))completionHandler;
@property (nonatomic, strong, readonly) __kindof AVPSource *source;
@property (nonatomic, strong, readonly, nullable) SJAliMediaPlayer *player;
@property (nonatomic, weak, readonly, nullable) id<SJAliMediaPlayerDefinitionLoaderDataSource> dataSource;
- (void)cancel;
@end

@protocol SJAliMediaPlayerDefinitionLoaderDataSource <NSObject>
@property (nonatomic, strong, readonly, nullable) SJAliMediaPlayer *player;
@property (nonatomic, strong, readonly) UIView *superview;
@end
NS_ASSUME_NONNULL_END
