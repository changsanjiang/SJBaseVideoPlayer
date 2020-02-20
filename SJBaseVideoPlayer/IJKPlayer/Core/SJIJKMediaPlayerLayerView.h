//
//  SJIJKMediaPlayerLayerView.h
//  Pods
//
//  Created by BlueDancer on 2020/2/19.
//

#import <UIKit/UIKit.h>
#import "SJMediaPlaybackController.h"
#import "SJIJKMediaPlayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface SJIJKMediaPlayerLayerView : UIView<SJMediaPlayerView>
- (instancetype)initWithPlayer:(SJIJKMediaPlayer *)player;

@property (nonatomic, strong, readonly) SJIJKMediaPlayer *player;

@property (nonatomic) SJVideoGravity videoGravity;
@property (nonatomic, readonly, getter=isReadyForDisplay) BOOL readyForDisplay;

@end

NS_ASSUME_NONNULL_END
