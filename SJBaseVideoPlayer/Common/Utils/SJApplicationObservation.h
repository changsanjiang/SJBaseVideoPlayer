//
//  SJApplicationObservation.h
//  player
//
//  Created by 畅三江 on 2023/9/19.
//

#import <Foundation/Foundation.h>
@protocol SJApplicationObserver;

NS_ASSUME_NONNULL_BEGIN

@interface SJApplicationObservation : NSObject
- (instancetype)initWithObserver:(id<SJApplicationObserver>)observer;

@property (nonatomic, weak, readonly, nullable) id<SJApplicationObserver> observer;
@end

@protocol SJApplicationObserver <NSObject>
@optional
- (void)onReceivedApplicationDidEnterBackgroundNotification;
- (void)onReceivedApplicationWillEnterForegroundNotification;
- (void)onReceivedApplicationDidBecomeActiveNotification;
@end
NS_ASSUME_NONNULL_END
