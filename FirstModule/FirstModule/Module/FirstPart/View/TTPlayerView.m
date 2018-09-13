//
//  TTPlayerView.m
//  FirstModule
//
//  Created by 李鹏 on 2018/8/12.
//  Copyright © 2018年 lipeng. All rights reserved.
//

#import "TTPlayerView.h"
#import "Masonry.h"
#import "RotationScreen.h"
#import "NSString+time.h"
#import "MoreView.h"
#import "UIButton+EnlargeEdge.h"
#import "TTSlider.h"
#import "AppDelegate.h"
#define RGBColor(r, g, b) [UIColor colorWithRed:r / 255.0 green:g / 255.0 blue:b / 255.0 alpha:1.0]

#define FullWidth [UIScreen mainScreen].bounds.size.width
#define FullHeight [UIScreen mainScreen].bounds.size.height
@interface TTPlayerView ()
{
    BOOL _isIntoBackground; // 是否在后台
    BOOL _isShowToolbar; // 是否显示工具条
    BOOL _isShowMoreView; // 是否显示更多视图
    BOOL _isSliding; // 是否正在滑动
    AVPlayerItem *_playerItem;
    AVPlayerLayer *_playerLayer;
    NSTimer *_timer;
    id _playTimeObserver; // 观察者
    UIView * _statusBar; //隐藏/显示
}
@property (assign, nonatomic) CGPoint startPoint;
@property (assign, nonatomic) CGFloat startVB;
@property (assign, nonatomic) CGFloat startVideoRate;

@property (strong, nonatomic) UISlider* volumeViewSlider;//控制音量

@property (assign, nonatomic) NSTimeInterval total;
@property (assign, nonatomic) CGFloat currentRate; //当前播放进度

@property (strong, nonatomic) UIView *mainView;
@property (strong, nonatomic) UIView *playerView;

@property (strong, nonatomic) UIView *topView;
@property (strong, nonatomic) UIButton *moreButton;


@property (strong, nonatomic) UIButton *playButton;

@property (strong, nonatomic) UIView * lockView;// 锁屏视图
@property (strong, nonatomic) UIButton * lockBtn; //锁屏按钮

@property (strong, nonatomic) UIView *downView;

@property (strong, nonatomic) UILabel *beginLabel;
@property (strong, nonatomic) UILabel *endLabel;
@property (strong, nonatomic) TTSlider *playProgress;
@property (strong, nonatomic) UIProgressView *loadedProgress; // 缓冲进度条
@property (strong, nonatomic) UIButton *rotationButton;
@property (strong, nonatomic) UIButton *barrageButton;

@property (strong, nonatomic) UIButton *playerButton;
@property (strong, nonatomic) UIButton *playerFullScreenButton;

@property (strong, nonatomic) UIView *inspectorView; // 继续播放/暂停播放
@property (strong, nonatomic) UILabel *inspectorLabel; //

@property (strong, nonatomic) MoreView * moreView;

// 约束动画
@property (strong, nonatomic) NSLayoutConstraint *topViewTop;
@property (strong, nonatomic) NSLayoutConstraint *downViewBottom;
@property (strong, nonatomic) NSLayoutConstraint *inspectorViewHeight;


@end
@implementation TTPlayerView


//初始化播放器
- (void)createPlayerWith:(NSURL *)url{
    _playerItem = [[AVPlayerItem alloc]initWithURL:url];
    self.player = [[AVPlayer alloc] initWithPlayerItem:_playerItem];
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    _playerLayer.backgroundColor = [UIColor cyanColor].CGColor;
    //设置播放窗口和当前视图之间的比例显示内容
    _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.layer addSublayer:_playerLayer];
    // 添加观察者，发布通知
    [self addObserverAndNotification];
    _statusBar= [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
   
    [self topView];
    [self downView];
    [self playerButton];
    [self lockViews];
    [self pause];
    [self createMoreView];
    _isShowToolbar = YES;
    _isShowMoreView = YES;
    [self getSystemVolumSlider];
}

/**
 *  添加观察者 、通知 、监听播放进度
 */
- (void)addObserverAndNotification {
    [_playerItem addObserver:self forKeyPath:@"status" options:(NSKeyValueObservingOptionNew) context:nil]; // 观察status属性， 一共有三种属性
    [_playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil]; // 观察缓冲进度
    [self monitoringPlayback:_playerItem]; // 监听播放
    [self addNotification]; // 添加通知
}

