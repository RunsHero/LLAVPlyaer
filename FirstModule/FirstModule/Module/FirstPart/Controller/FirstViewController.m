//
//  FirstViewController.m
//  FirstModule
//
//  Created by 李鹏 on 2018/8/3.
//  Copyright © 2018年 lipeng. All rights reserved.
//

#import "FirstViewController.h"
#import "TTPlayerView.h"
@interface FirstViewController ()

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"首页";
    self.navigationController.navigationBarHidden = YES;
    NSURL * url = [NSURL URLWithString:@"http://static.tripbe.com/videofiles/20121214/9533522808.f4v.mp4"];
    self.playerView = [[TTPlayerView alloc] init];
    [self.playerView createPlayerWith:url];
    self.playerView.titleLabel.text = @"视频播放标题";
    [self.view addSubview:self.playerView];

    NSNumber *value = [NSNumber numberWithInt:4];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    // 开始接受远程控制
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self resignFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // 接触远程控制
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}
// 重写父类成为响应者方法
- (BOOL)canBecomeFirstResponder
{
    return YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
