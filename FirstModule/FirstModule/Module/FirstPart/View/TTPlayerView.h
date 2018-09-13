//
//  TTPlayerView.h
//  FirstModule
//
//  Created by 李鹏 on 2018/8/12.
//  Copyright © 2018年 lipeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@protocol PlayerViewDelegate <NSObject>
//写代理方法
- (void)lockClick:(UIButton *)sender;
- (void)barrageClick:(UIButton *)sender;
@end
typedef NS_ENUM(NSInteger,TouchPlayerViewMode) {
    TouchPlayerViewModeNone, // 轻触
    TouchPlayerViewModeHorizontal, // 水平滑动
    TouchPlayerViewModeVertical, // 纵向滑动
    TouchPlayerViewModeUnknow, // 未知
} ;

typedef void (^ReturnIsLockValueBlock) (BOOL isLock);

@interface TTPlayerView : UIView
{
    TouchPlayerViewMode _touchMode;
    
}
@property (nonatomic, weak) id<PlayerViewDelegate> playerViewDelegate;
@property(nonatomic, copy) ReturnIsLockValueBlock returnIsLockValueBlock;
//视频名称
@property (strong ,nonatomic) UILabel * titleLabel;

// AVPlayer 控制视频播放
@property (nonatomic, strong) AVPlayer *player;

// 播放状态
@property (nonatomic, assign) BOOL isPlaying;

// 是否横屏
@property (nonatomic, assign) BOOL isLandscape;

// 是否锁屏
@property (nonatomic, assign) BOOL isLock;

// 传入视频地址
- (void)createPlayerWith:(NSURL *)url;

// 播放
- (void)play;

// 暂停
- (void)pause;

@end