// 观察播放进度
- (void)monitoringPlayback:(AVPlayerItem *)item {
    NSLog(@"观察播放进度");
    __weak typeof(self)WeakSelf = self;
    
    // 播放进度, 每秒执行30次， CMTime 为30分之一秒
    _playTimeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 30.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        if (self->_touchMode != TouchPlayerViewModeHorizontal) {
            // 当前播放秒
            float currentPlayTime = (double)item.currentTime.value/ item.currentTime.timescale;
            // 更新slider, 如果正在滑动则不更新
            if (self->_isSliding == NO) {
                [WeakSelf updateVideoSlider:currentPlayTime];
            }
        } else {
            return;
        }
    }];
}

// 更新滑动条
- (void)updateVideoSlider:(float)currentTime {
    self.playProgress.value = currentTime;
    self.beginLabel.text = [NSString convertTime:currentTime];
}
#pragma mark 添加通知
- (void)addNotification {
    // 播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    // 前台通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    // 后台通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}
#pragma mark - 播放完成通知
- (void)playbackFinished:(NSNotification *)notification {
    NSLog(@"视频播放完成通知");
    _playerItem = [notification object];
    // 是否无限循环
    [_playerItem seekToTime:kCMTimeZero]; // 跳转到初始
    [_player play]; // 是否无限循环
}
#pragma mark - 前台通知
- (void)enterForegroundNotification:(NSNotification *)notification{
    NSLog(@"前台通知");
    [self play];
}
#pragma mark - 后台通知
- (void)enterBackgroundNotification:(NSNotification *)notification{
    NSLog(@"后台通知");
    [self pause];
}
- (void)autorotateInterface:(NSNotification *)notification{
    NSLog(@"屏幕旋转");
}
#pragma mark KVO - status
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    AVPlayerItem *item = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        if (_isIntoBackground) {
            return;
        } else { // 判断status 的 状态
            AVPlayerStatus status = [[change objectForKey:@"new"] intValue]; // 获取更改后的状态
            if (status == AVPlayerStatusReadyToPlay) {
                NSLog(@"准备播放");
                // CMTime 本身是一个结构体
                CMTime duration = item.duration; // 获取视频长度
                
                [self customVideoSlider:duration];
                
                // 设置视频时间
                [self setMaxDuration:CMTimeGetSeconds(duration)]; //页面赋值总时长
                // 播放
                [self play];
                
            } else if (status == AVPlayerStatusFailed) {
                NSLog(@"AVPlayerStatusFailed");
            } else {
                NSLog(@"AVPlayerStatusUnknown");
            }
        }
        
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSTimeInterval timeInterval = [self availableDurationRanges]; // 缓冲时间
        CGFloat totalDuration = CMTimeGetSeconds(_playerItem.duration); // 总时间
        [self.loadedProgress setProgress:timeInterval / totalDuration animated:YES];
    }
}

// 设置最大时间
- (void)setMaxDuration:(CGFloat)duration {
    self.playProgress.maximumValue = duration; // maxValue = CMGetSecond(item.duration)
    self.endLabel.text = [NSString convertTime:duration];
}

// 已缓冲进度
- (NSTimeInterval)availableDurationRanges {
    NSArray *loadedTimeRanges = [_playerItem loadedTimeRanges]; // 获取item的缓冲数组
    // CMTimeRange 结构体 start duration 表示起始位置 和 持续时间
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue]; // 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds; // 计算总缓冲时间 = start + duration
    return result;
}
- (void)play {
    _isPlaying = YES;
    [_player play]; // 调用avplayer 的play方法
    [self.playButton setImage:[UIImage imageNamed:@"Stop"] forState:(UIControlStateNormal)];
    [self.playerButton setImage:[UIImage imageNamed:@"player_pause_iphone_window"] forState:(UIControlStateNormal)];
    [self.playerFullScreenButton setImage:[UIImage imageNamed:@"player_pause_iphone_fullscreen"] forState:(UIControlStateNormal)];
}

