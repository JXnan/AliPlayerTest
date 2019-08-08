//
//  AlivcShortVideoLivePlayViewController.m
//  AliyunVideoClient_Entrance
//
//  Created by wn Mac on 2019/5/14.
//  Copyright © 2019 Alibaba. All rights reserved.
//
#import <AliyunPlayer/AliyunPlayer.h>
#import "AlivcShortVideoLivePlayViewController.h"
#import "AlivcShortVideoCoverCell.h"
#import "AlivcShortVideoPlayerManager.h"
#import "MBProgressHUD+AlivcHelper.h"
#import "AliyunReachability.h"
#import "AlivcDefine.h"
#import "AliVideoClientUser.h"
#import "AlivcQuVideoServerManager.h"
#import "AliyunMediaConfig.h"
#import "AlivcShortVideoPlayCollectionViewDataSource.h"
#import "MJRefresh.h"
#import "AliyunPage.h"
#import "AliVideoClientUser.h"
#import "AlivcQuUserManager.h"
#import "NSData+AlivcHelper.h"
#import "AlivcShortVideoLiveVideoModel.h"

#define downloadPath NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject


typedef NS_ENUM(NSUInteger,AlivcPlayerControllerState) {
    AlivcPlayerControllerStateActive =  0,                  //正常状态
    AlivcPlayerControllerStateShowMask = 1 << 0,            //显示maskView
    AlivcPlayerControllerStateEnterbackground = 1 << 1      //进入后台
};



@interface AlivcShortVideoLivePlayViewController ()<AVPDelegate,UICollectionViewDelegate>
@property (nonatomic, strong) AlivcShortVideoPlayerManager *playerManager;

/**
 网络监听
 */
@property (nonatomic, strong) AliyunReachability *reachability;

/**
 初始化视频列表
 */
@property (nonatomic, strong) NSArray *defaultVideoList;

/**
 开始播放的位置
 */
@property (nonatomic, assign) NSInteger startPlayIndex;

/**
 控制器状态
 */
@property (nonatomic, assign) AlivcPlayerControllerState controllerState;

/**
 返回前台的时候 是否需要继续播放
 */
@property (nonatomic, assign) BOOL shouldResumeWhenActive;



@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) AlivcShortVideoPlayCollectionViewDataSource *collectionViewDataSource;
/**
 分页对象
 */
@property (nonatomic, strong) AliyunPage *page;
@property (nonatomic, copy) NSString *lastVid;

/**
 sts相关
 */
@property (nonatomic, copy) NSString *accessKeyId;
@property (nonatomic, copy) NSString *accessKeySecret;
@property (nonatomic, copy) NSString *securityToken;
@property (nonatomic, copy) NSString *region;

@property (nonatomic, assign) BOOL isLoading;
/**
 正在显示的indexPath
 */
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, assign) BOOL loadFinish;

@end

static NSString *CELLID = @"AlivcShortVideoCoverCell";

@implementation AlivcShortVideoLivePlayViewController


#pragma mark - lifeCycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [self initUI];
    [self initMaskViews];
    [self addNetWorkingNotification];
    [self loadData];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
    [self becomeActive];
    [self addNotification];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resignActive];
    [self removeObserver];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)dealloc
{
    [self.playerManager.listPlayer destroy];
    [self removeAllNotification];
    NSLog(@"%s",__func__);
}

#pragma mark - private methods

#pragma mark - UI
- (void)initUI{
    [self initCollectionView];
    self.playerManager = [[AlivcShortVideoPlayerManager alloc] initWithVC:self];
}

- (void)initCollectionView {
    if (@available(iOS 11.0, *)) {
        self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    [self.view addSubview:self.collectionView];
    self.collectionView.scrollsToTop = NO;
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self.collectionViewDataSource;
    
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    layout.itemSize = self.view.bounds.size;
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    
    self.collectionView.pagingEnabled = YES;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    [self.collectionView registerNib:[UINib nibWithNibName:CELLID bundle:nil
                                      ] forCellWithReuseIdentifier:  CELLID];
    //播放自己的视频不需要下拉刷新
 
        MJRefreshNormalHeader *refreshHeader = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadData)];
        refreshHeader.lastUpdatedTimeLabel.hidden =  YES;
        refreshHeader.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        self.collectionView.mj_header = refreshHeader;

}


