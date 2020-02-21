//
//  SJVideoPlayerURLAsset+SJPLMediaPlaybackAdd.m
//  Pods
//
//  Created by BlueDancer on 2020/2/21.
//

#import "SJVideoPlayerURLAsset+SJPLMediaPlaybackAdd.h"
#import <objc/message.h>

NS_ASSUME_NONNULL_BEGIN
@implementation SJVideoPlayerURLAsset (SJPLMediaPlaybackAdd)
- (nullable instancetype)initWithLiveURL:(NSURL *)URL {
    return [self initWithLiveURL:URL playModel:SJPlayModel.new];
}
- (nullable instancetype)initWithLiveURL:(NSURL *)URL playModel:(__kindof SJPlayModel *)playModel {
    if ( URL == nil ) return nil;
    self = [super init];
    if ( self ) {
        self.liveURL = URL;
        self.playModel = playModel;
    }
    return self;
}

- (void)setLiveURL:(NSURL * _Nullable)liveURL {
    objc_setAssociatedObject(self, @selector(liveURL), liveURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (nullable NSURL *)liveURL {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setPl_playerOptions:(nullable PLPlayerOption *)pl_playerOptions {
    objc_setAssociatedObject(self, @selector(pl_playerOptions), pl_playerOptions, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (PLPlayerOption *)pl_playerOptions {
    PLPlayerOption *options = objc_getAssociatedObject(self, _cmd);
    if ( options == nil ) {
        options = PLPlayerOption.defaultOption;
        PLPlayFormat format = kPLPLAY_FORMAT_UnKnown;
        NSString *urlString = (self.mediaURL ?: self.liveURL).absoluteString.lowercaseString;
        if ([urlString hasSuffix:@"mp4"]) {
            format = kPLPLAY_FORMAT_MP4;
        } else if ([urlString hasPrefix:@"rtmp:"]) {
            format = kPLPLAY_FORMAT_FLV;
        } else if ([urlString hasSuffix:@".mp3"]) {
            format = kPLPLAY_FORMAT_MP3;
        } else if ([urlString hasSuffix:@".m3u8"]) {
            format = kPLPLAY_FORMAT_M3U8;
        }
        [options setOptionValue:@(format) forKey:PLPlayerOptionKeyVideoPreferFormat];
#ifdef DEBUG
        [options setOptionValue:@"kPLLogInfo" forKey:PLPlayerOptionKeyLogLevel];
#else
        [options setOptionValue:@"kPLLogWarning" forKey:PLPlayerOptionKeyLogLevel];
#endif
        [self setPl_playerOptions:options];
    }
    return options;
}
@end
NS_ASSUME_NONNULL_END