- (void)pause {
    _isPlaying = NO;
    [_player pause];
    [self.playButton setImage:[UIImage imageNamed:@"Play"] forState:(UIControlStateNormal)];
    [self.playerButton setImage:[UIImage imageNamed:@"player_start_iphone_window"] forState:(UIControlStateNormal)];
    [self.playerFullScreenButton setImage:[UIImage imageNamed:@"player_start_iphone_fullscreen"] forState:(UIControlStateNormal)];
}


#pragma mark 屏幕转动方向



#pragma mark- sizeClass 横竖屏约束
// sizeClass 横竖屏切换时，执行
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    /*  当前屏幕是否是横屏
     *  [RotationScreen isOrientationLandscape]
     *
     *  是否锁定
     *  _isLock
     */
        if (![RotationScreen isOrientationLandscape]) { // 竖屏
            [self verticalView];
        } else { // 横屏
            [self horizontalView];
        }
    
}
//竖屏适配
- (void)verticalView{
    
    self.isLandscape = NO;
    self.lockView.hidden = YES;
    self.moreButton.hidden = YES;
    self.lockBtn.hidden = YES;
    [self moreViewHide];
    self.frame = CGRectMake(0, 0, FullWidth, 282.8);
    [self portraitHide];
    self.downView.backgroundColor = self.topView.backgroundColor = [UIColor clearColor];
    [self.rotationButton setImage:[UIImage imageNamed:@"player_fullScreen_iphone"] forState:(UIControlStateNormal)];
    _playerLayer.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 232.8);
    [_topView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(0);
        make.left.mas_equalTo(0);
        make.width.mas_equalTo(FullWidth);
        make.height.mas_equalTo(54);
    }];
    [_downView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(self.mas_bottom).mas_offset(-44);
        make.left.mas_equalTo(0);
        make.width.mas_equalTo(FullWidth);
        make.height.mas_equalTo(44);
    }];
}
//横屏适配
- (void)horizontalView {
    self.frame = CGRectMake(0, 0, FullWidth, FullHeight);
    self.moreButton.hidden = NO;
    self.isLandscape = YES;
    self.lockView.hidden = NO;
    self.lockBtn.hidden = NO;
    [self moreViewHide];
    [self portraitHide];
    _statusBar.hidden = YES;
    self.downView.backgroundColor = self.topView.backgroundColor = [UIColor clearColor];
    [self.rotationButton setImage:[UIImage imageNamed:@"player_window_iphone"] forState:(UIControlStateNormal)];
    _playerLayer.frame = CGRectMake(0, 0, FullWidth, FullHeight);
    [_topView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(0);
        make.left.mas_equalTo(0);
        make.width.mas_equalTo(FullWidth);
        make.height.mas_equalTo(54);
    }];
    [_downView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(self.mas_bottom).mas_offset(0);
        make.left.mas_equalTo(0);
        make.width.mas_equalTo(FullWidth);
        make.height.mas_equalTo(44);
    }];
    [self.moreView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.mas_top).mas_offset(0);
        make.left.mas_equalTo(self.mas_left).mas_offset(FullWidth/2);
        make.width.mas_offset(FullWidth/2);
        make.height.mas_offset(FullHeight);
    }];
}
#pragma mark 处理点击事件
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _touchMode = TouchPlayerViewModeNone;
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    
    //记录首次触摸坐标
    self.startPoint = point;
    //检测用户是触摸屏幕的左边还是右边，以此判断用户是要调节音量还是亮度，左边是亮度，右边是音量
    if (self.startPoint.x <= self.frame.size.width / 2.0) {
        //亮度
        self.startVB = [UIScreen mainScreen].brightness;
    } else {
        //音量
        self.startVB = self.volumeViewSlider.value;
    }
}

