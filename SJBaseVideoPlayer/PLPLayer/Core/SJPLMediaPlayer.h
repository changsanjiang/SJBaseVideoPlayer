//
//  SJPLMediaPlayer.h
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2020/2/20.
//  Copyright © 2020 changsanjiang. All rights reserved.
//

#import "SJMediaPlaybackController.h"
#import <PLPlayerKit/PLPlayerKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface SJPLMediaPlayer : NSObject<SJMediaPlayer>
- (instancetype)initWithURL:(NSURL *)URL options:(PLPlayerOption *)options startPosition:(NSTimeInterval)startPosition;
- (instancetype)initWithLiveURL:(NSURL *)URL options:(PLPlayerOption *)options;

@property (nonatomic) NSTimeInterval trialEndPosition;

@property (nonatomic, getter=isAutoReconnectEnable) BOOL autoReconnectEnable;
@property (nonatomic) BOOL pauseWhenAppDidEnterBackground;

@property (nonatomic, readonly) SJPlaybackType playbackType;
@property (nonatomic, readonly) NSTimeInterval startPosition;
@property (nonatomic, strong, readonly) NSURL *URL;
@property (nonatomic, strong, readonly) UIView *view;
@property (nonatomic, readonly) BOOL firstVideoFrameRendered;
@end
NS_ASSUME_NONNULL_END
