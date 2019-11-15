//
//  SJAliyunVodModel.h
//  Demo
//
//  Created by BlueDancer on 2019/11/13.
//  Copyright © 2019 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface SJAliyunVodModel : NSObject
@property (nonatomic, copy, nullable) NSString *saveDir;
@property (nonatomic) int64_t maxSize; ///< default value is 500
@property (nonatomic) int maxDuration; ///< default value is 300
@end

@interface SJAliyunVodURLModel : SJAliyunVodModel
- (instancetype)initWithURL:(NSURL *)URL;
@property (nonatomic, strong, nullable) NSURL *URL;
@end

@interface SJAliyunVodStsModel : SJAliyunVodModel
- (instancetype)initWithVid:(NSString *)vid
                accessKeyId:(NSString *)accessKeyId
            accessKeySecret:(NSString *)accessKeySecret
              securityToken:(NSString *)securityToken
                     region:(NSString *)region;

@property (nonatomic, copy) NSString* vid;
@property (nonatomic, copy) NSString* accessKeyId;
@property (nonatomic, copy) NSString* accessKeySecret;
@property (nonatomic, copy) NSString* securityToken;
@property (nonatomic, copy) NSString* region;
@end

@interface SJAliyunVodAuthModel : SJAliyunVodModel
- (instancetype)initWithVid:(NSString *)vid
                   playAuth:(NSString *)playAuth;

@property (nonatomic, copy) NSString* vid;
@property (nonatomic, copy) NSString* playAuth;
@end

@interface SJAliyunVodMpsModel : SJAliyunVodModel
- (instancetype)initWithVid:(NSString*)vid
                 accId:(NSString *)accId
             accSecret:(NSString*)accSecret
              stsToken:(NSString*)stsToken
              authInfo:(NSString*)authInfo
                region:(NSString*)region
            playDomain:(NSString*)playDomain
        mtsHlsUriToken:(NSString*)mtsHlsUriToken;

@property (nonatomic, copy) NSString* vid;
@property (nonatomic, copy) NSString* accId;
@property (nonatomic, copy) NSString* accSecret;
@property (nonatomic, copy) NSString* stsToken;
@property (nonatomic, copy) NSString* authInfo;
@property (nonatomic, copy) NSString* region;
@property (nonatomic, copy) NSString* playDomain;
@property (nonatomic, copy) NSString* mtsHlsUriToken;
@end

NS_ASSUME_NONNULL_END