// 移动事件
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"移动事件");
    //得出手指在Button上移动的距离
    UITouch *touch = [touches anyObject];
    CGPoint panPoint = [touch locationInView:self];
    CGPoint point = CGPointMake(panPoint.x - self.startPoint.x, panPoint.y - self.startPoint.y);
    //分析出用户滑动的方向
    if(_touchMode == TouchPlayerViewModeNone){
        if (point.x >= 30 || point.x <= -30) {//进度
            NSLog(@"进度");
            _touchMode = TouchPlayerViewModeHorizontal;
        } else if (point.y >= 30 || point.y <= -30) {//音量和亮度
            NSLog(@"音量和亮度");
            _touchMode = TouchPlayerViewModeVertical;
        }else{
            _touchMode = TouchPlayerViewModeNone;
        }
    }
    if (_touchMode == TouchPlayerViewModeUnknow) {
        
        return;
        
    } else if (_touchMode == TouchPlayerViewModeVertical) {
        //音量和亮度
        if (self.startPoint.x <= self.frame.size.width / 2.0) {
            //调节亮度
            if (point.y < 0) {
                //增加亮度
                NSLog(@"增加亮度");
                [[UIScreen mainScreen] setBrightness:self.startVB + (-point.y / 30.0 / 10)];
            } else {
                //减少亮度
                NSLog(@"减少亮度");
                [[UIScreen mainScreen] setBrightness:self.startVB - (point.y / 30.0 / 10)];
            }
            
        } else {
            //音量
            if (point.y < 0) {
                //增大音量
                NSLog(@"增大音量");
                [self.volumeViewSlider setValue:self.startVB + (-point.y / 30.0 / 10) animated:YES];
                if (self.startVB + (-point.y / 30 / 10) - self.volumeViewSlider.value >= 0.1) {
                    [self.volumeViewSlider setValue:0.1 animated:NO];
                    [self.volumeViewSlider setValue:self.startVB + (-point.y / 30.0 / 10) animated:YES];
                }
                
            } else {
                //减少音量
                NSLog(@"减少音量");
                [self.volumeViewSlider setValue:self.startVB - (point.y / 30.0 / 10) animated:YES];
            }
        }
    } else if (_touchMode == TouchPlayerViewModeHorizontal) {
        //进度
        CGPoint previous = [touch previousLocationInView:self];
        CGFloat offset_x = panPoint.x - previous.x;
        if (offset_x > 0) {
            self.currentRate+=2;
        }else{
            self.currentRate-=2;
        }
        CGFloat time = self.currentRate;
        NSLog(@"%lf",time);
        if (self.isPlaying) {
            if (time < 0) {
                time = 0;
            }else if (time > self.playProgress.maximumValue){
                time = self.playProgress.maximumValue;
            }
            [self updateVideoSlider:time];
            [_playerItem seekToTime:CMTimeMakeWithSeconds(time, 1) completionHandler:^(BOOL finished) {
                //在这里处理进度设置成功后的事情
            }];
        }
    }
    
}
//结束事件
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"结束事件");

    if (_touchMode == TouchPlayerViewModeNone) {
        NSLog(@"轻点-方法");
        if (_isLandscape) { // 如果当前是横屏
            NSLog(@"横屏--状态");
            if (_isShowToolbar) {
                NSLog(@"隐藏----工具条");
                [self portraitHide];
                _statusBar.hidden = YES;
            } else {
                NSLog(@"显示----工具条");
                if ([touches anyObject].view != _moreView) {
                    // 判断点击的区域如果不是_moreView 视图, 则关闭菜单
                    [self portraitShow];
                }
                if (_isShowMoreView) {
                    NSLog(@"<更多> - 隐藏");
                    if ([touches anyObject].view != _moreView) {
                        // 判断点击的区域如果不是_moreView 视图, 则关闭菜单
                        [self moreViewHide];
                        [self portraitShow];
                        _statusBar.hidden = NO;
                    }
                }
            }
        } else { // 如果是竖屏
            NSLog(@"竖屏--状态");
            if (_isShowToolbar) {
                NSLog(@"隐藏----工具条");
                [self portraitHide];
                _statusBar.hidden = NO;
            } else {
                NSLog(@"显示----工具条");
                [self portraitShow];
            }
        }
    }
    
}
//音量视图
- (UISlider*)getSystemVolumSlider{
    static UISlider * volumeViewSlider = nil;
    
    if (volumeViewSlider == nil) {
        MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(10, 50, 200, 4)];
        for (UIView* newView in volumeView.subviews) {
            if ([newView.class.description isEqualToString:@"MPVolumeSlider"]){
                volumeViewSlider = (UISlider*)newView;
                break;
            }
        }
    }
    self.volumeViewSlider = volumeViewSlider;
    return self.volumeViewSlider;
}
// 显示工具条
- (void)portraitShow {
    _isShowToolbar = YES; // 显示工具条置为 yes
    // 约束动画
    self.topViewTop.constant = 0;
    self.downViewBottom.constant = 0;
    [UIView animateWithDuration:0.1 animations:^{
        [self layoutIfNeeded];
        self.topView.alpha = self.downView.alpha = 1;
        self.playerButton.alpha = self.playerFullScreenButton.alpha = 1;
    } completion:^(BOOL finished) {
    }];
    // 显示状态条
    _statusBar.hidden = NO;

}

