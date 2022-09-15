//
//  SJAliMediaPlayerInternal.h
//  Pods
//
//  Created by 畅三江 on 2022/9/15.
//

#ifndef SJAliMediaPlayerInternal_h
#define SJAliMediaPlayerInternal_h


#import "SJAliMediaPlayer.h"
#import <AliyunPlayer/AliyunPlayer.h>

NS_ASSUME_NONNULL_BEGIN
@interface SJAliMediaPlayer (Internal)
@property (nonatomic, strong, readonly) AliPlayer *player;
@end
NS_ASSUME_NONNULL_END
#endif /* SJAliMediaPlayerInternal_h */
