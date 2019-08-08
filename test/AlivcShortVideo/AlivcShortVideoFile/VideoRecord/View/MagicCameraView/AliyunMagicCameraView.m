//
//  MagicCameraView.m
//  AliyunVideo
//
//  Created by Vienta on 2017/1/3.
//  Copyright (C) 2010-2017 Alibaba Group Holding Limited. All rights reserved.
//

#import "AliyunMagicCameraView.h"
#import "AVC_ShortVideo_Config.h"
#import "AlivcUIConfig.h"
#import "AliyunRecordBeautyView.h"
//#import "UIButton+Tool.h"
#import "AlivcRecordFocusView.h"
#import "UIImageView+WebCache.h"

#define finishBtnX  (CGRectGetWidth(self.bounds) - 58 - 10)

@interface AliyunMagicCameraView ()<AliyunRecordBeautyViewDelegate>


/**
 前后摄像头切换按钮
 */
@property (nonatomic, strong) UIButton *cameraIdButton;

/**
 回删按钮
 */
@property (nonatomic, strong) UIButton *deleteButton;

/**
 美颜按钮（录制按钮左边）
 */
@property (nonatomic, strong) UIButton *beautyButton;


/**
 动图按钮（录制按钮右边）
 */
@property (nonatomic, strong) UIButton *gifPictureButton;

/**
 时间显示控件
 */
@property (nonatomic, strong) UILabel *timeLabel;

/**
 手指按下录制按钮的时间
 */
@property (nonatomic, assign) double startTime;

/**
 点击录制按钮旁边左右两个按钮弹出的view
 */
@property (nonatomic, weak) AliyunRecordBeautyView *beautyView;

/**
 录制按钮右边的按钮
 */
@property (nonatomic, strong) AliyunRecordBeautyView *rightView;
/**
 录制按钮左边的按钮
 */
@property (nonatomic, strong) AliyunRecordBeautyView *leftView;
/**
 底部显示三角形的view
 */
@property (nonatomic, strong) UIImageView *triangleImageView;

/**
 显示单击拍文字的按钮
 */
@property (nonatomic, strong) UIButton *tapButton;

/**
 显示长按拍文字的按钮
 */
@property (nonatomic, strong) UIButton *longPressButton;

/**
 时间显示控件旁边的小圆点，正在录制的时候显示
 */
@property (nonatomic, strong) UIImageView *dotImageView;

@property (nonatomic, copy) NSArray *effectItems; //动图

/**
 短视频拍摄界面UI配置
 */
@property (nonatomic, strong) AlivcRecordUIConfig *uiConfig;

/**
  是否是第一次加载动图和MV数据
 */
@property (nonatomic, assign) BOOL isFirst;

@property (nonatomic, strong)AlivcRecordFocusView *focusView;

@property (nonatomic, assign)CFTimeInterval cameraIdButtonClickTime;

@property (nonatomic, strong) UIImageView *coverImageView;

@end

@implementation AliyunMagicCameraView