- (void)portraitHide {
    _isShowToolbar = NO; // 显示工具条置为 no
    
    // 约束动画
    self.topViewTop.constant = -(self.topView.frame.size.height);
    self.downViewBottom.constant = -(self.downView.frame.size.height);
    [UIView animateWithDuration:0.1 animations:^{
        [self layoutIfNeeded];
        self.topView.alpha = self.downView.alpha = 0;
        self.playerButton.alpha = self.playerFullScreenButton.alpha = 0;
    } completion:^(BOOL finished) {
        
    }];
    // 隐藏状态条
    if (_isLandscape) {
        _statusBar.hidden = YES;
    }else{
        _statusBar.hidden = NO;
    }
}

- (void)moreViewHide{
    self.moreView.hidden = YES;
}
- (void)moreViewShow{
    self.moreView.hidden = NO;
}


#pragma mark-
#pragma mark 滑块事件
- (void)playerSliderTouchDown:(id)sender {
    [self pause];
}

- (void)playerSliderTouchUpInside:(id)sender {
    _isSliding = NO; // 滑动结束
    [self play];
}

// 不要拖拽的时候改变， 手指抬起来后缓冲完成再改变
- (void)playerSliderValueChanged:(id)sender {
    _isSliding = YES;
    [self pause];
    CMTime changedTime = CMTimeMakeWithSeconds(self.playProgress.value, 1.0);
    NSLog(@"%.2f", self.playProgress.value);
    [_playerItem seekToTime:changedTime completionHandler:^(BOOL finished) {
        // 跳转完成后做某事
    }];
}

