//
//  SJAliyunVodPlaybackController.h
//  Demo
//
//  Created by BlueDancer on 2019/11/13.
//  Copyright © 2019 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJVideoPlayerPlaybackControllerDefines.h"
#import "SJVideoPlayerURLAsset+SJAliyunVodPlaybackAdd.h"

NS_ASSUME_NONNULL_BEGIN
@interface SJAliyunVodPlaybackController : NSObject<SJVideoPlayerPlaybackController>
@property (nonatomic, strong, nullable) SJVideoPlayerURLAsset *media;
@end
NS_ASSUME_NONNULL_END
