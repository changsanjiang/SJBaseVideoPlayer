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

@interface ViewController ()

@property (nonatomic, strong) SJBaseVideoPlayer *videoPlayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _videoPlayer = [SJBaseVideoPlayer player];
    
    [self.view addSubview:_videoPlayer.view];
    
    [_videoPlayer.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.offset(0);
        make.height.equalTo(_videoPlayer.view.mas_width).multipliedBy(9 / 16.0f);
    }];

    _videoPlayer.placeholder = [UIImage imageNamed:@"placeholder"];
    
    _videoPlayer.assetURL = [[NSBundle mainBundle] URLForResource:@"sample" withExtension:@"mp4"];
    
    // Do any additional setup after loading the view, typically from a nib.
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
    [_videoPlayer jumpedToTime:_videoPlayer.currentTime -15 completionHandler:nil];
}
- (IBAction)add:(id)sender {
    [_videoPlayer jumpedToTime:_videoPlayer.currentTime +15 completionHandler:nil];
}
@end
