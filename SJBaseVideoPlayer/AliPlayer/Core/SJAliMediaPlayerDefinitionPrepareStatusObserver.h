//
//  SJAliMediaPlayerDefinitionPrepareStatusObserver.h
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2019/11/7.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SJAliMediaPlayer;

NS_ASSUME_NONNULL_BEGIN
@interface SJAliMediaPlayerDefinitionPrepareStatusObserver : NSObject
- (instancetype)initWithPlayer:(SJAliMediaPlayer *)player;
@property (nonatomic, strong, readonly) SJAliMediaPlayer *player;

@property (nonatomic, copy, nullable) void(^statusDidChangeExeBlock)(SJAliMediaPlayerDefinitionPrepareStatusObserver *obs);
@end
NS_ASSUME_NONNULL_END