- (void)initMaskViews {
   // if (self.navigationController.viewControllers.firstObject != self.tabBarController) {
        //返回按钮
        UIButton *backButton = [[UIButton alloc]init];
        [backButton addTarget:self action:@selector(backButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
        [backButton setImage:[AlivcImage imageNamed:@"avcBackIcon"] forState:UIControlStateNormal];
        [backButton sizeToFit];
        backButton.center = CGPointMake(15 + backButton.frame.size.width / 2, SafeTop + 22);
        [self.view addSubview:backButton];
    
        
   // }
    
    
}
- (void)addNotification {

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(becomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged)
                                                 name:AliyunPVReachabilityChangedNotification
                                               object:nil];
}


- (void)addNetWorkingNotification {
    self.reachability = [AliyunReachability reachabilityForInternetConnection];
    [self.reachability startNotifier];
    [self reachabilityChanged];
}

- (void)removeObserver {

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}
- (void)removeAllNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - NETWORK
- (void)loadData {
    __weak typeof(self) weakSelf = self;
    NSString *token = [AliVideoClientUser shared].token;
    if (!token) {
        [self randomUserCompletion:^{
            [weakSelf fetchSTSCompletion:^(NSString * _Nonnull accessKeyId, NSString * _Nonnull accessKeySecret, NSString * _Nonnull securityToken, NSString * _Nullable errString) {
                [weakSelf loadNewVideo];
            }];
        }];
    } else {
        //获取数据
//        [self fetchSTSCompletion:^(NSString * _Nonnull accessKeyId, NSString * _Nonnull accessKeySecret, NSString * _Nonnull securityToken, NSString * _Nullable errString) {
//            [weakSelf loadNewVideo];
//        }];
        [self loadNewVideo];
    }
    

}

//刷新数据
- (void)loadNewVideo {
    NSString *token = [AliVideoClientUser shared].token;
    self.page.currentPageNo = 1;
    self.loadFinish = NO;
    self.lastVid = @"";
    [self fetchVideo:token];
    
}
//获取更多数据
- (void)loadMoreVideo {
    [self.page next];
    //if ([self.page hasMore]) {
        NSString *token = [AliVideoClientUser shared].token;
        if (!token) {
            [MBProgressHUD showMessage:@"请先登录" inView:self.view];
            return;
        }
       
        self.lastVid = self.collectionViewDataSource.videoList.lastObject.ID;
        [self fetchVideo:token];

}

// 获取用户数据
- (void)randomUserCompletion:(void(^)(void))completion{
    NSData *localUserData = [[NSUserDefaults standardUserDefaults]objectForKey:AlivcUserLocalPath];
    if (localUserData)
    {
        AliVideoClientUser *localUser = (AliVideoClientUser *)[NSData
                                                               customInstanceFromData:localUserData
                                                               forClassType:[AliVideoClientUser class]];
        [[AliVideoClientUser shared] setLocalUser:localUser];
        if(completion) {
            completion();
        }
    } else {
        __weak typeof(self) weakSelf = self;
        [AlivcQuUserManager randomAUserSuccess:^{
            NSData *data = [NSData dataWithObject:[AliVideoClientUser shared]];
            [[NSUserDefaults standardUserDefaults]setObject:data forKey:AlivcUserLocalPath];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [[NSNotificationCenter defaultCenter] postNotificationName:AlivcNotificationRandomUserSuccess object:nil];
            if(completion) {
                completion();
            }
        } failure:^(NSString * _Nonnull errDes) {
            [MBProgressHUD showMessage:errDes inView:weakSelf.view];
            [weakSelf.collectionView.mj_header endRefreshing];
        }];
    }
}

- (void)fetchSTSCompletion:(void (^)(NSString * _Nonnull, NSString * _Nonnull, NSString * _Nonnull, NSString * _Nullable))completion{
    __weak typeof(self) weakSelf = self;
    NSString *token = [AliVideoClientUser shared].token;
    [AlivcQuVideoServerManager quServerGetSTSWithToken:token
                                               success:^(NSString * _Nonnull accessKeyId,
                                                         NSString * _Nonnull accessKeySecret,
                                                         NSString * _Nonnull securityToken) {
                                                   weakSelf.accessKeyId = accessKeyId;
                                                   weakSelf.accessKeySecret = accessKeySecret;
                                                   weakSelf.securityToken = securityToken;
                                                   weakSelf.region = @"cn-shanghai";
                                                   if (completion) {
                                                       completion(accessKeyId,accessKeySecret,securityToken,nil);
                                                   }
                                               } failure:^(NSString * _Nonnull errorString) {
                                                   [MBProgressHUD showMessage:errorString inView:weakSelf.view];
                                                   completion(@"",@"",@"",errorString);
                                                   [weakSelf.collectionView.mj_header endRefreshing];
                                               }];
}


- (void)fetchVideo:(NSString *)token {
    __weak typeof(self) weakSelf = self;
    self.isLoading = YES;
   
//    [AlivcQuVideoServerManager quServerGetRecommendVideoListWithToken:token
//                                                            pageIndex:self.page.currentPageNo
//                                                             pageSize:self.page.pageSize  lastEndVideoId:self.lastVid
//                                                              success:^(NSArray<AlivcQuVideoModel *> * _Nonnull videoList,
//                                                                        NSInteger allVideoCount) {
//
//                                                                  [weakSelf dealWithData:videoList countNum:allVideoCount lastVideoId:weakSelf.lastVid];
//
//                                                              } failure:^(NSString * _Nonnull errorString) {
//                                                                  weakSelf.isLoading = NO;
//                                                                  [MBProgressHUD showMessage:errorString inView:weakSelf.view];
//                                                                  [weakSelf.collectionView.mj_header endRefreshing];
//                                                              }];
//
    
    [AlivcQuVideoServerManager getRecommendLiveListWithToken:token pageIndex:self.page.currentPageNo pageSize:self.page.pageSize success:^(NSArray<AlivcShortVideoLiveVideoModel *> * _Nonnull videoList, NSInteger totalCount) {
        
      [weakSelf dealWithData:videoList countNum:totalCount lastVideoId:weakSelf.lastVid];
        
    } failure:^(NSString * _Nonnull errorString) {
        [MBProgressHUD showMessage:errorString inView:weakSelf.view];
        [weakSelf.collectionView.mj_header endRefreshing];
    }];
    
    
}


- (void)dealWithData:(NSArray<AlivcShortVideoLiveVideoModel *> *) videoList countNum:(NSInteger) allVideoCount lastVideoId:(NSString *)lastVid {
    if (videoList.count<10) {
        self.loadFinish = YES;
    }
    
    self.isLoading = NO;
    self.page.totalRecords = allVideoCount;
    [self.collectionView.mj_header endRefreshing];
    if (lastVid == nil || lastVid.length == 0) {
        self.collectionViewDataSource.videoList = videoList.mutableCopy;
        
        [self fetchedNewVideos:videoList];
        self.collectionView.contentInset = UIEdgeInsetsZero;
        [self moveToIndex:0];
        
    }else{
        NSMutableArray *indexPaths = @[].mutableCopy;
        for (int i = 0; i < videoList.count; i++) {
            NSInteger index = self.collectionViewDataSource.videoList.count - 1 + i;
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0] ;
            [indexPaths addObject:indexPath];
        }
        [self.collectionViewDataSource.videoList addObjectsFromArray:videoList];
        [self fetchedMoreVideos:videoList];
        
        [self.collectionView performBatchUpdates:^{
            [self.collectionView insertItemsAtIndexPaths:indexPaths];
        } completion:^(BOOL finished) {
        }];
    }
}

