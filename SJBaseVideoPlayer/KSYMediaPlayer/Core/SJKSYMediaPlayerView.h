//
//  SJKSYMediaPlayerView.h
//  SJBaseVideoPlayer
//
//  Created by 畅三江 on 2021/9/9.
//

#import <UIKit/UIKit.h>
#import "SJKSYMediaPlayer.h"

NS_ASSUME_NONNULL_BEGIN
@interface SJKSYMediaPlayerView : UIView<SJMediaPlayerView>
- (instancetype)initWithPlayer:(SJKSYMediaPlayer *)player;
@property (nonatomic, strong, readonly) SJKSYMediaPlayer *player;
@property (nonatomic) SJVideoGravity videoGravity;
@property (nonatomic, readonly, getter=isReadyForDisplay) BOOL readyForDisplay;
@end
NS_ASSUME_NONNULL_END
