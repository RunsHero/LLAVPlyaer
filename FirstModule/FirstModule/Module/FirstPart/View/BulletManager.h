//
//  BulletManager.h
//  CommentDemo
//
//  Created by 李鹏 on 2018/9/12.
//  Copyright © 2018年 lipeng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BulletView;
@interface BulletManager : NSObject

@property (nonatomic, copy) void(^generateViewBlock)(BulletView * view);

//弹幕开始执行
- (void)start;
//弹幕结束执行
- (void)stop;
//当前状态
- (BOOL)status;
@end