#pragma mark - player function
- (void)fetchedNewVideos:(NSArray<AlivcShortVideoLiveVideoModel *> *)videos {
    [self.playerManager stop];
    [self.playerManager clear];
    [self.playerManager updateAccessId:self.accessKeyId accessKeySecret:self.accessKeySecret securityToken:self.securityToken region:self.region];
    [self.playerManager addPlayList:videos];
}

- (void)fetchedMoreVideos:(NSArray<AlivcShortVideoLiveVideoModel *> *)videos {
    [self.playerManager updateAccessId:self.accessKeyId accessKeySecret:self.accessKeySecret securityToken:self.securityToken region:self.region];
    [self.playerManager addPlayList:videos];
}


- (void)showAtIndex:(NSInteger)index cell:(AlivcShortVideoCoverCell *)cell {
    //如果是当前视频 return
    if (self.playerManager.currentIndex == index ) {
        return;
    }
    if(cell) {
        [self.playerManager removePlayView];
        [cell addPlayer:self.playerManager.listPlayer];
        [self.playerManager playAtIndex:index];
    }
}

- (void)endDisplayingCell:(AlivcShortVideoCoverCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == self.playerManager.currentIndex) {
//        [self.playerManager removePlayView];
//        [self.playerManager pause];
    }
}
- (void)didClickPlayerAtIndex:(NSInteger)index {
    switch (self.playerManager.playerStatus) {
        case AVPStatusStarted:
            [self.playerManager pause];
            break;
        case AVPStatusPaused:
            [self.playerManager resume];
            break;
        case AVPStatusPrepared:
            [self.playerManager resume];
            break;
        default:
            break;
    }
}
//移除一个视频
- (void)removePlayItem:(NSInteger)index{
    [self.collectionViewDataSource  removeVideoAtIndex:index];
    [self.playerManager removeVideoAtIndex:index];
    NSInteger count =  self.collectionViewDataSource.videoList.count;
    if (count) {
        if (index <= count -1) {
            [self moveToIndex:index];
        }else {
            //移动到最后一个
            [self moveToIndex:count -1];
        }
    }else {
        [self.playerManager stop];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

//试图移动到哪个位置
- (void)moveToIndex:(NSInteger)index {
    [self.collectionView reloadData];
    [self.collectionView layoutIfNeeded];
    if (self.collectionViewDataSource.videoList.count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
            [self.collectionView performBatchUpdates:^{
                [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
            } completion:^(BOOL finished) {
                [self scrollViewDidEndDecelerating:self.collectionView];
                
            }];
        });
    }
}


#pragma mark - Delegates
#pragma mark - CollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self didClickPlayerAtIndex:indexPath.item];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.loadFinish == YES) {
        return;
    }
    
    //如果还剩最后三个并且不在加载中
    if(indexPath.item >= (self.collectionViewDataSource.videoList.count - 3.0) && !self.isLoading) {
        self.indexPath = indexPath;
        [self loadMoreVideo];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [self endDisplayingCell:(AlivcShortVideoCoverCell *)cell forItemAtIndexPath:indexPath];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSInteger index = self.collectionView.contentOffset.y / ScreenHeight;
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    AlivcShortVideoCoverCell *cell = (AlivcShortVideoCoverCell *)
    [self.collectionView cellForItemAtIndexPath:indexPath];
    [self showAtIndex:index cell:cell];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    AliyunPVNetworkStatus status = [self.reachability currentReachabilityStatus];
    if (status == AliyunPVNetworkStatusNotReachable) {
        [MBProgressHUD showMessage:@"网络不给力" inView:self.view];
        return;
    }
    
    if (scrollView.contentOffset.y + scrollView.bounds.size.height > scrollView.contentSize.height + 20 && self.collectionViewDataSource.videoList.count > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD showMessage:@"已经是最后一个视频了" inView:self.view];
        });
    }
}

