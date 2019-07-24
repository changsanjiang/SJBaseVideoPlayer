//
//  ViewController.m
//  Project
//
//  Created by BlueDancer on 2018/2/22.
//  Copyright © 2018年 SanJiang. All rights reserved.
//

#import "ViewController.h"
#import "SJBaseVideoPlayer.h"
#import <Masonry.h>

@implementation UIViewController (RotationControl)

- (BOOL)shouldAutorotate {
    return NO;
}

@end


@interface ViewController ()

@property (nonatomic, strong) SJBaseVideoPlayer *videoPlayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _videoPlayer = [SJBaseVideoPlayer player];
    
    [self.view addSubview:_videoPlayer.view];
    
    [_videoPlayer.view mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11.0, *)) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        } else {
            make.top.offset(0);
        }
        make.leading.trailing.offset(0);
        make.height.equalTo(self->_videoPlayer.view.mas_width).multipliedBy(9 / 16.0f);
    }];

//    _videoPlayer.placeholderImageView.image =
    
    _videoPlayer.URLAsset = [[SJVideoPlayerURLAsset alloc] initWithURL:[NSURL URLWithString:@"https://dh2.v.netease.com/2017/cg/fxtpty.mp4"]];
    
    _videoPlayer.pauseWhenAppDidEnterBackground = NO;
    
//    [_videoPlayer rotation];
    
    
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (BOOL)prefersStatusBarHidden {
    return _videoPlayer.vc_prefersStatusBarHidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return _videoPlayer.vc_preferredStatusBarStyle;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)playVideo:(id)sender {
    _videoPlayer.assetURL = [[NSBundle mainBundle] URLForResource:@"sample" withExtension:@"mp4"];
}
- (IBAction)play:(id)sender {
    [_videoPlayer play];
}
- (IBAction)pause:(id)sender {
    [_videoPlayer pause];
}
- (IBAction)stop:(id)sender {
    [_videoPlayer stop];
}
- (IBAction)refresh:(id)sender {
    [_videoPlayer refresh];
}
- (IBAction)sub:(id)sender {
    [_videoPlayer seekToTime:_videoPlayer.currentTime -15 completionHandler:nil];
}
- (IBAction)add:(id)sender {
    [_videoPlayer seekToTime:_videoPlayer.currentTime +15 completionHandler:nil];
}
@end
