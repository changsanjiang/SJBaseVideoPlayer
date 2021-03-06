//
//  SJAVMediaPlayerLoader.m
//  Pods
//
//  Created by 畅三江 on 2019/4/10.
//

#import "SJAVMediaPlayerLoader.h"
#import "SJVideoPlayerURLAsset+SJAVMediaPlaybackAdd.h"
#import <objc/message.h>
#import "SJMetalDefines.h"
NS_ASSUME_NONNULL_BEGIN
@implementation SJAVMediaPlayerLoader
static void *kPlayer = &kPlayer;

+ (nullable SJAVMediaPlayer *)loadPlayerForMedia:(SJVideoPlayerURLAsset *)media {
#ifdef DEBUG
    NSParameterAssert(media);
#endif
    if ( media == nil )
        return nil;
    
    SJVideoPlayerURLAsset *target = media.original ?: media;
    SJAVMediaPlayer *__block _Nullable player = objc_getAssociatedObject(target, kPlayer);
    if ( player != nil && player.assetStatus != SJAssetStatusFailed ) {
        return player;
    }
    
    AVPlayer *avPlayer = target.avPlayer;
    if ( avPlayer == nil ) {
        AVPlayerItem *avPlayerItem = target.avPlayerItem;
        if ( avPlayerItem == nil ) {
            AVAsset *avAsset = target.avAsset;
            if ( avAsset == nil ) {
                avAsset = [AVURLAsset URLAssetWithURL:target.mediaURL options:nil];
            }
            avPlayerItem = [AVPlayerItem playerItemWithAsset:avAsset];
        }
        
        if (target.videoCompositionEnable) {
            NSArray <AVAssetTrack *>*assetTracks = avPlayerItem.asset.tracks;
            if (assetTracks.count) {
                CGSize videoSize = CGSizeZero;
                switch (target.compositionDirection) {
                    case SJVideoCompositionDirectionLeftToRight://白幕在左
                    case SJVideoCompositionDirectionRightToLeft://白幕在右
                    {
                        videoSize = CGSizeMake(assetTracks.firstObject.naturalSize.width/2.f, assetTracks.firstObject.naturalSize.height);
                    }
                        break;
                    case SJVideoCompositionDirectionTopToBottom://白幕在上
                    case SJVideoCompositionDirectionBottomToTop://白幕在下
                    {
                        videoSize = CGSizeMake(assetTracks.firstObject.naturalSize.width, assetTracks.firstObject.naturalSize.height/2.f);
                    }
                        break;
                    default:
                        break;
                }
                
                if (videoSize.width && videoSize.height) {
                    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoCompositionWithAsset:avPlayerItem.asset applyingCIFiltersWithHandler:^(AVAsynchronousCIImageFilteringRequest * _Nonnull request) {
                        CGRect sourceRect = (CGRect){0,0,videoSize.width,videoSize.height};
                        CGRect alphaRect = CGRectZero;
                        
                        CGFloat dx;
                        CGFloat dy;
                        switch (target.compositionDirection) {
                            case SJVideoCompositionDirectionLeftToRight://白幕在左
                            case SJVideoCompositionDirectionRightToLeft://白幕在右
                            {
                                alphaRect = CGRectOffset(sourceRect, videoSize.width, 0);
                                dx = -sourceRect.size.width;
                                dy = 0;
                            }
                                break;
                            case SJVideoCompositionDirectionTopToBottom://白幕在上
                            case SJVideoCompositionDirectionBottomToTop://白幕在下
                            {
                                alphaRect = CGRectOffset(sourceRect, 0, videoSize.height);
                                dx = 0;
                                dy = -sourceRect.size.height;
                            }
                            default:
                                break;
                        }
                     
                        
                        if (@available(iOS 11.0, *)) {
                            if (!videoKernel) {
                                NSURL *kernelURL = [[NSBundle mainBundle] URLForResource:@"default" withExtension:@"metallib"];
                                NSError *error;
                                NSData *kernelData = [NSData dataWithContentsOfURL:kernelURL];
                                videoKernel = [CIColorKernel kernelWithFunctionName:@"maskVideoMetal" fromMetalLibraryData:kernelData error:&error];
                                NSLog(@"%@",error);
                                
                            }
                        } else {
                            if (!videoKernel) {
                                videoKernel = [CIColorKernel kernelWithString:@"kernel vec4 alphaFrame(__sample s, __sample m) {return vec4(s.rgb, m.r);}"];
                            }
                        }
                        
                        
                        CIImage *inputImage;
                        CIImage *maskImage;
                        switch (target.compositionDirection) {
                            case SJVideoCompositionDirectionLeftToRight:{
                                inputImage = [[request.sourceImage imageByCroppingToRect:alphaRect] imageByApplyingTransform:CGAffineTransformMakeTranslation(dx, dy)];
                                
                                maskImage = [request.sourceImage imageByCroppingToRect:sourceRect];
                            }
                                break;
                            case SJVideoCompositionDirectionRightToLeft:{
                                inputImage = [request.sourceImage imageByCroppingToRect:sourceRect];
                                maskImage = [[request.sourceImage imageByCroppingToRect:alphaRect] imageByApplyingTransform:CGAffineTransformMakeTranslation(dx, dy)];
                            }
                                break;
                            case SJVideoCompositionDirectionTopToBottom:{
                                inputImage = [request.sourceImage imageByCroppingToRect:sourceRect];
                                maskImage = [[request.sourceImage imageByCroppingToRect:alphaRect] imageByApplyingTransform:CGAffineTransformMakeTranslation(dx, dy)];
                            }
                                break;
                            case SJVideoCompositionDirectionBottomToTop:
                            {

                                
                                inputImage = [[request.sourceImage imageByCroppingToRect:alphaRect] imageByApplyingTransform:CGAffineTransformMakeTranslation(dx, dy)];
                                
                                maskImage = [request.sourceImage imageByCroppingToRect:sourceRect];
                            }
                            default:
                                break;
                        }
                        
                        CIImage *outPutImage = [videoKernel applyWithExtent:inputImage.extent arguments:@[(id)inputImage,(id)maskImage]];
                        
                        
                        
                        [request finishWithImage:outPutImage context:nil];
                    }];
                    videoComposition.renderSize = videoSize;
                    avPlayerItem.videoComposition = videoComposition;
                    avPlayerItem.seekingWaitsForVideoCompositionRendering = YES;
                }
                
            }
            
            
            
        }
        
        avPlayer = [AVPlayer playerWithPlayerItem:avPlayerItem];
    }
    
    player = [SJAVMediaPlayer.alloc initWithAVPlayer:avPlayer startPosition:media.startPosition];
    objc_setAssociatedObject(target, kPlayer, player, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return player;
}

+ (void)clearPlayerForMedia:(SJVideoPlayerURLAsset *)media {
    if ( media != nil ) {
        id<SJMediaModelProtocol> target = media.original ?: media;
        objc_setAssociatedObject(target, kPlayer, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}
@end
NS_ASSUME_NONNULL_END