#pragma mark - Actions

- (void)becomeActive {
    self.controllerState = self.controllerState & AlivcPlayerControllerStateShowMask;
    if (self.shouldResumeWhenActive) {
        [self.playerManager resume];
    }
    NSIndexPath *firstIndexPath = [[self.collectionView indexPathsForVisibleItems] firstObject];
    if (self.playerManager.currentIndex != firstIndexPath.item && self.playerManager.currentIndex >= 0) {
        
        [self.collectionView setContentOffset:[self.collectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForRow:self.playerManager.currentIndex inSection:0]].frame.origin animated:NO];
        
    }
}

- (void)resignActive {
    self.controllerState = self.controllerState | AlivcPlayerControllerStateEnterbackground;
    if(self.playerManager.playerStatus == AVPStatusStarted) {
        self.shouldResumeWhenActive = YES;
    }else {
        self.shouldResumeWhenActive = NO;
    }
    [self.playerManager pause];
    
}


- (void)backButtonTouched:(UIButton *)sender {
    [self.playerManager stop];
    [self.playerManager clear];
    [self.navigationController popViewControllerAnimated:YES];
}


//网络状态判定
- (void)reachabilityChanged{
    AliyunPVNetworkStatus status = [self.reachability currentReachabilityStatus];
    switch (status) {
        case AliyunPVNetworkStatusNotReachable://由播放器底层判断是否有网络
            [MBProgressHUD showMessage:@"请检查网络连接!" inView:self.view];
            break;
        case AliyunPVNetworkStatusReachableViaWiFi:
            
            break;
        case AliyunPVNetworkStatusReachableViaWWAN:
        {
            [MBProgressHUD showMessage:@"当前为4G网络,请注意流量消耗!" inView:self.view];
            
        }
            break;
        default:
            break;
    }
    //如果列表没有数据 并且 刚连上网络 需要刷新数据
    if (self.collectionViewDataSource.videoList.count == 0 && status != AliyunPVNetworkStatusNotReachable) {
        [self loadData];
    }
}




- (void)setControllerState:(AlivcPlayerControllerState)controllerState {
    _controllerState = controllerState;
    self.playerManager.canPlay = !controllerState;
}

- (UICollectionView *)collectionView{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    }
    return _collectionView;
}

- (AlivcShortVideoPlayCollectionViewDataSource *)collectionViewDataSource {
    if (!_collectionViewDataSource) {
        __weak typeof(self) weakSelf = self;
        _collectionViewDataSource = [[AlivcShortVideoPlayCollectionViewDataSource alloc] initWithCellID:CELLID cellConfig:^(AlivcShortVideoCoverCell * _Nullable cell, NSIndexPath * _Nullable indexPath) {
            cell.model = [weakSelf.collectionViewDataSource videoModelWithIndexPath:indexPath];
        }];
    }
    return _collectionViewDataSource;
}
- (AliyunPage *)page {
    if (!_page) {
        _page = [[AliyunPage alloc] init];
        _page.pageSize = 10;
    }
    return _page;
}

@end