- (instancetype)initWithUIConfig:(AlivcRecordUIConfig *)uiConfig{
    self = [super initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    if(self){
        _uiConfig = uiConfig;
        [AliyunIConfig config].recordType = AliyunIRecordActionTypeClick;
        [self setupSubview];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
    
        [self setupSubview];
    }
    return self;
}

/**
 添加子控件
 */
- (void)setupSubview
{
    _cameraIdButtonClickTime =CFAbsoluteTimeGetCurrent();
    if(!_uiConfig){
        _uiConfig = [[AlivcRecordUIConfig alloc]init];
    }
    self.topView = [[UIView alloc] initWithFrame:CGRectMake(0,(IPHONEX ? 44 + 14 : 14), CGRectGetWidth(self.bounds), 44+8)];
    [self addSubview:self.topView];
    
    [self.topView addSubview:self.backButton];
    [self.topView addSubview:self.cameraIdButton];
    [self.topView addSubview:self.flashButton];
    self.flashButton.enabled = NO;
    [self.topView addSubview:self.countdownButton];
    [self.topView addSubview:self.finishButton];
    [self addSubview:self.musicButton];
    [self addSubview:self.filterButton];
    [self insertSubview:self.previewView atIndex:0];
    
    self.bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.bounds) - 60 , CGRectGetWidth(self.bounds), 60)];
    self.bottomView.backgroundColor = [AlivcUIConfig shared].kAVCBackgroundColor;
    [self addSubview:self.bottomView];
    
    self.topView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.01];
    
    
    self.deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(ScreenWidth/2-40, ScreenHeight-42 - SafeBottom, 70, 40)];
    self.deleteButton.hidden = YES;
    self.deleteButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.deleteButton setTitle:@" 回删" forState:UIControlStateNormal];
    [self.deleteButton setImage:_uiConfig.deleteImage forState:UIControlStateNormal];
    [self.deleteButton addTarget:self action:@selector(deletePartClicked) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.deleteButton];
    
  
    
    self.circleBtn = [[MagicCameraPressCircleView alloc] initWithFrame:CGRectMake(ScreenWidth/2-40, ScreenHeight - 120 - SafeBottom, 75, 75)];
    [self addSubview:self.circleBtn];
    [self.circleBtn addTarget:self action:@selector(recordButtonTouchUp) forControlEvents:UIControlEventTouchUpInside];
    [self.circleBtn addTarget:self action:@selector(recordButtonTouchDown) forControlEvents:UIControlEventTouchDown];
    [self.circleBtn addTarget:self action:@selector(recordButtonTouchUpDragOutside) forControlEvents:UIControlEventTouchDragOutside];
    
    CGFloat rateViewH = 35;
    CGFloat rateViewY = CGRectGetMinY(self.circleBtn.frame) - rateViewH - 12;
    self.rateView = [[AliyunRateSelectView alloc] initWithItems:@[@"极慢",@"慢",@"标准",@"快",@"极快"]];
    self.rateView.frame = CGRectMake(40,rateViewY, ScreenWidth-80, rateViewH);
    self.rateView.selectedSegmentIndex = 2;
    [self.rateView addTarget:self action:@selector(rateChanged:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:self.rateView];
    
    
    self.beautyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.beautyButton setImage:_uiConfig.faceImage forState:UIControlStateNormal];
    [self.beautyButton setBackgroundColor:[UIColor clearColor]];
    [self.beautyButton addTarget:self action:@selector(beauty) forControlEvents:UIControlEventTouchUpInside];
    self.beautyButton.frame = CGRectMake(0, 0, 40, 70);
    CGFloat y = self.circleBtn.center.y;
    CGFloat x = ScreenWidth/2-120;
    self.beautyButton.center = CGPointMake(x, y);
    [self.beautyButton setTitle:@"美颜" forState:UIControlStateNormal];
    [self.beautyButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.beautyButton.titleLabel.font = [UIFont systemFontOfSize:12];
    CGFloat titleHeight = self.beautyButton.titleLabel.intrinsicContentSize.height;
    CGFloat imageWidth = self.beautyButton.imageView.frame.size.width;
    CGFloat imageHeight = self.beautyButton.imageView.frame.size.height;
    self.beautyButton.imageEdgeInsets = UIEdgeInsetsMake(0, (40 - imageWidth) * 0.5, titleHeight + 8, 0);
    self.beautyButton.titleEdgeInsets = UIEdgeInsetsMake(imageHeight + 8, -imageWidth, 0, 0);
    self.beautyButton.layer.shadowColor = [UIColor grayColor].CGColor;
    self.beautyButton.layer.shadowOpacity = 0.5;
    self.beautyButton.layer.shadowOffset = CGSizeMake(1, 1);
    
    [self addSubview:self.beautyButton];
    
    self.gifPictureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.gifPictureButton setImage:_uiConfig.magicImage forState:UIControlStateNormal];
    [self.gifPictureButton setBackgroundColor:[UIColor clearColor]];
    [self.gifPictureButton addTarget:self action:@selector(getGifPictureView) forControlEvents:UIControlEventTouchUpInside];
    self.gifPictureButton.frame = CGRectMake(0, 0, 40, 70);
    self.gifPictureButton.center = CGPointMake(ScreenWidth/2+120, y);
    
    [self.gifPictureButton setTitle:@"道具" forState:UIControlStateNormal];
    [self.gifPictureButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.gifPictureButton.titleLabel.font = [UIFont systemFontOfSize:12];
    CGFloat gif_titleHeight = self.gifPictureButton.titleLabel.intrinsicContentSize.height;
    CGFloat gif_imageWidth = self.gifPictureButton.imageView.frame.size.width;
    CGFloat gif_imageHeight = self.gifPictureButton.imageView.frame.size.height;
    self.gifPictureButton.imageEdgeInsets = UIEdgeInsetsMake(0, (40 - gif_imageWidth) * 0.5, gif_titleHeight + 8, 0);
    self.gifPictureButton.titleEdgeInsets = UIEdgeInsetsMake(gif_imageHeight + 8, -gif_imageWidth, 0, 0);
    self.gifPictureButton.layer.shadowColor = [UIColor grayColor].CGColor;
    self.gifPictureButton.layer.shadowOpacity = 0.5;
    self.gifPictureButton.layer.shadowOffset = CGSizeMake(1, 1);
    [self addSubview:self.gifPictureButton];

    
    
    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    self.timeLabel.frame = CGRectMake(0, 0, 60, 16);
    self.timeLabel.backgroundColor = [UIColor clearColor];
    self.timeLabel.textColor = [UIColor whiteColor];
    self.timeLabel.center = CGPointMake(ScreenWidth / 2+10, ScreenHeight - 152-SafeBottom);
    [self addSubview:self.timeLabel];
    
    self.dotImageView = [[UIImageView alloc] initWithImage:_uiConfig.dotImage];
    self.dotImageView.center = CGPointMake(ScreenWidth/2-30, self.timeLabel.center.y);
    self.dotImageView.hidden = YES;
    [self addSubview:self.dotImageView];
    
    [self addSubview:self.progressView];
    
    self.triangleImageView = [[UIImageView alloc] initWithImage:_uiConfig.triangleImage];
    self.triangleImageView.center = CGPointMake(ScreenWidth/2, ScreenHeight-8-SafeBottom);
    [self addSubview:self.triangleImageView];
    
    UIButton *tapButton = [[UIButton alloc] initWithFrame:CGRectMake(ScreenWidth/2-21, ScreenHeight-36-SafeBottom, 45, 20)];
    [tapButton setTitle:@"单击拍" forState:UIControlStateNormal];
    [tapButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [tapButton addTarget:self action:@selector(tapButtonClick) forControlEvents:UIControlEventTouchUpInside];
    tapButton.titleLabel.font = [UIFont systemFontOfSize:14];
    self.tapButton = tapButton;
    [self addSubview:tapButton];
    
    UIButton *longPressButton = [[UIButton alloc] initWithFrame:CGRectMake(ScreenWidth/2-21+72, ScreenHeight-36-SafeBottom, 45, 20)];
    [longPressButton setTitle:@"长按拍" forState:UIControlStateNormal];
    [longPressButton setTitleColor:AlivcOxRGB(0xc3c5c6) forState:UIControlStateNormal];
    [longPressButton addTarget:self action:@selector(longPressButtonClick) forControlEvents:UIControlEventTouchUpInside];
    longPressButton.titleLabel.font = [UIFont systemFontOfSize:14];
    self.longPressButton = longPressButton;
    [self addSubview:longPressButton];
    
    [self setExclusiveTouchInButtons];
}

/**
 按钮间设置不能同时点击
 */
- (void)setExclusiveTouchInButtons{
    [self.tapButton setExclusiveTouch:YES];
    [self.beautyButton setExclusiveTouch:YES];
    [self.gifPictureButton setExclusiveTouch:YES];
    [self.musicButton setExclusiveTouch:YES];
    [self.filterButton setExclusiveTouch:YES];
    [self.countdownButton setExclusiveTouch:YES];
    [self.deleteButton setExclusiveTouch:YES];
    [self.finishButton setExclusiveTouch:YES];
    [self.cameraIdButton setExclusiveTouch:YES];
}


/**
 显示单击拍按钮的点击事件
 */
- (void)tapButtonClick{
    CGFloat y = self.tapButton.center.y;
    self.tapButton.center = CGPointMake(ScreenWidth/2, y);
    self.longPressButton.center = CGPointMake(ScreenWidth/2+72, y);
    [self.tapButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.longPressButton setTitleColor:AlivcOxRGB(0xc3c5c6) forState:UIControlStateNormal];
    [self.circleBtn setTitle:@"" forState:UIControlStateNormal];
    if (self.delegate && [self.delegate respondsToSelector:@selector(tapButtonClicked)]) {
        [self.delegate tapButtonClicked];
    }
    
}

/**
 显示长按拍按钮的点击时间
 */
- (void)longPressButtonClick{
    CGFloat y = self.tapButton.center.y;
    self.tapButton.center = CGPointMake(ScreenWidth/2-72, y);
    self.longPressButton.center = CGPointMake(ScreenWidth/2, y);
    [self.tapButton setTitleColor:AlivcOxRGB(0xc3c5c6) forState:UIControlStateNormal];
    [self.longPressButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.circleBtn setTitle:@"按住拍" forState:UIControlStateNormal];
    if (self.delegate && [self.delegate respondsToSelector:@selector(longPressButtonClicked)]) {
        [self.delegate longPressButtonClicked];
    }
}


/**
 美颜按钮的点击事件
 */
- (void)beauty{

    self.beautyView = self.leftView;
    [self addSubview:self.beautyView];
    self.bottomHide = YES;
    
}

- (AliyunRecordBeautyView *)leftView{
    if (!_leftView) {
        _leftView = [[AliyunRecordBeautyView alloc] initWithFrame:CGRectMake(0, ScreenHeight-180-78-SafeAreaBottom, ScreenWidth, 180+78+SafeAreaBottom)  titleArray:@[@"美颜",@"美肌"] imageArray:@[@"shortVideo_emotion",@"shortVideo_beautySkin"]];
        _leftView.delegate = self;
    }
    return _leftView;
}

/**
 动图按钮的点击事件
 */
- (void)getGifPictureView{
    self.beautyView = self.rightView;
    [self addSubview:self.beautyView];
    self.bottomHide = YES;
    
    if (!self.isFirst) {
        [self refreshUIWithGifItems:self.effectItems];
        self.isFirst = YES;
    }
}

- (AliyunRecordBeautyView *)rightView{
    if (!_rightView) {
       _rightView = [[AliyunRecordBeautyView alloc] initWithFrame:CGRectMake(0, ScreenHeight-200, ScreenWidth, 200)  titleArray:@[@"人脸贴纸"] imageArray:@[@"shortVideo_gifPicture"]];
        _rightView.delegate = self;
        
    }
    return _rightView;
}
- (void)cancelRecordBeautyView{
    if (self.beautyView) {
        self.bottomHide = NO;
        [self.beautyView removeFromSuperview];
    }
    
}

- (void)recordButtonTouchUp {
    NSLog(@" DD----  %f    %f  - %f", CFAbsoluteTimeGetCurrent(), _startTime, (CFAbsoluteTimeGetCurrent() - _startTime));
    switch ([AliyunIConfig config].recordType) {
        case AliyunIRecordActionTypeCombination:
                if (_recording) {
                    [self endRecord];
                }
            break;
            
        case AliyunIRecordActionTypeHold:
            if (_recording) {
                
                [self endRecord];
                self.circleBtn.transform = CGAffineTransformIdentity;
                [self.circleBtn setImage:_uiConfig.videoShootImageNormal forState:UIControlStateNormal];
            }
            break;
            
        case AliyunIRecordActionTypeClick:
            if (_recording) {
                [self endRecord];
                self.circleBtn.transform = CGAffineTransformIdentity;
                [self.circleBtn setImage:_uiConfig.videoShootImageNormal forState:UIControlStateNormal];
                return;
            }else{
                self.tapButton.hidden = YES;
                self.longPressButton.hidden = YES;
                self.triangleImageView.hidden = YES;
                _recording = YES;
                _progressView.videoCount++;
                self.circleBtn.transform = CGAffineTransformScale(self.transform, 1.32, 1.32);
                [self.circleBtn setImage:_uiConfig.videoShootImageShooting forState:UIControlStateNormal];
                self.dotImageView.hidden = NO;
                [_delegate recordButtonRecordVideo];
            }
            break;
        default:
            break;
    }
    
}


- (void)recordButtonTouchDown {
    _startTime = CFAbsoluteTimeGetCurrent();
    
    NSLog(@"  YY----%f---%zd", _startTime,[AliyunIConfig config].recordType);
    
    switch ([AliyunIConfig config].recordType) {
        case AliyunIRecordActionTypeCombination:
            if (_recording) {
                [self endRecord];
                return;
            }else{
                _recording = YES;
            }
            break;
        case AliyunIRecordActionTypeHold:
            
            if (_recording == NO) {
                _recording = YES;
                self.tapButton.hidden = YES;
                self.longPressButton.hidden = YES;
                self.triangleImageView.hidden = YES;
                self.circleBtn.transform = CGAffineTransformScale(self.transform, 1.32, 1.32);
                [self.circleBtn setImage:_uiConfig.videoShootImageLongPressing forState:UIControlStateNormal];
                [self.circleBtn setTitle:@"" forState:UIControlStateNormal];
                _progressView.videoCount++;
                self.dotImageView.hidden = NO;
                [_delegate recordButtonRecordVideo];
            }
            
            break;
            
        case AliyunIRecordActionTypeClick:
            
            break;
        default:
            break;
    }
}

- (void)recordButtonTouchUpDragOutside{
    if ([AliyunIConfig config].recordType == AliyunIRecordActionTypeHold) {
        [self endRecord];
        self.circleBtn.transform = CGAffineTransformIdentity;
        [self.circleBtn setImage:_uiConfig.videoShootImageNormal forState:UIControlStateNormal];
    }
}

/**
 结束录制
 */
- (void)endRecord{
    if (!_recording) {
        return;
    }
    _startTime = 0;
    _recording = NO;
    [_delegate recordButtonPauseVideo];
    _progressView.showBlink = NO;
     [self destroy];
    _deleteButton.enabled = YES;
   
    if ([AliyunIConfig config].recordOnePart) {
        if (_delegate) {
            [_delegate recordButtonFinishVideo];
        }
    }
    self.countdownButton.enabled = YES;
    if (self.progressView.videoCount > 0 ) {
        self.deleteButton.hidden = NO;
    }
    self.dotImageView.hidden = YES;
}


- (void)recordingPercent:(CGFloat)percent
{
    [self.progressView updateProgress:percent];
    if(_recording){
        int d = percent;
        int m = d / 60;
        int s = d % 60;
        self.timeLabel.text = [NSString stringWithFormat:@"%02d:%02d",m,s];
    }
    
    if(percent == 0){
        [self.progressView reset];
        self.deleteButton.hidden = YES;
        self.triangleImageView.hidden = NO;
        self.tapButton.hidden = NO;
        self.longPressButton.hidden = NO;
        self.timeLabel.text = @"";
    }
}

- (void)destroy
{
    self.timeLabel.text = @"";
    self.dotImageView.hidden = YES;
}

#pragma mark - AliyunRecordBeautyViewDelegate
- (void)didChangeAdvancedMode{
    if ([self.delegate respondsToSelector:@selector(didChangeAdvancedMode)]) {
        [self.delegate didChangeAdvancedMode];
    }
}

- (void)didChangeCommonMode{
    if ([self.delegate respondsToSelector:@selector(didChangeCommonMode)]) {
        [self.delegate didChangeCommonMode];
    }
}
- (void)didFetchGIFListData{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didFetchGIFListData)]) {
        [self.delegate didFetchGIFListData];
    }
}
- (void)didSelectEffectFilter:(AliyunEffectFilterInfo *)filter{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectEffectFilter:)]) {
        [self.delegate didSelectEffectFilter:filter];
    }
}

