//
//  AlivcRecordFocusView.m
//  AlivcVideoClient_Entrance
//
//  Created by wanghao on 2019/3/18.
//  Copyright © 2019年 Alibaba. All rights reserved.
//

#import "AlivcRecordFocusView.h"
#import "UIColor+AlivcHelper.h"

@interface AlivcRecordFocusView()

@property (nonatomic, strong)CAShapeLayer *shapeLayer;

@property (nonatomic, strong)NSTimer *timer;

@end

@implementation AlivcRecordFocusView


-(instancetype)initWithFrame:(CGRect)frame{
    self =[super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled =NO;
    }
    return self;
}

-(void)hiddenAction{
    self.hidden = YES;
    [_timer setFireDate:[NSDate distantFuture]];
}

-(void)setCenter:(CGPoint)center{
    [super setCenter:center];
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(hiddenAction) userInfo:nil repeats:YES];
        
    }else{
        [_timer setFireDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    self.hidden =NO;
    if (self.animation) {
        self.transform = CGAffineTransformIdentity;
        //    self.layer.position = point;
        self.layer.anchorPoint = CGPointMake(0.5, 0.5);
        __weak typeof(self)weakSelf = self;
        [UIView animateWithDuration:0.3 animations:^{
            weakSelf.transform = CGAffineTransformMakeScale(0.75, 0.75);
        }];
        
    }
}

- (void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    CGFloat size =CGRectGetWidth(self.frame)-4;
    CGFloat lineLenth = 5;
    UIBezierPath *path =[UIBezierPath bezierPath];
    path.lineWidth = 1.0;

    CGFloat center_x = size/2;
    CGFloat center_y = size/2;
    CGFloat start_x =2;
    CGFloat start_y =2;
    
    [path moveToPoint:CGPointMake(start_x,start_y)];
    [path addLineToPoint:CGPointMake(center_x,start_y)];
    [path addLineToPoint:CGPointMake(center_x,start_y+lineLenth)];

    [path moveToPoint:CGPointMake(center_x,start_y)];
    [path addLineToPoint:CGPointMake(start_x+size,start_y)];
    [path addLineToPoint:CGPointMake(start_x+size,center_y)];
    [path addLineToPoint:CGPointMake(start_x+size-lineLenth,center_y)];

    [path moveToPoint:CGPointMake(start_x+size,center_y)];
    [path addLineToPoint:CGPointMake(start_x+size,start_y+size)];
    [path addLineToPoint:CGPointMake(center_x,start_y+size)];
    [path addLineToPoint:CGPointMake(center_x,start_y+size-lineLenth)];

    [path moveToPoint:CGPointMake(center_x,start_y+size)];
    [path addLineToPoint:CGPointMake(start_x,start_y+size)];
    [path addLineToPoint:CGPointMake(start_x,center_y)];
    [path addLineToPoint:CGPointMake(start_x+lineLenth,center_y)];

    [path moveToPoint:CGPointMake(start_x,center_y)];
    [path addLineToPoint:CGPointMake(start_x, start_y)];
    [path closePath];
    UIColor *lineColor = [UIColor colorWithHexString:@"#FECB2F"];
    [lineColor set];
    [path stroke];
}

-(void)dealloc{
    if (_timer) {
        [_timer setFireDate:[NSDate distantFuture]];
        [_timer invalidate];
        _timer = nil;
    }
}

@end
