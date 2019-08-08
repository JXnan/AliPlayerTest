//
//  AliyunRecordBeautyView.m
//  AliyunVideoClient_Entrance
//
//  Created by 张璠 on 2018/7/6.
//  Copyright © 2018年 Alibaba. All rights reserved.
//

#import "AliyunRecordBeautyView.h"
#import "AliyunToolView.h"
#import "AliyunMagicCameraEffectCell.h"
#import "AliyunPasterInfo.h"
#import <UIImageView+WebCache.h>
#import "AliyunEffectFilterCell.h"
#import "AliyunDBHelper.h"
#import "AliyunResourceRequestManager.h"
#import "AliyunEffectResourceModel.h"
#import "AliyunResourceDownloadManager.h"
#import "AliyunEffectModelTransManager.h"
#import "UIView+AlivcHelper.h"
#import "AlivcPushBeautyDataManager.h"
#import "AlivcLiveBeautifySettingsViewController.h"
#import "MBProgressHUD+AlivcHelper.h"
#import "AVC_ShortVideo_Config.h"

typedef enum : NSUInteger {
    AliyunEditSouceClickTypeNone = 0,
    AliyunEditSouceClickTypeFilter,
    AliyunEditSouceClickTypePaster,
    AliyunEditSouceClickTypeCaption,
    AliyunEditSouceClickTypeMV,
    AliyunEditSouceClickTypeMusic,
    AliyunEditSouceClickTypePaint,
    AliyunEditSouceClickTypeTimeFilter
} AliyunEditSouceClickType;

@interface AliyunRecordBeautyView()<AliyunToolViewDelegate,UICollectionViewDelegate,UICollectionViewDataSource,AlivcLiveBeautifySettingsViewControllerDelegate>

/**
 美颜view
 */
@property (nonatomic, strong) UIView *beautySkinView;

/**
 美肌view
 */
@property (nonatomic, strong) UIView *beautyFaceView;

/**
 动图view
 */
@property (nonatomic, strong) UICollectionView *gifCollectionView;


/**
 文字数组
 */
@property (nonatomic, strong) NSArray *titleArray;

/**
 正在显示的view
 */
@property (nonatomic, weak) UIView *frontView;

/**
 顶部按钮序号
 */
@property (nonatomic, assign) CGFloat buttonTag;

/**
 MV选中的序号
 */
@property (nonatomic, assign) NSInteger selectIndex;

/**
 人脸动图选中的序号
 */
@property (nonatomic, assign) NSInteger selectGifIndex;

/**
 对FMDB包装类的对象
 */
@property (nonatomic, strong) AliyunDBHelper *dbHelper;

/**
 顶部view
 */
@property (nonatomic, strong) AliyunToolView *toolView;

/**
 美颜类型
 */
@property (nonatomic, assign) AliyunBeautyType beautyType;
@property (nonatomic, strong) AlivcLiveBeautifySettingsViewController *beatyFaceSettingViewControl;//高级美颜界面
@property (nonatomic, strong) AlivcLiveBeautifySettingsViewController *beatySkinSettingViewControl;//美肌界面

@property (nonatomic, strong) AlivcPushBeautyDataManager *beautyFaceDataManager_normal;     //普通美颜的数据管理器
@property (nonatomic, strong) AlivcPushBeautyDataManager *beautyFaceDataManager_advanced;   //高级美颜的数据管理器
@property (nonatomic, strong) AlivcPushBeautyDataManager *beautySkinDataManager;            //美肌的数据管理器

/**
 滤镜view的父view
 */
@property (nonatomic, strong) UIView *contentView;

/**
 点击这个button，此类的view消失
 */
@property (nonatomic, strong) UIButton *dismissButton;

@property (nonatomic, copy) NSArray *effectItems; //动图

@property (nonatomic, strong) NSMutableDictionary *cellDic;

@end

@implementation AliyunRecordBeautyView