- (void)didChangeBeautyValue:(CGFloat)beautyValue{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didChangeBeautyValue:)]) {
        [self.delegate didChangeBeautyValue:beautyValue];
    }
}

- (void)didChangeAdvancedBeautyWhiteValue:(CGFloat)beautyWhiteValue{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didChangeAdvancedBeautyWhiteValue:)]) {
        [self.delegate didChangeAdvancedBeautyWhiteValue:beautyWhiteValue];
    }
}
- (void)didChangeAdvancedBlurValue:(CGFloat)blurValue{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didChangeAdvancedBlurValue:)]) {
        [self.delegate didChangeAdvancedBlurValue:blurValue];
    }
}
- (void)didChangeAdvancedBigEye:(CGFloat)bigEyeValue{
        if (self.delegate && [self.delegate respondsToSelector:@selector(didChangeAdvancedBigEye:)]) {
        [self.delegate didChangeAdvancedBigEye:bigEyeValue];
    }
}
- (void)didChangeAdvancedSlimFace:(CGFloat)slimFaceValue{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didChangeAdvancedSlimFace:)]) {
        [self.delegate didChangeAdvancedSlimFace:slimFaceValue];
    }
}

- (void)didChangeAdvancedBuddy:(CGFloat)buddyValue{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didChangeAdvancedBuddy:)]) {
        [self.delegate didChangeAdvancedBuddy:buddyValue];
    }
}

