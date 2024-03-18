//
//  SJAVPlayerItemObservation.h
//  player
//
//  Created by 畅三江 on 2023/8/8.
//

#import <AVFoundation/AVFoundation.h>
@protocol SJAVPlayerItemObserver;

NS_ASSUME_NONNULL_BEGIN
@interface SJAVPlayerItemObservation : NSObject
- (instancetype)initWithPlayerItem:(AVPlayerItem *)playerItem observer:(id<SJAVPlayerItemObserver>)observer;

@property (nonatomic, weak, readonly, nullable) id<SJAVPlayerItemObserver> observer;
@end

@protocol SJAVPlayerItemObserver <NSObject>
- (void)playerItem:(AVPlayerItem *)playerItem statusDidChange:(AVPlayerItemStatus)playerItemStatus;
- (void)playerItem:(AVPlayerItem *)playerItem loadedTimeRangesDidChange:(NSArray<NSValue *> *)loadedTimeRanges;
- (void)playerItem:(AVPlayerItem *)playerItem didPlayToEndTime:(NSNotification *)notification;
- (void)playerItemNewAccessLogDidEntry:(AVPlayerItem *)playerItem; // 子线程执行
@end
NS_ASSUME_NONNULL_END