-(instancetype)initWithFrame:(CGRect)frame titleArray:(NSArray *)titleArray  imageArray:(NSArray *)imageArray{
    self = [super initWithFrame:frame];
    if (self) {
        
        _beautyFaceDataManager_normal = [[AlivcPushBeautyDataManager alloc]initWithType:AlivcPushBeautyParamsTypeShortVideo customSaveString:@"beautyFaceDataManager_normal"];
        _beautyFaceDataManager_advanced = [[AlivcPushBeautyDataManager alloc]initWithType:AlivcPushBeautyParamsTypeShortVideo customSaveString:@"beautyFaceDataManager_advanced"];
        _beautySkinDataManager = [[AlivcPushBeautyDataManager alloc]initWithType:AlivcPushBeautyParamsTypeShortVideo customSaveString:@"beautySkinDataManager"];
        
        [self setup:titleArray imageArray:imageArray];
        self.titleArray = titleArray;
    }
    return self;
}

- (void)setGifSelectedIndex:(NSInteger)selectedIndex{
    self.selectGifIndex = selectedIndex;
    [self.gifCollectionView reloadData];
}


/**
 初始化的一些设置
 
 @param titleArray 文字数组
 @param imageArray 图片数组
 */
- (void)setup:(NSArray *)titleArray imageArray:(NSArray *)imageArray{
    
    self.backgroundColor = [UIColor clearColor];
    if ([titleArray[0] isEqualToString:@"美颜"]) {
        
        self.contentView = [[UIView alloc]initWithFrame:CGRectMake(0, 78, ScreenWidth, self.frame.size.height - 78)];
        [self addSubview:self.contentView];
        [self.contentView addVisualEffect];
        self.toolView = [[AliyunToolView alloc] initWithItems:titleArray imageArray:imageArray frame:CGRectMake(0, 0, ScreenWidth, 45)];
        self.toolView.delegate = self;
        [self.contentView addSubview:self.toolView];
        [self addSubview:self.beautyFaceView];
        self.frontView = self.beautyFaceView;
//        [self.contentView addSubview:self.filterView];
//        self.frontView = self.filterView;
        
        _dismissButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, 78)];
        _dismissButton.backgroundColor = [UIColor clearColor];
        [self addSubview:_dismissButton];
        [_dismissButton addTarget:self action:@selector(disMissSelf:) forControlEvents:UIControlEventTouchUpInside];
    }else if([titleArray[0] isEqualToString:@"人脸贴纸"]){
        [self addVisualEffect];
        self.toolView = [[AliyunToolView alloc] initWithItems:titleArray  imageArray:imageArray frame:CGRectMake(0, 0, ScreenWidth, 45)];
        self.toolView.delegate = self;
        [self addSubview:self.toolView];
        
        [self addSubview:self.gifCollectionView];
        self.frontView = self.gifCollectionView;
        [self.dbHelper openResourceDBSuccess:nil failure:nil];
    }
}

/**
 _dismissButton的点击时间
 
 @param button _dismissButton
 */
- (void)disMissSelf:(UIButton *)button{
    if (self.delegate && [self.delegate respondsToSelector:@selector(recordBeautyView:dismissButtonTouched:)]) {
        [self.delegate recordBeautyView:self dismissButtonTouched:button];
    }
}