//上方视图
#pragma mark - 上方视图
- (UIView *)topView{
    if (_topView == nil) {
        _topView = [[UIView alloc] init];
        _topView.backgroundColor = [UIColor clearColor];
        [self addSubview:_topView];
        
        UIButton * backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [backBtn setEnlargeEdge:10];
        [backBtn setBackgroundImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
        [backBtn addTarget:self action:@selector(backClick) forControlEvents:UIControlEventTouchUpInside];
        [_topView addSubview:backBtn];
        [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(20);
            make.left.mas_equalTo(20);
            make.width.mas_equalTo(24);
            make.height.mas_equalTo(24);
        }];
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.textAlignment = NSTextAlignmentLeft;
        self.titleLabel.font = [UIFont systemFontOfSize:14];
        [_topView addSubview:self.titleLabel];
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(24);
            make.left.mas_equalTo(backBtn.mas_right).mas_offset(5);
            make.right.mas_equalTo(self.mas_right).mas_offset(-104);
            make.height.mas_equalTo(16);
        }];
        self.moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.moreButton setBackgroundImage:[UIImage imageNamed:@"report"] forState:UIControlStateNormal];
        [self.moreButton addTarget:self action:@selector(moreClick) forControlEvents:UIControlEventTouchUpInside];
        [_topView addSubview:self.moreButton];
        [self.moreButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(self.titleLabel.mas_centerY);
            make.right.mas_equalTo(-10);
            make.width.mas_equalTo(32);
            make.height.mas_equalTo(32);
        }];
    }
    return _topView;
}
//下方视图
#pragma mark - 下方视图
- (UIView *)downView{
    if (_downView == nil) {
        _downView = [[UIView alloc] init];
        _downView.backgroundColor = [UIColor clearColor];
        [self addSubview:_downView];
        [_downView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.mas_equalTo(self.mas_bottom).mas_offset(0);
            make.left.mas_equalTo(0);
            make.width.mas_equalTo(FullWidth);
            make.height.mas_equalTo(44);
        }];
        self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.playButton setEnlargeEdge:10];
        [self.playButton addTarget:self action:@selector(playOrPause) forControlEvents:UIControlEventTouchUpInside];
        [_downView addSubview:self.playButton ];
        [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(12);
            make.left.mas_equalTo(12);
            make.width.mas_equalTo(20);
            make.height.mas_equalTo(20);
        }];
        
        self.rotationButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.rotationButton setEnlargeEdge:10];
        [self.rotationButton setImage:[UIImage imageNamed:@"Rotation"] forState:UIControlStateNormal];
        [self.rotationButton addTarget:self action:@selector(switchScreen) forControlEvents:UIControlEventTouchUpInside];
        [_downView addSubview:self.rotationButton];
        [self.rotationButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(3);
            make.left.mas_equalTo(self.mas_right).mas_offset(-60);
            make.width.mas_equalTo(38);
            make.height.mas_equalTo(38);
        }];
        
        self.barrageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.barrageButton setEnlargeEdge:10];
        [self.barrageButton setImage:[UIImage imageNamed:@"barrage"]forState:UIControlStateNormal];
        [self.barrageButton addTarget:self action:@selector(barrageClick:) forControlEvents:UIControlEventTouchUpInside];
        [_downView addSubview:self.barrageButton];
        [self.barrageButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(3);
            make.left.mas_equalTo(self.mas_right).mas_offset(-130);
            make.width.mas_equalTo(48);
            make.height.mas_equalTo(32);
        }];
         
         
        [self beginLab];
        [self loadedProgres];
        [self playProgres];
        [self endLab];
    }
    return _downView;
}
//右下方大播放按钮
- (UIButton *)playerButton{
    if (_playerButton == nil) {
        _playerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playerButton addTarget:self action:@selector(playOrPause) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_playerButton];
        [_playerButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.mas_equalTo(self.downView.mas_top).mas_offset(-20);
            make.left.mas_equalTo(self.mas_right).mas_offset(-84);
            make.width.mas_equalTo(64);
            make.height.mas_equalTo(64);
        }];
    }
    return _playerButton;
}
- (UIView *)lockViews{
    
    if (self.lockView == nil) {
        
        self.lockView = [[UIView alloc] init];
        self.lockView.alpha = 0.5;
        self.lockView.layer.cornerRadius = 19;
        self.lockView.backgroundColor = [UIColor blackColor];
        [self addSubview:self.lockView];
        [self.lockView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(self.mas_centerY);
            make.left.mas_equalTo(self.mas_left).mas_offset(20);
            make.width.mas_offset(38);
            make.height.mas_offset(38);
        }];
        if (self.lockBtn == nil) {
            self.lockBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            [self.lockBtn setBackgroundColor:[UIColor blackColor]];
            [self.lockBtn setBackgroundImage:[UIImage imageNamed:@"unLock"] forState:UIControlStateNormal];
            [self.lockBtn addTarget:self action:@selector(lockClick:) forControlEvents:UIControlEventTouchUpInside];
            [self.lockBtn setEnlargeEdge:10.0];
            [self.lockView addSubview:self.lockBtn];
            [self.lockBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(self.lockView.mas_top).mas_offset(11);
                make.left.mas_equalTo(self.lockView.mas_left).mas_offset(11);
                make.width.mas_offset(16);
                make.height.mas_offset(16);
            }];
        }
    }
   
    return self.lockView;
}

