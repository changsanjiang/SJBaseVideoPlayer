//
//  SJVideoPlayerURLAsset+SJPLMediaPlaybackAdd.h
//  Pods
//
//  Created by BlueDancer on 2020/2/21.
//

#import "SJVideoPlayerURLAsset.h"
#import <PLPlayerKit/PLPlayerKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface SJVideoPlayerURLAsset (SJPLMediaPlaybackAdd)
- (nullable instancetype)initWithLiveURL:(NSURL *)URL;
- (nullable instancetype)initWithLiveURL:(NSURL *)URL playModel:(__kindof SJPlayModel *)playModel;

@property (nonatomic, strong, readonly, nullable) NSURL *liveURL;
@property (nonatomic, strong, null_resettable) PLPlayerOption *pl_playerOptions;
@end
NS_ASSUME_NONNULL_END