- (void)setEffectItems:(NSArray *)effectItems
{
    _effectItems = effectItems;
    [_gifCollectionView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
}

- (void)AliyunToolView:(AliyunToolView *)toolView didClickedButton:(NSInteger)buttonTag{
    [self.frontView removeFromSuperview];
    if ([self.titleArray[0] isEqualToString:@"美颜"]) {
        if(buttonTag == 0){
            [self addSubview:self.beautyFaceView];
            self.frontView = self.beautyFaceView;
            //            [self bringSubviewToFront:self.dismissButton];
        }else if(buttonTag == 1){
            [self addSubview:self.beautySkinView];
            self.frontView = self.beautySkinView;
            //            [self bringSubviewToFront:self.dismissButton];
            
        }
    }else if([self.titleArray[0] isEqualToString:@"人脸贴纸"]){
        [self addSubview:self.gifCollectionView];
        self.frontView = self.gifCollectionView;
    }
    self.buttonTag = buttonTag;
    
}


- (UIView *)beautyFaceView {
    if (!_beautyFaceView) {
        //默认档位
        
        NSInteger level = [_beautyFaceDataManager_advanced getBeautyLevel];
        //可供微调的选择
        NSArray *dics = @[[_beautyFaceDataManager_advanced SkinPolishingDic],[_beautyFaceDataManager_advanced SkinWhiteningDic],[_beautyFaceDataManager_advanced SkinShiningDic]];
        
        self.beatyFaceSettingViewControl = [AlivcLiveBeautifySettingsViewController settingsViewControllerWithLevel:level detailItems:dics];
        
        //因为control没有展示在界面上，所有view手动设置frame
        self.beatyFaceSettingViewControl.view.frame = CGRectMake(0, 0, ScreenWidth, self.frame.size.height);
        
        //设置高低级美颜
        AlivcBeautySettingViewStyle style = [[NSUserDefaults standardUserDefaults] integerForKey:@"shortVideo_beautyType"];
        if (style == AlivcBeautySettingViewStyle_ShortVideo_BeautyFace_Base) {
            [self.beatyFaceSettingViewControl setUIStyle:AlivcBeautySettingViewStyle_ShortVideo_BeautyFace_Base];
            //设置档位
            NSInteger level = [self.beautyFaceDataManager_normal getBeautyLevel];
            [self.beatyFaceSettingViewControl updateLevel:level];
        }else{
            [self.beatyFaceSettingViewControl setUIStyle:AlivcBeautySettingViewStyle_ShortVideo_BeautyFace_Advanced];
            //设置档位
            NSInteger level = [self.beautyFaceDataManager_advanced getBeautyLevel];
            [self.beatyFaceSettingViewControl updateLevel:level];
        }
        
        self.beatyFaceSettingViewControl.delegate = self;
        for (NSInteger i = 0; i < 3; i ++) {
            __block AliyunRecordBeautyView *weakSelf = self;
            [self.beatyFaceSettingViewControl setAction:^{
                [weakSelf.toolView clickTithTag:i];
            } withTag:i];
        }
        
        _beautyFaceView = self.beatyFaceSettingViewControl.view;
        
    }
    return _beautyFaceView;
}


- (UIView *)beautySkinView {
    if (!_beautySkinView) {
        //默认档位
        NSInteger level = [_beautySkinDataManager getBeautyLevel];
        //可供微调的选择
        NSArray *dics = @[[_beautySkinDataManager EyeWideningDic],[_beautySkinDataManager FaceSlimmingDic]];
        self.beatySkinSettingViewControl = [AlivcLiveBeautifySettingsViewController settingsViewControllerWithLevel:level detailItems:dics];
        
        [self.beatySkinSettingViewControl setUIStyle:AlivcBeautySettingViewStyle_ShortVideo_BeautySkin];
        self.beatySkinSettingViewControl.delegate = self;
        for (NSInteger i = 0; i < 3; i ++) {
            __block AliyunRecordBeautyView *weakSelf = self;
            [self.beatySkinSettingViewControl setAction:^{
                [weakSelf.toolView clickTithTag:i];
            } withTag:i];
        }
        //因为control没有展示在界面上，所有view手动设置frame
        self.beatySkinSettingViewControl.view.frame = CGRectMake(0, 0, ScreenWidth, self.frame.size.height);
        
        _beautySkinView = self.beatySkinSettingViewControl.view;
    }
    return _beautySkinView;
}

- (UICollectionView *)gifCollectionView {
    if (!_gifCollectionView) {
        
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.sectionInset = UIEdgeInsetsMake(15, 22, 20, 22);
        flowLayout.minimumInteritemSpacing = 20;
        flowLayout.minimumLineSpacing = 20;
        _gifCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 45, ScreenWidth, 165) collectionViewLayout:flowLayout];
        _gifCollectionView.backgroundColor = [UIColor clearColor];
        _gifCollectionView.delegate = (id)self;
        _gifCollectionView.dataSource = (id)self;
//        [_gifCollectionView registerClass:[AliyunMagicCameraEffectCell class] forCellWithReuseIdentifier:@"AliyunMagicCameraEffectCell"];
    }
    return _gifCollectionView;
}