- (void)recordBeautyView:(AliyunRecordBeautyView *)view dismissButtonTouched:(UIButton *)button{
    if (self.delegate && [self.delegate respondsToSelector:@selector(magicCameraView:dismissButtonTouched:)]) {
        [self.delegate magicCameraView:self dismissButtonTouched:button];
    }
}

- (void)recordBeatutyViewDidSelectHowToGet:(AliyunRecordBeautyView *)view{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectedHowToGet)]) {
        [self.delegate didSelectedHowToGet];
    }
    
}
#pragma mark - MagicCameraScrollViewDelegate

- (void)focusItemIndex:(NSInteger)index cell:(UICollectionViewCell *)cell
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(effectItemFocusToIndex:cell:)]&&(!_recording) && self.beautyView) {
        [self.delegate effectItemFocusToIndex:index cell: cell];
    }
}

- (void)setHide:(BOOL)hide {
    self.deleteButton.hidden = hide;
    self.topView.hidden = hide;
    self.rateView.hidden = hide;
    self.beautyButton.hidden = hide;
    self.gifPictureButton.hidden = hide;
    self.musicButton.hidden = hide;
    self.filterButton.hidden = hide;
    
}

- (void)setBottomHide:(BOOL)hide{
    _bottomHide = hide;
    self.rateView.hidden = hide;
    self.beautyButton.hidden = hide;
    self.gifPictureButton.hidden = hide;
    self.circleBtn.hidden = hide;
    if(self.progressView.videoCount){
        self.triangleImageView.hidden = YES;
        self.longPressButton.hidden = YES;
        self.tapButton.hidden = YES;
        self.deleteButton.hidden = NO;
    }else{
        self.triangleImageView.hidden = hide;
        self.longPressButton.hidden = hide;
        self.tapButton.hidden = hide;
        self.deleteButton.hidden = YES;
        if ([AliyunIConfig config].recordType == AliyunIRecordActionTypeHold) {
            [self.circleBtn setTitle:@"按住拍" forState:UIControlStateNormal];
        }
    }
    
}

