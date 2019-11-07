//
//  SJAliMediaPlaybackController.h
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2019/11/7.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJVideoPlayerPlaybackControllerDefines.h"
#import "SJVideoPlayerURLAsset+SJAliMediaPlaybackAdd.h"
#import <AliyunPlayer/AVPDef.h>

NS_ASSUME_NONNULL_BEGIN
@interface SJAliMediaPlaybackController : NSObject<SJVideoPlayerPlaybackController>
@property (nonatomic, strong, nullable) SJVideoPlayerURLAsset *media;
@property (nonatomic) AVPSeekMode seekMode;
@end
NS_ASSUME_NONNULL_END