- (AliyunDBHelper *)dbHelper {
    
    if (!_dbHelper) {
        _dbHelper = [[AliyunDBHelper alloc] init];
    }
    return _dbHelper;
}

#pragma mark - AliyunEffectFilter2ViewDelegate
- (void)didSelectEffectFilter:(AliyunEffectFilterInfo *)filter {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectEffectFilter:)]) {
        [self.delegate didSelectEffectFilter:filter];
    }
    
}

#pragma mark - UICollectionViewDataSource && UICollectionViewDelegate -

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.effectItems.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //由于要更新下载进度 这里cell不复用了
    NSString *identifier = [_cellDic objectForKey:[NSString stringWithFormat:@"%@", indexPath]];
    // 如果取出的唯一标示符不存在，则初始化唯一标示符，并将其存入字典中，对应唯一标示符注册Cell
    if (identifier == nil) {
        identifier = [NSString stringWithFormat:@"AliyunMagicCameraEffectCell%@", [NSString stringWithFormat:@"%@", indexPath]];
        [_cellDic setValue:identifier forKey:[NSString stringWithFormat:@"%@", indexPath]];
        // 注册Cell
        [_gifCollectionView registerClass:[AliyunMagicCameraEffectCell class]  forCellWithReuseIdentifier:identifier];
    }
    AliyunMagicCameraEffectCell *effectCell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    NSLog(@"\n-----动图下载测试：%ld,%p-------\n",(long)indexPath.row,effectCell);
    AliyunPasterInfo *pasterInfo = [self.effectItems objectAtIndex:indexPath.row];
    
    if (pasterInfo.bundlePath != nil) {
        UIImage *iconImage = [UIImage imageWithContentsOfFile:pasterInfo.icon];
        [effectCell.imageView setImage:iconImage];
        [effectCell shouldDownload:NO];
        NSLog(@"动图下载测试刷新图片：bundlePath：%@",pasterInfo.bundlePath);
    } else {
        if ([pasterInfo fileExist] && pasterInfo.icon) {
            NSLog(@"动图下载测试刷新图片 存在：icon：%@ ",pasterInfo.icon);
            UIImage *iconImage = [UIImage imageWithContentsOfFile:pasterInfo.icon];
            if (!iconImage) {
                NSURL *url = [NSURL URLWithString:pasterInfo.icon];
                [effectCell.imageView sd_setImageWithURL:url];
                NSLog(@"动图下载测试url");
            } else {
                [effectCell.imageView setImage:iconImage];
                NSLog(@"动图下载测试iconImage");
            }
        } else {
            NSLog(@"动图下载测试刷新图片 不存在：icon：%@\n",pasterInfo.icon);
            NSURL *url = [NSURL URLWithString:pasterInfo.icon];
            [effectCell.imageView sd_setImageWithURL:url];
            
        }
        if (pasterInfo.icon == nil) {
            [effectCell shouldDownload:NO];
        } else {
            BOOL shouldDownload = ![pasterInfo fileExist];
            [effectCell shouldDownload:shouldDownload];
            NSLog(@"动图下载测试:下载按钮:%d",shouldDownload);
        }
    }
    if (indexPath.row == 0) {
        effectCell.imageView.contentMode = UIViewContentModeCenter;
        effectCell.imageView.backgroundColor = rgba(255, 255, 255, 0.2);
        effectCell.imageView.layer.cornerRadius = effectCell.imageView.frame.size.width/2;
        effectCell.imageView.layer.masksToBounds = YES;
        effectCell.imageView.image = [AlivcImage imageNamed:@"shortVideo_clear"];
        
    }else{
        effectCell.imageView.contentMode = UIViewContentModeScaleAspectFill;
        effectCell.imageView.backgroundColor = [UIColor clearColor];
        effectCell.imageView.layer.cornerRadius = 50/2;
        effectCell.imageView.layer.masksToBounds = YES;
    }
    if (indexPath.row == _selectGifIndex) {
        [effectCell setApplyed:YES];
        
        NSLog(@"动图下载测试选择效果设置为YES");
    }else{
        [effectCell setApplyed:NO];
        NSLog(@"动图下载测试选择效果设置为NO");
    } 
    return effectCell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    AliyunMagicCameraEffectCell *cell = (AliyunMagicCameraEffectCell *)[self.gifCollectionView cellForItemAtIndexPath:indexPath];
    if (cell.isLoading) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(focusItemIndex:cell:)]) {
            [self.delegate focusItemIndex:indexPath.row cell:cell];
        }
    });
}

