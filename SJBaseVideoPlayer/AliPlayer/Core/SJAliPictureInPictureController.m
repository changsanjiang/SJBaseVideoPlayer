//
//  SJAliPictureInPictureController.m
//  SJBaseVideoPlayer.common-AliPlayer-IJKPlayer
//
//  Created by 畅三江 on 2022/9/15.
//

#import "SJAliPictureInPictureController.h"
#if __has_include(<AliyunPlayer/AliPlayerPictureInPictureDelegate.h>)
#import <AVKit/AVPictureInPictureController.h>
#import "SJAliMediaPlayerInternal.h"
#import <AliyunPlayer/AliPlayerPictureInPictureDelegate.h>

@interface SJAliPictureInPictureController ()<AliPlayerPictureInPictureDelegate>
@property (nonatomic) SJPictureInPictureStatus status;
@end

@implementation SJAliPictureInPictureController

+ (BOOL)isPictureInPictureSupported {
    return AVPictureInPictureController.isPictureInPictureSupported;
}

- (instancetype)initWithPlayer:(SJAliMediaPlayer *)player delegate:(nonnull id<SJPictureInPictureControllerDelegate>)delegate {
    self = [super init];
    if ( self ) {
        _player = player;
        _delegate = delegate;
        [_player.player setPictureinPictureDelegate:self];
    }
    return self;
}

- (void)setRequiresLinearPlayback:(BOOL)requiresLinearPlayback {
#ifdef DEBUG
    NSLog(@"%d - -[%@ %s] 暂未提供相关API", (int)__LINE__, NSStringFromClass([self class]), sel_getName(_cmd));
#endif
}

- (BOOL)requiresLinearPlayback {
#ifdef DEBUG
    NSLog(@"%d - -[%@ %s] 暂未提供相关API", (int)__LINE__, NSStringFromClass([self class]), sel_getName(_cmd));
#endif
    return NO;
}

- (void)setCanStartPictureInPictureAutomaticallyFromInline:(BOOL)canStartPictureInPictureAutomaticallyFromInline {
    if ( canStartPictureInPictureAutomaticallyFromInline != _canStartPictureInPictureAutomaticallyFromInline ) {
        _canStartPictureInPictureAutomaticallyFromInline = canStartPictureInPictureAutomaticallyFromInline;
        [_player.player setPictureInPictureEnable:canStartPictureInPictureAutomaticallyFromInline];
    }
}

- (void)startPictureInPicture {
#ifdef DEBUG
    NSLog(@"%d - -[%@ %s] 暂未提供相关API", (int)__LINE__, NSStringFromClass([self class]), sel_getName(_cmd));
#endif
}

- (void)stopPictureInPicture {
//#ifdef DEBUG
//    NSLog(@"%d - -[%@ %s] 暂未提供相关API", (int)__LINE__, NSStringFromClass([self class]), sel_getName(_cmd));
//#endif
    self.canStartPictureInPictureAutomaticallyFromInline = NO;
}

- (void)setStatus:(SJPictureInPictureStatus)status {
    if ( status != _status ) {
        _status = status;
        
        if ( [self.delegate respondsToSelector:@selector(pictureInPictureController:statusDidChange:)] ) {
            [self.delegate pictureInPictureController:self statusDidChange:status];
        }
    }
}

#pragma mark - AliPlayerPictureInPictureDelegate

- (void)pictureInPictureControllerWillStartPictureInPicture {
#ifdef SJDEBUG
    NSLog(@"%d - -[%@ %s]", (int)__LINE__, NSStringFromClass([self class]), sel_getName(_cmd));
#endif
    self.status = SJPictureInPictureStatusStarting;
}

- (void)pictureInPictureControllerDidStartPictureInPicture {
#ifdef SJDEBUG
    NSLog(@"%d - -[%@ %s]", (int)__LINE__, NSStringFromClass([self class]), sel_getName(_cmd));
#endif
    self.status = SJPictureInPictureStatusRunning;
}

/// 画中画返回app界面，后是否要停止
- (BOOL)pictureInPictureIsPlaybackPaused {
#ifdef SJDEBUG
    NSLog(@"%d - -[%@ %s]", (int)__LINE__, NSStringFromClass([self class]), sel_getName(_cmd));
#endif
    return NO;
}

- (void)pictureInPictureControllerWillStopPictureInPicture {
#ifdef SJDEBUG
    NSLog(@"%d - -[%@ %s]", (int)__LINE__, NSStringFromClass([self class]), sel_getName(_cmd));
#endif
    self.status = SJPictureInPictureStatusStopping;
}

- (void)pictureInPictureControllerDidStopPictureInPicture {
#ifdef SJDEBUG
    NSLog(@"%d - -[%@ %s]", (int)__LINE__, NSStringFromClass([self class]), sel_getName(_cmd));
#endif
    self.status = SJPictureInPictureStatusStopped;
}
@end
#else
@implementation SJAliPictureInPictureController
+ (BOOL)isPictureInPictureSupported {
    return NO;
}

- (instancetype)initWithPlayer:(SJAliMediaPlayer *)player delegate:(id<SJPictureInPictureControllerDelegate>)delegate {
    return nil;
}

- (void)startPictureInPicture { }
- (void)stopPictureInPicture { }
@end
#endif
