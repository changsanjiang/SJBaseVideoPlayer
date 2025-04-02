//
//  SJVideoPlayerURLAsset+SJAliMediaPlaybackAdd.m
//  SJVideoPlayer_Example
//
//  Created by BlueDancer on 2019/11/7.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

#import "SJVideoPlayerURLAsset+SJAliMediaPlaybackAdd.h"
#import <objc/message.h>

NS_ASSUME_NONNULL_BEGIN
@implementation SJAliMediaSource : NSObject
- (instancetype)initWithSource:(__kindof AVPSource *)source
{
    self = [super init];
    if ( self ) {
        _source = source;
    }
    return self;
}
@end

@implementation SJVideoPlayerURLAsset (SJAliMediaPlaybackAdd)
- (instancetype)initWithSource:(SJAliMediaSource *)source {
    return [self initWithSource:source playModel:SJPlayModel.new];
}
- (instancetype)initWithSource:(SJAliMediaSource *)source playModel:(__kindof SJPlayModel *)playModel {
    return [self initWithSource:source startPosition:0 playModel:playModel];
}
- (instancetype)initWithSource:(SJAliMediaSource *)source startPosition:(NSTimeInterval)startPosition {
    return [self initWithSource:source startPosition:startPosition playModel:SJPlayModel.new];
}
- (instancetype)initWithSource:(SJAliMediaSource *)source startPosition:(NSTimeInterval)startPosition playModel:(__kindof SJPlayModel *)playModel {
    self = [super init];
    if ( self ) {
        self.source = source;
        self.startPosition = startPosition;
        self.playModel = playModel;
    }
    return self;
}

- (void)setSource:(SJAliMediaSource * _Nullable)source {
    objc_setAssociatedObject(self, @selector(source), source, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (nullable SJAliMediaSource *)source {
    SJAliMediaSource *source = objc_getAssociatedObject(self, _cmd);
    if ( source == nil ) {
        if ( self.mediaURL != nil ) {
            AVPUrlSource *urlSource = [[AVPUrlSource alloc] urlWithString:self.mediaURL];
            if ([self.mediaURL isFileURL]) {
                urlSource = [[AVPUrlSource alloc] fileURLWithPath:self.mediaURL.relativePath];
            } else {
                urlSource = [[AVPUrlSource alloc] urlWithString:self.mediaURL.absoluteString];
            }
            source = [[SJAliMediaSource alloc] initWithSource:urlSource];
            [self setSource:source];
        }
    }
    return source;
}
@end

NS_ASSUME_NONNULL_END
