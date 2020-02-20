//
//  SJAliyunVodPlayerLayerView.h
//  Pods
//
//  Created by BlueDancer on 2020/2/19.
//

#import <UIKit/UIKit.h>
#import "SJAliyunVodPlayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface SJAliyunVodPlayerLayerView : UIView<SJMediaPlayerView>
- (instancetype)initWithPlayer:(SJAliyunVodPlayer *)player;
@property (nonatomic, strong, readonly) SJAliyunVodPlayer *player;
@property (nonatomic) SJVideoGravity videoGravity;
@property (nonatomic, readonly, getter=isReadyForDisplay) BOOL readyForDisplay;
@end

NS_ASSUME_NONNULL_END