- (void)setRealVideoCount:(NSInteger)realVideoCount{
    if (realVideoCount) {
        self.triangleImageView.hidden = YES;
        self.longPressButton.hidden = YES;
        self.tapButton.hidden = YES;
        self.deleteButton.hidden = NO;
    }else{
        self.triangleImageView.hidden = NO;
        self.longPressButton.hidden = NO;
        self.tapButton.hidden = NO;
        self.deleteButton.hidden = YES;
    }
}
-(void)setMaxDuration:(CGFloat)maxDuration{
    _maxDuration = maxDuration;
    self.progressView.maxDuration = maxDuration;
}

-(void)setMinDuration:(CGFloat)minDuration{
    _minDuration = minDuration;
    self.progressView.minDuration = minDuration;
}

#pragma mark - Getter -
- (UIButton *)backButton
{
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _backButton.backgroundColor = [UIColor clearColor];
        _backButton.frame = CGRectMake(0, 8, 44, 44);
        [_backButton setImage:_uiConfig.backImage forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(backButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

- (UIButton *)finishButton
{
    if (!_finishButton) {
        _finishButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _finishButton.backgroundColor = [UIColor clearColor];
    
        _finishButton.frame = CGRectMake(finishBtnX, 16, 58, 27);
        _finishButton.hidden = NO;
        [_finishButton setTitle:@"下一步" forState:UIControlStateNormal];
        _finishButton.titleLabel.font = [UIFont systemFontOfSize:13];
        [_finishButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; 
        _finishButton.enabled = NO;
        UIColor *bgColor_disable = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.34];
//        UIColor *bgColor_enable =  [UIColor colorWithRed:252/255.0 green:68/255.0 blue:72/255.0 alpha:1/1.0];
        [_finishButton setBackgroundColor:bgColor_disable];
        [_finishButton addTarget:self action:@selector(finishButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        _finishButton.layer.cornerRadius = 2;
        
    }
    return _finishButton;
}

- (UIButton *)cameraIdButton
{
    if (!_cameraIdButton) {
        _cameraIdButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cameraIdButton.backgroundColor = [UIColor clearColor];
        _cameraIdButton.frame = CGRectMake(finishBtnX - 44 - 36, 8, 44, 44);
        [_cameraIdButton setImage:_uiConfig.switchCameraImage forState:UIControlStateNormal];
        [_cameraIdButton addTarget:self action:@selector(cameraIdButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cameraIdButton;
}


- (UIButton *)flashButton
{
    if (!_flashButton) {
        _flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _flashButton.backgroundColor = [UIColor clearColor];
        _flashButton.frame = CGRectMake(finishBtnX - 44 - 36 - 44 - 20, 8, 44, 44);
        _flashButton.hidden = NO;
        [_flashButton setImage:_uiConfig.ligheImageUnable forState:UIControlStateNormal];
        [_flashButton addTarget:self action:@selector(flashButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _flashButton;
}



-(UIButton *)countdownButton {
    if (!_countdownButton) {
        _countdownButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _countdownButton.backgroundColor = [UIColor clearColor];
        _countdownButton.frame = CGRectMake(finishBtnX - 44 - 36 - 44 - 20 - 44 - 20, 8, 44, 44);
        [_countdownButton setImage:_uiConfig.countdownImage forState:UIControlStateNormal];
        [_countdownButton addTarget:self action:@selector(timerButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _countdownButton;
}



- (UIButton *)musicButton{
    if (!_musicButton) {
        _musicButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _musicButton.backgroundColor = [UIColor clearColor];
        _musicButton.frame = CGRectMake(CGRectGetWidth(self.bounds) - 44 - 10, 80 + SafeTop, 44, 50);
        [_musicButton setImage:_uiConfig.musicImage forState:UIControlStateNormal];
        [_musicButton addTarget:self action:@selector(musicButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [_musicButton setTitle:@"剪音乐" forState:UIControlStateNormal];
        _musicButton.titleLabel.font = [UIFont systemFontOfSize:13];
        CGFloat titleHeight = _musicButton.titleLabel.intrinsicContentSize.height;
        //        CGFloat titleWidth = btn.titleLabel.intrinsicContentSize.width;
        CGFloat imageWidth = _musicButton.imageView.frame.size.width;
        CGFloat imageHeight = _musicButton.imageView.frame.size.height;
        
        _musicButton.imageEdgeInsets = UIEdgeInsetsMake(0, (44 - imageWidth) * 0.5, titleHeight + 8, 0);
        _musicButton.titleEdgeInsets = UIEdgeInsetsMake(imageHeight + 8, -imageWidth, 0, 0);
        
        _musicButton.layer.shadowColor = [UIColor grayColor].CGColor;
        _musicButton.layer.shadowOpacity = 0.5;
        _musicButton.layer.shadowOffset = CGSizeMake(1, 1);
       
        
        
    }
    return _musicButton;
}

- (UIButton *)filterButton{
    if (!_filterButton) {
        _filterButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _filterButton.backgroundColor = [UIColor clearColor];
        _filterButton.frame = CGRectMake(CGRectGetWidth(self.bounds) - 44 - 10, SafeTop + 80 + 50 + 26, 44, 50);
        [_filterButton setImage:_uiConfig.filterImage forState:UIControlStateNormal];
        [_filterButton addTarget:self action:@selector(filterButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [_filterButton setTitle:@"滤镜" forState:UIControlStateNormal];
        _filterButton.titleLabel.font = [UIFont systemFontOfSize:13];
        CGFloat titleHeight = _filterButton.titleLabel.intrinsicContentSize.height;
        //        CGFloat titleWidth = btn.titleLabel.intrinsicContentSize.width;
        CGFloat imageWidth = _filterButton.imageView.frame.size.width;
        CGFloat imageHeight = _filterButton.imageView.frame.size.height;
        _filterButton.imageEdgeInsets = UIEdgeInsetsMake(0, (44 - imageWidth) * 0.5, titleHeight + 8, 0);
        _filterButton.titleEdgeInsets = UIEdgeInsetsMake(imageHeight + 8, -imageWidth, 0, 0);
        
        _filterButton.layer.shadowColor = [UIColor grayColor].CGColor;
        _filterButton.layer.shadowOpacity = 0.5;
        _filterButton.layer.shadowOffset = CGSizeMake(1, 1);
        
        
    }
    return _filterButton;
}



- (QUProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[QUProgressView alloc] initWithFrame:CGRectMake(10, IPHONEX ? 43 : 5, CGRectGetWidth(self.bounds) - 20, 4)];
        _progressView.showBlink = NO;
        _progressView.showNoticePoint = YES;
        _progressView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.01];
        _progressView.layer.cornerRadius = 2;
        _progressView.layer.masksToBounds = YES;
    }
    return _progressView;
}

- (UIView *)previewView{
    if (!_previewView) {
        _previewView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    }
    return _previewView;
}

-(AlivcRecordFocusView *)focusView{
    if (!_focusView) {
        CGFloat size = 150;
        _focusView =[[AlivcRecordFocusView alloc]initWithFrame:CGRectMake(0, 0, size, size)];
        _focusView.animation =YES;
        [self.previewView addSubview:_focusView];
    }
    return _focusView;
}

-(void)refreshFocusPointWithPoint:(CGPoint)point{
    self.focusView.center = point;
    [self.previewView bringSubviewToFront:self.focusView];
}




#pragma mark - Actions -

/**
 速度选择控件的点击时间

 @param rateView 速度选择控件
 */
- (void)rateChanged:(AliyunRateSelectView *)rateView {
    CGFloat rate = 1.0f;
    switch (rateView.selectedSegmentIndex) {
        case 0:
            rate = 0.5f;
            break;
        case 1:
            rate = 0.75f;
            break;
        case 2:
            rate = 1.0f;
            break;
        case 3:
            rate = 1.5f;
            break;
        case 4:
            rate = 2.0f;
            break;
        default:
            break;
    }
    [self.delegate didSelectRate:rate];
}

- (void)resetRecordButtonUI{
    self.circleBtn.transform = CGAffineTransformIdentity;
    [self.circleBtn setImage:_uiConfig.videoShootImageNormal forState:UIControlStateNormal];
    self.dotImageView.hidden = YES;
    if([AliyunIConfig config].recordType == AliyunIRecordActionTypeClick){
        [self.circleBtn setTitle:@"" forState:UIControlStateNormal];
    }else if([AliyunIConfig config].recordType == AliyunIRecordActionTypeHold){
        if (!self.progressView.videoCount) {
            [self.circleBtn setTitle:@"按住拍" forState:UIControlStateNormal];
        }
        
    }
}

/**
 返回按钮的点击事件

 @param sender 返回按钮
 */
- (void)backButtonClicked:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(backButtonClicked)]) {
        [self.delegate backButtonClicked];
    }
}


/**
 闪光灯按钮的点击事件

 @param sender 闪光灯按钮
 */
- (void)flashButtonClicked:(id)sender
{
    UIButton *button = (UIButton *)sender;
    if (self.delegate && [self.delegate respondsToSelector:@selector(flashButtonClicked)]) {
        NSString *imageName = [self.delegate flashButtonClicked];
        [button setImage:[AlivcImage imageNamed:imageName] forState:0];
    }
}


/**
 前置、后置摄像头切换按钮的点击事件

 @param sender 前置、后置摄像头切换按钮
 */
- (void)cameraIdButtonClicked:(id)sender
{
    if (CFAbsoluteTimeGetCurrent()-_cameraIdButtonClickTime >1.2) {//限制连续点击时间间隔不能小于1s
//        NSLog(@"=============>切换摄像头");
        _cameraIdButtonClickTime =CFAbsoluteTimeGetCurrent();
        if (self.delegate && [self.delegate respondsToSelector:@selector(cameraIdButtonClicked)]) {
            [self.delegate cameraIdButtonClicked];
        }
    }
}


/**
 定时器按钮的点击事件

 @param sender 定时器按钮
 */
- (void)timerButtonClicked:(id)sender{
    if (self.delegate && [self.delegate respondsToSelector:@selector(timerButtonClicked)]) {
        [self.delegate timerButtonClicked];
        self.triangleImageView.hidden = YES;
        self.tapButton.hidden = YES;
        self.longPressButton.hidden = YES;
        self.timeLabel.text = @"";
        if (self.beautyView) {
            [self.beautyView removeFromSuperview];
        }
    }
    self.countdownButton.enabled = NO;
}


/**
 音乐按钮的点击事件

 @param sender 音乐按钮
 */
- (void)musicButtonClicked:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(musicButtonClicked)]) {
        [self.delegate musicButtonClicked];
    }
}

- (void)filterButtonClicked:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(filterButtonClicked)]) {
        [self.delegate filterButtonClicked];
    }
}
/**
 回删按钮的点击事件
 */
- (void)deletePartClicked {
    if ([self.delegate respondsToSelector:@selector(deleteButtonClicked)]) {
        [self.delegate deleteButtonClicked];
    }
}


/**
 完成按钮的点击事件
 */
- (void)finishButtonClicked {
    if ([self.delegate respondsToSelector:@selector(finishButtonClicked)]) {
        [self.delegate finishButtonClicked];
    }
}



/**
 根据新的动图数组刷新ui
 
 @param effectItems 新的动图数组
 */
- (void)refreshUIWithGifItems:(NSArray *)effectItems{
    if (effectItems) {
        self.effectItems = effectItems;
        if (self.beautyView) {
             [self.beautyView refreshUIWithGifItems:effectItems];
        }
       
    }
}


/**
 动图实际应用时候调用此方法刷新UI选中状态
 */
- (void)refreshUIWhenThePasterInfoApplyedWithIndex:(NSInteger)applyedIndex{
    if (self.beautyView) {
        [self.beautyView refreshUIWhenThePasterInfoApplyedWithIndex:applyedIndex];
    }
}

- (void)enableFinishButton:(BOOL)enable {
    self.finishButton.enabled = enable;
    if (enable) {
        UIColor *bgColor_enable =  [UIColor colorWithRed:252/255.0 green:68/255.0 blue:72/255.0 alpha:1/1.0];
        self.finishButton.backgroundColor = bgColor_enable;
    } else {
        UIColor *bgColor_disable = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.34];
        self.finishButton.backgroundColor = bgColor_disable;
    }
}

- (void)setMusicButtonImage:(NSString *)imageUrl {
    if(imageUrl) {
        [self.coverImageView sd_setImageWithURL:[NSURL URLWithString:imageUrl]];
    } else {
        self.coverImageView.image = nil;
    }
}

- (UIImageView *)coverImageView {
    if (!_coverImageView) {
        CGFloat imageWH = 32;
        _coverImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, imageWH, imageWH)];
        _coverImageView.layer.cornerRadius = imageWH * 0.5;
        _coverImageView.layer.masksToBounds = YES; 
        _coverImageView.center = CGPointMake(self.musicButton.bounds.size.width * 0.5, imageWH * 0.5);
        [self.musicButton addSubview:_coverImageView];
    }
    return _coverImageView;
}

@end