//锁屏事件处理
- (void)lockClick:(UIButton *)sender{
    [self.playerViewDelegate lockClick:sender];
}
//开始时间、播放进度
#pragma mark - 开始时间、播放进度
- (UILabel *)beginLab{
    if (self.beginLabel == nil) {
        self.beginLabel = [[UILabel alloc] init];
        self.beginLabel.textAlignment = NSTextAlignmentCenter;
        self.beginLabel.font = [UIFont systemFontOfSize:11];
        [_downView addSubview:self.beginLabel];
        [self.beginLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.playButton);
            make.left.mas_equalTo(self.playButton.mas_right).mas_offset(10);
            make.width.mas_equalTo(40);
            make.height.mas_equalTo(15);
        }];
    }
    return self.beginLabel;
}
//缓冲进度条
#pragma mark - 缓冲进度条
- (UIProgressView *)loadedProgres{
    
    if (self.loadedProgress == nil) {
        self.loadedProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        self.loadedProgress.backgroundColor = [UIColor blackColor];
        [_downView addSubview:self.loadedProgress];
        [self.loadedProgress mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.playButton);
            make.left.mas_equalTo(self.beginLabel.mas_right).mas_offset(5);
            make.width.mas_equalTo(238);
            make.height.mas_equalTo(2);
        }];
    }
    return self.loadedProgress;
}
//播放时间+进度条
#pragma mark - 播放时间+进度条
//快进、快退、播放进度条
- (UISlider *)playProgres{
    if (_playProgress == nil) {
        _playProgress = [[TTSlider alloc] init];
        self.playProgress.enabled = YES;
        self.playProgress.userInteractionEnabled = YES;
        [self.playProgress setThumbImage:[UIImage imageNamed:@"icmpv_thumb_light"] forState:(UIControlStateNormal)];
        [self.playProgress addTarget:self action:@selector(playerSliderTouchDown:) forControlEvents:UIControlEventTouchDown];
        [self.playProgress addTarget:self action:@selector(playerSliderTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        [self.playProgress addTarget:self action:@selector(playerSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        [self.loadedProgress addSubview:_playProgress];
        [_playProgress mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.playButton);
            make.left.mas_equalTo(self.beginLabel.mas_right).mas_offset(5);
            make.width.mas_equalTo(238);
            make.height.mas_equalTo(38);
        }];
    }
    return self.playProgress;
}
//总时长
#pragma mark - 总时长显示
- (UILabel *)endLab{
    if (self.endLabel == nil) {
        self.endLabel = [[UILabel alloc] init];
        self.endLabel.textAlignment = NSTextAlignmentCenter;
        self.endLabel.font = [UIFont systemFontOfSize:11];
        [_downView addSubview:self.endLabel];
        [self.endLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.playProgress);
            make.left.mas_equalTo(self.playProgress.mas_right).mas_offset(5);
            make.width.mas_equalTo(40);
            make.height.mas_equalTo(15);
        }];
    }
    return self.endLabel;
}
- (UIView *)createMoreView{
    if (self.moreView == nil) {
        self.moreView = [[MoreView alloc] init];
        self.moreView.backgroundColor = [UIColor redColor];
        self.moreView.hidden = YES;
        [self addSubview:self.moreView];
        [self.moreView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.mas_top).mas_offset(0);
            make.left.mas_equalTo(self.mas_left).mas_offset(FullWidth/2);
            make.width.mas_offset(FullWidth/2);
            make.height.mas_offset(FullHeight);
        }];
    }
    return self.moreView;
}
- (void)customVideoSlider:(CMTime)duration {
    _playProgress.maximumValue = CMTimeGetSeconds(duration);
    UIGraphicsBeginImageContextWithOptions((CGSize){ 1, 1 }, NO, 0.0f);
    UIImage * transparentImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [_playProgress setMinimumTrackImage:transparentImage forState:UIControlStateNormal];
    [_playProgress setMaximumTrackImage:transparentImage forState:UIControlStateNormal];
}

//播放、暂停响应事件
- (void)playOrPause{
    if (self.isPlaying == YES) {
        [self.player pause];
        self.isPlaying = NO;
        [self pause];
    }else{
        [self.player play];
        self.isPlaying = YES;
         [self play];
    }
}
//屏幕切换
- (void)switchScreen{
    NSLog(@"屏幕旋转");
    if ([RotationScreen isOrientationLandscape]) { // 如果是横屏，
       
        [RotationScreen forceOrientation:(UIInterfaceOrientationPortrait)]; // 切换为竖屏
    } else {
        [RotationScreen forceOrientation:(UIInterfaceOrientationLandscapeRight)]; // 否则，切换为横屏
    }
}
- (void)barrageClick:(UIButton *)sender{
    [self.playerViewDelegate barrageClick:sender];
}
//返回上一页
- (void)backClick{
    
    if ([RotationScreen isOrientationLandscape]){
        [RotationScreen forceOrientation:(UIInterfaceOrientationPortrait)]; // 切换为竖屏
    }else{
        NSLog(@"点击返回上一页");
    }
}
//更多点击响应事件
- (void)moreClick{
    NSLog(@"点击了更多按钮");
    self.moreView.hidden = NO;
    [self portraitHide];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
