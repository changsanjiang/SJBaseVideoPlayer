//
//  SJPLMediaPlayerLayerView.h
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2020/2/20.
//  Copyright © 2020 changsanjiang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SJMediaPlaybackController.h"
#import "SJPLMediaPlayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface SJPLMediaPlayerLayerView : UIView<SJMediaPlayerView>
- (instancetype)initWithPlayer:(SJPLMediaPlayer *)player;
@property (nonatomic, strong, readonly) SJPLMediaPlayer *player;
@property (nonatomic) SJVideoGravity videoGravity;
@property (nonatomic, readonly, getter=isReadyForDisplay) BOOL readyForDisplay;
@end

NS_ASSUME_NONNULL_END
