//
//  SJAVMediaPlayerLoader.h
//  Pods
//
//  Created by BlueDancer on 2019/4/10.
//

#import <Foundation/Foundation.h>
#import "SJAVMediaModelProtocol.h"
#import "SJAVMediaPlaybackDefines.h"

NS_ASSUME_NONNULL_BEGIN
@interface SJAVMediaPlayerLoader : NSObject
+ (void)loadPlayerForMedia:(id<SJMediaModelProtocol>)media completionHandler:(void(^_Nullable)(id<SJMediaModelProtocol> media, id<SJAVMediaPlayerProtocol> player))completionHandler;
@end
NS_ASSUME_NONNULL_END
