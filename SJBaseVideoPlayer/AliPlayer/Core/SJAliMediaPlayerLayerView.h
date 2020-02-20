//
//  SJAliMediaPlayerLayerView.h
//  Pods
//
//  Created by BlueDancer on 2020/2/19.
//

#import <UIKit/UIKit.h>
#import "SJAliMediaPlayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface SJAliMediaPlayerLayerView : UIView<SJMediaPlayerView>
- (instancetype)initWithPlayer:(SJAliMediaPlayer *)player;
@property (nonatomic, strong, readonly) SJAliMediaPlayer *player;
@property (nonatomic) SJVideoGravity videoGravity;
@property (nonatomic, readonly, getter=isReadyForDisplay) BOOL readyForDisplay;
@end

NS_ASSUME_NONNULL_END