#pragma mark - AlivcLiveBeautifySettingsViewControllerDelegate

- (void)settingsViewController:(AlivcLiveBeautifySettingsViewController *)viewController didChangeLevel:(NSInteger)level{
    //更新对应的选项
    if(viewController == self.beatyFaceSettingViewControl){
        //美颜
        switch (viewController.currentStyle) {
            case AlivcBeautySettingViewStyle_ShortVideo_BeautyFace_Advanced:
            {
                [_beautyFaceDataManager_advanced saveBeautyLevel:level];
                AlivcPushBeautyParams *params = [_beautyFaceDataManager_advanced getBeautyParamsOfLevel:level];
                //高级美颜
                NSLog(@"高级美颜改变档位:%d,美白:%d,磨皮：%d，红润：%d",(int)level,params.beautyWhite,params.beautyBuffing,params.beautyRuddy);
                NSLog(@"高级美颜短视频当前版本：%d",SDK_VERSION);
                [self.delegate didChangeAdvancedBeautyWhiteValue:params.beautyWhite];
                [self.delegate didChangeAdvancedBlurValue:params.beautyBuffing];
                [self.delegate didChangeAdvancedBuddy:params.beautyRuddy];
                //更新详细参数的界面
                NSArray *dics = @[[_beautyFaceDataManager_advanced SkinPolishingDic],[_beautyFaceDataManager_advanced SkinWhiteningDic],[_beautyFaceDataManager_advanced SkinShiningDic]];
                [viewController updateDetailItems:dics];
            }
                break;
            case AlivcBeautySettingViewStyle_ShortVideo_BeautyFace_Base:
            {
                //基础美颜
                [_beautyFaceDataManager_normal saveBeautyLevel:level];
                NSLog(@"基础美颜");
                [self.delegate didChangeBeautyValue:level];
            }
                break;
            default:
                break;
        }
        
    }else if (viewController == self.beatySkinSettingViewControl){
        //美肌
        NSLog(@"美肌");
        
        [_beautySkinDataManager saveBeautyLevel:level];
        AlivcPushBeautyParams *params = [_beautySkinDataManager getBeautyParamsOfLevel:level];
        [self.delegate didChangeAdvancedSlimFace:params.beautySlimFace];
        [self.delegate didChangeAdvancedBigEye:params.beautyBigEye];
        
        NSArray *dics = @[[_beautySkinDataManager EyeWideningDic],[_beautySkinDataManager FaceSlimmingDic]];
        [viewController updateDetailItems:dics];
    }
}

- (void)settingsViewController:(AlivcLiveBeautifySettingsViewController *)viewController didChangeValue:(NSDictionary *)info{
    
    //更新对应的选项
    if(viewController == self.beatyFaceSettingViewControl){
        //美颜
        switch (viewController.currentStyle) {
            case AlivcBeautySettingViewStyle_ShortVideo_BeautyFace_Advanced:
            {
                //高级美颜
                [_beautyFaceDataManager_advanced saveParamWithInfo:info];
                AlivcPushBeautyParams *params = [_beautyFaceDataManager_advanced getBeautyParamsOfLevel:[_beautyFaceDataManager_advanced getBeautyLevel]];
                [self.delegate didChangeAdvancedBeautyWhiteValue:params.beautyWhite];
                [self.delegate didChangeAdvancedBlurValue:params.beautyBuffing];
                [self.delegate didChangeAdvancedBuddy:params.beautyRuddy];
                NSLog(@"高级美颜改变值,美白:%d,磨皮：%d，红润：%d",params.beautyWhite,params.beautyBuffing,params.beautyRuddy);
                NSLog(@"高级美颜短视频当前版本：%d",SDK_VERSION);
                
            }
                break;
            case AlivcBeautySettingViewStyle_ShortVideo_BeautyFace_Base:
            {
                //基础美颜
                NSLog(@"基础美颜");
                NSAssert(false, @"基础美颜怎么会调用到这里来，请开发人员仔细看下原因");
                
            }
                break;
            default:
                break;
        }
        
    }else if (viewController == self.beatySkinSettingViewControl){
        //美肌
        NSLog(@"美肌");
        
        [_beautySkinDataManager saveParamWithInfo:info];
        AlivcPushBeautyParams *params = [_beautySkinDataManager getBeautyParamsOfLevel:[_beautySkinDataManager getBeautyLevel]];
        [self.delegate didChangeAdvancedSlimFace:params.beautySlimFace];
        [self.delegate didChangeAdvancedBigEye:params.beautyBigEye];
        
    }
    
}

