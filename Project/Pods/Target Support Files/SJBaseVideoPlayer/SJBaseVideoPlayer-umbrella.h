#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "SJBaseVideoPlayer+TestLog.h"
#import "SJBaseVideoPlayer.h"
#import "SJPlaybackRecordSaveHandler.h"
#import "UIScrollView+ListViewAutoplaySJAdd.h"
#import "UIViewController+SJRotationPrivate_FixSafeArea.h"
#import "AVAsset+SJAVMediaExport.h"
#import "SJAVMediaPlayer.h"
#import "SJAVMediaPlayerLayerView.h"
#import "SJAVMediaPlayerLoader.h"
#import "SJAVPictureInPictureController.h"
#import "SJVideoPlayerURLAsset+SJAVMediaPlaybackAdd.h"
#import "SJVideoPlayerURLAssetPrefetcher.h"
#import "SJAVMediaPlaybackController.h"
#import "SJBaseVideoPlayerConst.h"
#import "SJMetalDefines.h"
#import "SJVideoPlayerPlayStatusDefines.h"
#import "NSString+SJBaseVideoPlayerExtended.h"
#import "NSTimer+SJAssetAdd.h"
#import "SJBarrageItem.h"
#import "SJBarrageQueueController.h"
#import "SJControlLayerAppearStateManager.h"
#import "SJDeviceVolumeAndBrightnessManager.h"
#import "SJFitOnScreenManager.h"
#import "SJFlipTransitionManager.h"
#import "SJFloatSmallViewController.h"
#import "SJFloatSmallViewTransitionController.h"
#import "SJMediaPlaybackController.h"
#import "SJPlaybackHistoryController.h"
#import "SJPlaybackObservation.h"
#import "SJPlaybackRecord.h"
#import "SJPlayerAutoplayConfig.h"
#import "SJPlayerView.h"
#import "SJPlayModel+SJPrivate.h"
#import "SJPlayModel.h"
#import "SJPlayModelPropertiesObserver.h"
#import "SJPrompt.h"
#import "SJPromptPopupController.h"
#import "SJReachability.h"
#import "SJRotationManager.h"
#import "SJSubtitleItem.h"
#import "SJSubtitlesPromptController.h"
#import "SJVideoDefinitionSwitchingInfo+Private.h"
#import "SJVideoDefinitionSwitchingInfo.h"
#import "SJVideoPlayerPresentView.h"
#import "SJVideoPlayerURLAsset+SJSubtitlesAdd.h"
#import "SJVideoPlayerURLAsset.h"
#import "SJViewControllerManager.h"
#import "SJWatermarkView.h"
#import "SJBarrageQueueControllerDefines.h"
#import "SJControlLayerAppearManagerDefines.h"
#import "SJDeviceVolumeAndBrightnessManagerDefines.h"
#import "SJFitOnScreenManagerDefines.h"
#import "SJFlipTransitionManagerDefines.h"
#import "SJFloatSmallViewControllerDefines.h"
#import "SJPictureInPictureControllerDefines.h"
#import "SJPlaybackHistoryControllerDefines.h"
#import "SJPlayerGestureControlDefines.h"
#import "SJPromptDefines.h"
#import "SJPromptPopupControllerDefines.h"
#import "SJReachabilityDefines.h"
#import "SJRotationManagerDefines.h"
#import "SJSubtitlesPromptControllerDefines.h"
#import "SJVideoPlayerControlLayerProtocol.h"
#import "SJVideoPlayerPlaybackControllerDefines.h"
#import "SJVideoPlayerPresentViewDefines.h"
#import "SJViewControllerManagerDefines.h"
#import "SJWatermarkViewDefines.h"
#import "CALayer+SJBaseVideoPlayerExtended.h"
#import "UIScrollView+SJBaseVideoPlayerExtended.h"
#import "UIView+SJBaseVideoPlayerExtended.h"
#import "UIViewController+SJBaseVideoPlayerExtended.h"
#import "SJTimerControl.h"
#import "SJVideoPlayerRegistrar.h"
#import "SJBaseVideoPlayerResourceLoader.h"

FOUNDATION_EXPORT double SJBaseVideoPlayerVersionNumber;
FOUNDATION_EXPORT const unsigned char SJBaseVideoPlayerVersionString[];

