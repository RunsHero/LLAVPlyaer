//
//  MoreView.m
//  FirstModule
//
//  Created by 李鹏 on 2018/8/28.
//  Copyright © 2018年 lipeng. All rights reserved.
//

#import "MoreView.h"
#import "Masonry.h"

@implementation MoreView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self createView];
    }
    return self;
}
- (void)createView{
    self.labTest = [[UILabel alloc] init];
    self.labTest.text = @"测试页面";
    self.labTest.backgroundColor = [UIColor blueColor];
    self.labTest.textAlignment = NSTextAlignmentCenter;
    self.labTest.font = [UIFont systemFontOfSize:15];
    [self addSubview:self.labTest];
    [self.labTest mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.mas_top).mas_offset(5);
        make.left.mas_equalTo(self.mas_left).mas_offset(10);
        make.right.mas_equalTo(self.mas_right).mas_offset(-10);
        make.height.mas_offset(30);
    }];
    
    UIButton * btnTest = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnTest setTitle:@"测试按钮及点击方法" forState:UIControlStateNormal];
    [btnTest setBackgroundColor:[UIColor grayColor]];
    [btnTest addTarget:self action:@selector(testClick) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:btnTest];
    [btnTest mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.labTest.mas_bottom).mas_offset(30);
        make.left.mas_equalTo(self.mas_left).mas_offset(10);
        make.right.mas_equalTo(self.mas_right).mas_offset(-10);
        make.height.mas_offset(30);
    }];
}
- (void)testClick{
    NSLog(@"点击响应事件");
    if ([self.labTest.text isEqualToString:@"点击事件测试效果"]) {
        self.labTest.text = @"测试页面";
    }else{
         self.labTest.text = @"点击事件测试效果";
    }
    
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
