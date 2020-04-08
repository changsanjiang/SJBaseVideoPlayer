//
//  ViewController.m
//  Project
//
//  Created by BlueDancer on 2018/2/22.
//  Copyright © 2018年 SanJiang. All rights reserved.
//

#import "ViewController.h"
#import <Masonry.h>
#import <SJBaseVideoPlayer/SJBaseVideoPlayer.h>

@interface ViewController ()
@property (nonatomic, strong) SJBaseVideoPlayer *player;
@end

@implementation ViewController

- (BOOL)shouldAutorotate {
    return NO;
}
 
- (void)viewDidLoad {
    [super viewDidLoad];
    
    _player = [SJBaseVideoPlayer player]; 
    [self.view addSubview:_player.view];
    
    [_player.view mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11.0, *)) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        } else {
            make.top.offset(0);
        }
        make.leading.trailing.offset(0);
        make.height.equalTo(self->_player.view.mas_width).multipliedBy(9 / 16.0f);
    }];

//    _player.placeholderImageView.image =
    
    _player.URLAsset = [[SJVideoPlayerURLAsset alloc] initWithURL:[NSURL URLWithString:@"https://dh2.v.netease.com/2017/cg/fxtpty.mp4"]];
    
    _player.pauseWhenAppDidEnterBackground = NO;
    
//    [_player rotation];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)playVideo:(id)sender {
    _player.assetURL = [NSURL URLWithString:@"https://dh2.v.netease.com/2017/cg/fxtpty.mp4"];
}
- (IBAction)play:(id)sender {
    [_player play];
}
- (IBAction)pause:(id)sender {
    [_player pause];
}
- (IBAction)stop:(id)sender {
    [_player stop];
}
- (IBAction)refresh:(id)sender {
    [_player refresh];
}
- (IBAction)sub:(id)sender {
    [_player seekToTime:_player.currentTime -15 completionHandler:nil];
}
- (IBAction)add:(id)sender {
    [_player seekToTime:_player.currentTime +15 completionHandler:nil];
}
@end
