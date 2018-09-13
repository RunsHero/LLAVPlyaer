//
//  BulletManager.m
//  CommentDemo
//
//  Created by 李鹏 on 2018/9/12.
//  Copyright © 2018年 lipeng. All rights reserved.
//

#import "BulletManager.h"
#import "BulletView.h"
@interface BulletManager()
//弹幕的数据来源
@property (nonatomic, strong) NSMutableArray * datasource;
//弹幕使用过程中的数组变量
@property (nonatomic, strong) NSMutableArray * bulletComments;
//存储弹幕View的数组变量
@property (nonatomic, strong) NSMutableArray *bulletViews;

@property BOOL bStopAnimation;

@end

@implementation BulletManager

- (instancetype) init{
    if (self = [super init]) {
        self.bStopAnimation = YES;
    }
    return self;
}
- (void)start{
    if (!self.bStopAnimation) {
        return;
    }
    self.bStopAnimation = NO;
    [self.bulletComments removeAllObjects];
    [self.bulletComments addObjectsFromArray:self.datasource];
    
    [self initBulletComment];
}
- (void)stop{
    if (self.bStopAnimation) {
        return;
    }
    self.bStopAnimation = YES;
    [self.bulletViews enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BulletView * view = obj;
        [view stopAnimation];
        view = nil;
    }];
    [self.bulletViews removeAllObjects];
}
- (BOOL)status{
    if (self.bStopAnimation) {
        return NO;
    }else{
        return YES;
    }
}
- (void)initBulletComment {
    NSMutableArray * trajectorys = [NSMutableArray arrayWithArray:@[@(0),@(1),@(2),@(3)]];
    for (int i=0; i<4; i++) {
        if (self.bulletComments.count > 0) {
            //通过随机数获取到弹幕的轨迹
            NSInteger index = arc4random()%trajectorys.count;
            int trajectory = [[trajectorys objectAtIndex:index] intValue];
            [trajectorys removeObjectAtIndex:index];
            //从弹幕数组中逐一取出弹幕数据
            NSString *comment = [self.bulletComments firstObject];
            [self.bulletComments removeObjectAtIndex:0];
            //创建弹幕view
            [self createBulletView:comment trajectory:trajectory];
        }
    }
}
- (void)createBulletView:(NSString *)comment trajectory:(int)trajectory{
    if (self.bStopAnimation) {
        return;
    }
    BulletView * view = [[BulletView alloc] initWithComment:comment];
    view.trajectory = trajectory;
    [self.bulletViews addObject:view];
    
    __weak typeof (view) weakView = view;
    __weak typeof (self) myself = self;
    view.moveStatusBlock = ^(MoveStatus status){
        if (self.bStopAnimation) {
            return ;
        }
        switch (status) {
            case Start:{
                //弹幕开始进入屏幕，讲View加入弹幕管理的变量中bullectViews
                [myself.bulletViews addObject:weakView];
                break;
            }
            case Enter:{
                //弹幕完全进入屏幕，判断是否还有其他内容，如果有则在改弹幕轨迹中创建一个弹幕
                NSString * comment = [myself nextComment];
                if (comment) {
                    [myself createBulletView:comment trajectory:trajectory];
                }
                break;
            }
            case End:{
                //弹幕飞出屏幕后从bulletViews中删除
                if ([myself.bulletViews containsObject:weakView]) {
                    [weakView stopAnimation];
                    [myself.bulletViews removeObject:weakView];
                }
                if (myself.bulletComments.count == 0) {
                    //说明屏幕上已经没有弹幕了，开始循环滚动
                    self.bStopAnimation = YES;
                    [myself start];
                }
                break;
            }
            default:
                break;
        }
    };
    
    if (self.generateViewBlock) {
        self.generateViewBlock(view);
    }
}
- (NSMutableArray *)datasource{
    if (!_datasource) {
        _datasource = [NSMutableArray arrayWithArray:@[@"弹幕1~~~~~~~",
                                                       @"弹幕2~~~~~~~~~~",
                                                       @"弹幕3~~~~",
                                                       @"弹幕4~~~~~~~",
                                                       @"弹幕5~~~~~~~",
                                                       @"弹幕7~~~~",
                                                       @"弹幕8~~~~~~~",
                                                       @"弹幕9~~~~~~~",
                                                       @"弹幕10~~~~",
                                                       @"弹幕11~~~~~~~",
                                                       @"弹幕12~~~~~~~",
                                                       @"弹幕13~~~~",
                                                       @"弹幕14~~~~~~~",
                                                       @"弹幕15~~~~~~~"]];
    }
    return _datasource;
}

- (NSString *)nextComment {
    if (self.bulletComments.count == 0) {
        return nil;
    }
    NSString * comment = [self.bulletComments firstObject];
    if (comment) {
        [self.bulletComments removeObjectAtIndex:0];
    }
    return comment;
}
- (NSMutableArray *)bulletComments{
    if (!_bulletComments) {
        _bulletComments = [NSMutableArray arrayWithArray:nil];
    }
    return _bulletComments;
}
- (NSMutableArray *)bulletViews{
    if (!_bulletViews) {
        _bulletViews = [NSMutableArray arrayWithArray:nil];
    }
    return _bulletViews;
}
@end
