//
//  SJAliyunVodPlayerDefinitionPrepareStatusObserver.h
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2019/11/7.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SJAliyunVodPlayer;

NS_ASSUME_NONNULL_BEGIN
@interface SJAliyunVodPlayerDefinitionPrepareStatusObserver : NSObject
- (instancetype)initWithPlayer:(SJAliyunVodPlayer *)player;
@property (nonatomic, strong, readonly) SJAliyunVodPlayer *player;

@property (nonatomic, copy, nullable) void(^statusDidChangeExeBlock)(SJAliyunVodPlayerDefinitionPrepareStatusObserver *obs);
@end
NS_ASSUME_NONNULL_END
