//
//  SJRotationManager_4.h
//  SJVideoPlayer_Example
//
//  Created by 畅三江 on 2022/7/6.
//  Copyright © 2022 changsanjiang. All rights reserved.
//

#import "SJRotationManagerDefines.h"

NS_ASSUME_NONNULL_BEGIN
@interface SJRotationManager_4 : NSObject<SJRotationManager>
+ (instancetype)rotationManager;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (void)setNeedsStatusBarAppearanceUpdate;
@end

@interface UIWindow (SJRotationControls)
@property (nonatomic, readonly) UIInterfaceOrientationMask sj_4_supportedInterfaceOrientations;
@end
NS_ASSUME_NONNULL_END