- (void)settingsViewController:(AlivcLiveBeautifySettingsViewController *)viewController didChangeUIStyle:(AlivcBeautySettingViewStyle)uiStyle{
    NSInteger level = 0;
    switch (uiStyle) {
        case AlivcBeautySettingViewStyle_ShortVideo_BeautyFace_Base:
            NSLog(@"基础美颜");
            level = [_beautyFaceDataManager_normal getBeautyLevel];
            [self.delegate didChangeCommonMode];
            self.beautyType = AliyunBeautyTypeBase;
            break;
        case AlivcBeautySettingViewStyle_ShortVideo_BeautyFace_Advanced:
            level = [_beautyFaceDataManager_advanced getBeautyLevel];
            NSLog(@"高级美颜");
            [self.delegate didChangeAdvancedMode];
            self.beautyType = AliyunBeautyTypeAdvanced;
            break;
            
        default:
            break;
    }
    //更新ui
    [self.beatyFaceSettingViewControl updateLevel:level];
}

- (void)settingsViewControllerDidSelectHowToGet:(AlivcLiveBeautifySettingsViewController *)viewController{
    if (self.delegate && [self.delegate respondsToSelector:@selector(recordBeatutyViewDidSelectHowToGet:)]) {
        [self.delegate recordBeatutyViewDidSelectHowToGet:self];
    }
}


/**
 动图应用上去之后更新UI状态
 */
- (void)refreshUIWhenThePasterInfoApplyedWithIndex:(NSInteger)applyedIndex{
    NSInteger newIndex = applyedIndex;
    if (newIndex != _selectGifIndex) {
        AliyunMagicCameraEffectCell *cell = (AliyunMagicCameraEffectCell *)[self.gifCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_selectGifIndex inSection:0]];
        if (cell) {
            [cell setApplyed:NO];
        }else{
            //获取不到cell表明用户在下载过程中滑动到其他地方去了
            [self.gifCollectionView reloadData];
        }
        
        NSLog(@"\n动图下载测试把%ld选中设为NO %p\n",_selectGifIndex,cell);
    }
    if (newIndex < self.effectItems.count) {
        AliyunMagicCameraEffectCell *cell = (AliyunMagicCameraEffectCell *)[self.gifCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:newIndex inSection:0]];
        if (cell) {
            [cell setApplyed:YES];
            cell.downloadImageView.hidden = YES;
        }else{
            //获取不到cell表明用户在下载过程中滑动到其他地方去了
            [self.gifCollectionView reloadData];
        }
        _selectGifIndex = newIndex;
        NSLog(@"\n动图下载测试把%ld选中设为YES %p\n",_selectGifIndex,cell);
    }
}

/**
 根据新的动图数组刷新ui
 
 @param effectItems 新的动图数组
 */
- (void)refreshUIWithGifItems:(NSArray *)effectItems{
    self.effectItems = effectItems;
    [self.gifCollectionView reloadData];
}

- (NSMutableDictionary *)cellDic{
    if (!_cellDic) {
        _cellDic = @[].mutableCopy;
    }
    return _cellDic;
}
@end
