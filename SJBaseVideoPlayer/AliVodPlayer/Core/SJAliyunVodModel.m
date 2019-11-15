//
//  SJAliyunVodModel.m
//  Demo
//
//  Created by BlueDancer on 2019/11/13.
//  Copyright © 2019 SanJiang. All rights reserved.
//

#import "SJAliyunVodModel.h"

@implementation SJAliyunVodModel
- (instancetype)init {
    self = [super init];
    if ( self ) {
        _maxSize = 500;
        _maxDuration = 300;
    }
    return self;
}
@end


@implementation SJAliyunVodURLModel
- (instancetype)initWithURL:(NSURL *)URL {
    self = [super init];
    if ( self ) {
        _URL = URL;
    }
    return self;
}
@end

@implementation SJAliyunVodStsModel
- (instancetype)initWithVid:(NSString *)vid
                accessKeyId:(NSString *)accessKeyId
            accessKeySecret:(NSString *)accessKeySecret
              securityToken:(NSString *)securityToken
                     region:(NSString *)region {
    self = [super init];
    if ( self ) {
        _vid = vid.copy;
        _accessKeyId = accessKeyId.copy;
        _accessKeySecret = accessKeySecret.copy;
        _securityToken = securityToken.copy;
        _region = region.copy; 
    }
    return self;
}
@end

@implementation SJAliyunVodAuthModel
- (instancetype)initWithVid:(NSString *)vid
                   playAuth:(NSString *)playAuth {
    self = [super init];
    if ( self ) {
        _vid = vid.copy;
        _playAuth = playAuth.copy; 
    }
    return self;
}
@end

@implementation SJAliyunVodMpsModel
- (instancetype)initWithVid:(NSString*)vid
                 accId:(NSString *)accId
             accSecret:(NSString*)accSecret
              stsToken:(NSString*)stsToken
              authInfo:(NSString*)authInfo
                region:(NSString*)region
            playDomain:(NSString*)playDomain
             mtsHlsUriToken:(NSString*)mtsHlsUriToken {
    self = [super init];
    if ( self ) {
        _vid = vid.copy;
        _accId = accId.copy;
        _accSecret = accSecret.copy;
        _stsToken = stsToken.copy;
        _authInfo = authInfo.copy;
        _region = region.copy;
        _playDomain = playDomain.copy;
        _mtsHlsUriToken = mtsHlsUriToken.copy;
    }
    return self;
}
@end
