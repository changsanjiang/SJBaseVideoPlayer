//
//  SJAVPlayerObservation.h
//  player
//
//  Created by 畅三江 on 2023/8/7.
//

#import <AVFoundation/AVFoundation.h>
@protocol SJAVPlayerObserver;

NS_ASSUME_NONNULL_BEGIN
@interface SJAVPlayerObservation : NSObject
- (instancetype)initWithPlayer:(AVPlayer *)player observer:(id<SJAVPlayerObserver>)observer;

@property (nonatomic, weak, readonly, nullable) id<SJAVPlayerObserver> observer;
@end

@protocol SJAVPlayerObserver <NSObject>
- (void)player:(AVPlayer *)player playerStatusDidChange:(AVPlayerStatus)playerStatus;
- (void)player:(AVPlayer *)player playerTimeControlStatusDidChange:(AVPlayerTimeControlStatus)timeControlStatus API_AVAILABLE(ios(10.0));
- (void)player:(AVPlayer *)player reasonForWaitingToPlayDidChange:(nullable AVPlayerWaitingReason)reasonForWaitingToPlay API_AVAILABLE(ios(10.0));
@end
NS_ASSUME_NONNULL_END
