//
//  VPlayerViewController.m
//  FirstModule
//
//  Created by 李鹏 on 2018/8/31.
//  Copyright © 2018年 lipeng. All rights reserved.
//

#import "VPlayerViewController.h"
#import "AppDelegate.h"
#import "RotationScreen.h"
#import "AppDelegate.h"
#import "BulletView.h"
#import "BulletManager.h"
@interface VPlayerViewController ()<PlayerViewDelegate>
@property (nonatomic, strong) BulletManager * manager;
@end

@implementation VPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"首页";
    self.navigationController.navigationBarHidden = YES;
    NSURL * url = [NSURL URLWithString:@"http://static.tripbe.com/videofiles/20121214/9533522808.f4v.mp4"];
    self.playerView = [[TTPlayerView alloc] init];
    [self.playerView createPlayerWith:url];
    self.playerView.playerViewDelegate = self;
    self.playerView.titleLabel.text = @"视频播放标题";
    [self.view addSubview:self.playerView];
    
    self.manager = [[BulletManager alloc] init];
    __weak typeof(self) myself = self;
    self.manager.generateViewBlock = ^(BulletView *view) {
        [myself addBulletView:view];
    };
    
    
}

- (void)clickStopBtn{
    [self.manager stop];
}
- (void)addBulletView:(BulletView *)view{
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    view.frame = CGRectMake(width+10,  view.trajectory * 80, CGRectGetWidth(view.bounds), CGRectGetHeight(view.bounds));
    [self.view addSubview:view];
    
    [view startAnimation];
}
- (void)lockClick:(UIButton *)sender{
    AppDelegate * delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (delegate.allowRotate == NO) {
        [sender setBackgroundImage:[UIImage imageNamed:@"unLock"] forState:UIControlStateNormal];
        delegate.allowRotate = YES;
    }else{
        [sender setBackgroundImage:[UIImage imageNamed:@"lock"] forState:UIControlStateNormal];
        delegate.allowRotate = NO;
    }
}
- (void)barrageClick:(UIButton *)sender{
    if (self.manager.status) {
        [self.manager stop];
    }else{
        [self.manager start];
    }
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    self.playerView = [[TTPlayerView alloc] init];
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        // 屏幕从竖屏变为横屏时执行
        //赋值Block，并将捕获的值赋值给UILabel
        if (self.playerView.isLock) {
            AppDelegate * delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            delegate.allowRotate = NO;
        }
    }else{
        // 屏幕从横屏变为竖屏时执行
        NSLog(@"屏幕从横屏变为竖屏时执行");
        self.playerView.returnIsLockValueBlock = ^(BOOL isLock){
            
            if (isLock) {
                AppDelegate * delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
                delegate.allowRotate = NO;
            }
        };
    }
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
