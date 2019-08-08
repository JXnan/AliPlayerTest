//
//  AlivcAudioEffectView.m
//  AliyunVideoClient_Entrance
//
//  Created by wanghao on 2019/3/4.
//  Copyright © 2019年 Alibaba. All rights reserved.
//

#import "AlivcAudioEffectView.h"
#import "UIView+AlivcHelper.h"
#import "AlivcEditBottomHeaderView.h"
//#import "AliyunEffectFilterCell.h"
#import "UIColor+AlivcHelper.h"
#import "AlivcAudioEffectCell.h"


#define AES_HeaderVew_Height    45  //顶部页眉View高度
#define AES_LineView_Height     1   //分割线高度


@interface AlivcAudioEffectView()
@property(nonatomic, strong)AlivcEditBottomHeaderView *headerView;    //顶部页眉View
@property(nonatomic, strong)UIView *contentView;   //中间内容View
@property(nonatomic, strong)UICollectionView *soundsCollectionView;
@property(nonatomic, strong) NSMutableArray *audiosArr;
@property (nonatomic, assign) NSInteger selectIndex;


@end

@implementation AlivcAudioEffectView

-(id)initWithFrame:(CGRect)frame{
    
    self = [super initWithFrame:frame];
    if (self) {
        self.audiosArr =[NSMutableArray arrayWithArray:[self configAudios]];
        [self setupSubviews];
    }
    return self;
}

-(void)setupSubviews{
    _selectIndex = 0;
    [self addVisualEffect];
    [self addSubview:self.headerView];
    [self addSubview:self.contentView];
}

- (NSArray *)configAudios
{
    
    AlivcAudioEffectModel *effctNone = [[AlivcAudioEffectModel alloc] init];
    effctNone.title = @"原生";
    effctNone.type = AlivcEffectSoundTypeClear;
    effctNone.iconPath = @"audioEffect_default_icon";
    
    AlivcAudioEffectModel *effctLolita = [[AlivcAudioEffectModel alloc] init];
    effctLolita.title = @"萝莉";
    effctLolita.type = AlivcEffectSoundTypeLolita;
    effctLolita.iconPath = @"audioEffect_lolita_icon";
    
    AlivcAudioEffectModel *effctUncle = [[AlivcAudioEffectModel alloc] init];
    effctUncle.title = @"大叔";
    effctUncle.type = AlivcEffectSoundTypeUncle;
    effctUncle.iconPath = @"audioEffect_uncle_icon";
    
    AlivcAudioEffectModel *effctEcho = [[AlivcAudioEffectModel alloc] init];
    effctEcho.title = @"回音";
    effctEcho.type = AlivcEffectSoundTypeEcho;
    effctEcho.iconPath = @"audioEffect_echo_icon";
    
    AlivcAudioEffectModel *effctRevert = [[AlivcAudioEffectModel alloc] init];
    effctRevert.title = @"KTV";
    effctRevert.type = AlivcEffectSoundTypeRevert;
    effctRevert.iconPath = @"audioEffect_ktv_icon";
    
    NSArray *audios = @[effctNone,effctLolita,effctUncle,effctEcho,effctRevert];
    
    return audios;
}

#pragma mark - GET
-(AlivcEditBottomHeaderView *)headerView{
    if (!_headerView) {
        _headerView = [[AlivcEditBottomHeaderView alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), AES_HeaderVew_Height)];
        _headerView.backgroundColor = [UIColor clearColor];
        [_headerView hiddenButton];
        [_headerView setTitle:@"音效" icon:[AlivcImage imageNamed:@"alivc_svEdit_audio"]];
    }
    return _headerView;
}

-(UIView *)contentView{
    if (!_contentView) {
        _contentView = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(self.headerView.frame), CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)- CGRectGetMaxY(self.headerView.frame))];
        [_contentView addSubview:self.soundsCollectionView];
    }
    return _contentView;
}

-(UICollectionView *)soundsCollectionView{
    if (!_soundsCollectionView) {
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.itemSize = CGSizeMake(50, 70);
        layout.sectionInset = UIEdgeInsetsMake(15, 22, 20, 22);
        layout.minimumInteritemSpacing = 20;
        layout.minimumLineSpacing = 20;
        
        _soundsCollectionView = [[UICollectionView alloc] initWithFrame:self.contentView.bounds collectionViewLayout:layout];
        _soundsCollectionView.backgroundColor =[UIColor clearColor];
        _soundsCollectionView.showsHorizontalScrollIndicator = NO;
        _soundsCollectionView.showsVerticalScrollIndicator = NO;
        _soundsCollectionView.delegate = (id)self;
        _soundsCollectionView.dataSource = (id)self;
        [_soundsCollectionView registerClass:[AlivcAudioEffectCell class] forCellWithReuseIdentifier:@"AlivcAudioEffectCellIdentifier"];
    }
    return _soundsCollectionView;
}

#pragma mark - UICollectionViewDelegate -

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    AlivcAudioEffectCell *effectCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AlivcAudioEffectCellIdentifier" forIndexPath:indexPath];
    [effectCell cellModel:_audiosArr[indexPath.row]];
    
    if (indexPath.row == _selectIndex) {
        [effectCell setSelected:YES];
    }else{
        [effectCell setSelected:NO];
    }
    return effectCell;
    
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.audiosArr.count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    AlivcAudioEffectCell *lastSelectCell = (AlivcAudioEffectCell *)[collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_selectIndex inSection:0]];
    [lastSelectCell setSelected:NO];
    
    AlivcAudioEffectModel *model = self.audiosArr[indexPath.row];
    if (self.delegate && [self.delegate respondsToSelector:@selector(AlivcAudioEffectViewDidSelectCell:)]) {
        [self.delegate AlivcAudioEffectViewDidSelectCell:model.type];
    }
}

@end
