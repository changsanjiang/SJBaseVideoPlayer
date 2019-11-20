//
//  SJIJKMediaPlayerDefinitionLoader.h
//  SJBaseVideoPlayer
//
//  Created by BlueDancer on 2019/11/20.
//

#import "SJIJKMediaPlayer.h"
@protocol SJIJKMediaPlayerDefinitionLoaderDataSource;

NS_ASSUME_NONNULL_BEGIN
@interface SJIJKMediaPlayerDefinitionLoader : NSObject
- (instancetype)initWithURL:(NSURL *)URL options:(IJKFFOptions *)ops dataSource:(id<SJIJKMediaPlayerDefinitionLoaderDataSource>)dataSource completionHandler:(void(^)(SJIJKMediaPlayerDefinitionLoader *loader))completionHandler;
@property (nonatomic, strong, readonly) NSURL *URL;
@property (nonatomic, strong, readonly, nullable) SJIJKMediaPlayer *player;
@property (nonatomic, weak, readonly, nullable) id<SJIJKMediaPlayerDefinitionLoaderDataSource> dataSource;
- (void)cancel;
@end

@protocol SJIJKMediaPlayerDefinitionLoaderDataSource <NSObject>
@property (nonatomic, strong, readonly, nullable) SJIJKMediaPlayer *player;
@property (nonatomic, strong, readonly) UIView *superview;
@end
NS_ASSUME_NONNULL_END
