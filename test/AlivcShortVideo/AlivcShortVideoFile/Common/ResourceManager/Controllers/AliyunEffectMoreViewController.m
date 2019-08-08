//
//  AliyunEffectMoreViewController.h.m
//  AliyunVideo
//
//  Created by TripleL on 17/3/3.
//  Copyright (C) 2010-2017 Alibaba Group Holding Limited. All rights reserved.
//

#import "AliyunEffectMoreViewController.h"
#import "AliyunEffectMoreView.h"
#import "AliyunEffectMoreTableViewCell.h"
#import "AliyunDBHelper.h"
#import "AliyunEffectManagerViewController.h"
#import "AliyunResourceRequestManager.h"
#import "AliyunResourceDownloadManager.h"
#import "AliyunEffectModelTransManager.h"
#import "AliyunEffectInfo.h"
#import "AliyunResourceFontRequest.h"
#import "AliyunEffectMorePreviewCell.h"
#import "MBProgressHUD+AlivcHelper.h"
#import "AlivcDefine.h"
#import "AFNetworking.h"


@interface AliyunEffectMoreViewController () <AliyunEffectMoreViewDelegate, UITableViewDataSource, UITableViewDelegate, AliyunEffectMoreTableViewCellDelegate, AliyunEffectMorePreviewCellDelegate, AliyunEffectManagerViewControllerDelegate>

@property (nonatomic, strong) AliyunEffectMoreView *effectMoreView;

@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, strong) AliyunDBHelper *dbHelper;

@property (nonatomic, assign) AliyunEffectType effectType;

@property (nonatomic, strong) NSIndexPath *selectIndexPath;

@property (nonatomic, assign) BOOL netReconnect;//网络是否重新连接

@end

@implementation AliyunEffectMoreViewController

- (void)loadView {
    
    self.effectMoreView = [[AliyunEffectMoreView alloc] initWithFrame: [[UIScreen mainScreen] bounds]];
    self.effectMoreView.delegate = self;
    [self.effectMoreView setTableViewDelegates:self];
    self.view = self.effectMoreView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    [self.effectMoreView setTitleWithEffectType:self.effectType];
    [self.dbHelper openResourceDBSuccess:nil failure:nil];
    [self fetchListData];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resourceDeleteNoti:) name:AliyunEffectResourceDeleteNotification object:nil];
    __weak typeof(self)weakSelf = self;
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusNotReachable:
                weakSelf.netReconnect = YES;
                NSLog(@"断网，数据需要重载");
                break;
            default:
                break;
        }
    }];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
}
-(void)changReconnectState{
    _netReconnect = YES;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (_netReconnect) {
        [self fetchListData];
    }
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self stopPreviewLastCell];
    self.selectIndexPath = nil;
    [self.effectMoreView.tableView reloadData];
}
//资源删除通知
- (void)resourceDeleteNoti:(NSNotification *)noti {
    AliyunEffectResourceModel *model = noti.userInfo[@"deleteModel"];
    [self deleteResourceWithModel:model];
}


- (BOOL)prefersStatusBarHidden {
    
    return YES;
}
// 支持设备自动旋转
- (BOOL)shouldAutorotate
{
    return YES;
}

-(void)dealloc{
    NSLog(@"moreViewController dealloc!");
    [self.dbHelper closeDB];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:nil];
}

// 支持竖屏显示
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

- (instancetype)initWithEffectType:(AliyunEffectType)type {
    self = [super init];
    if (self) {
        _effectType = type;
    }
    return self;
}

#pragma mark - Data
- (void)fetchListData {

    [self.dataArray removeAllObjects];
    switch (self.effectType) {
        case AliyunEffectTypeFont:
            
            break;
        case AliyunEffectTypePaster:
            [self pasterCategoryList];
            break;
        case AliyunEffectTypeMV:
            [self MVList];
            break;
        case AliyunEffectTypeFilter:
            
            break;
        case AliyunEffectTypeMusic:
            
            break;
        case AliyunEffectTypeCaption:
            [self captionList];
            break;
        case AliyunEffectTypeSpecialFilter:
            
            break;
        default:
            break;
    }
    
}
- (void)captionList {
    __weak __typeof (self)weakSelf = self;
    [AliyunResourceRequestManager fetchCaptionListWithSuccess:^(NSArray *resourceListArray) {
        [weakSelf dealWithData:resourceListArray];
    } failure:^(NSString *errorStr) {
        NSLog(@"资源列表请求失败:%@", errorStr);
    }];
}
- (void)pasterCategoryList {
    __weak __typeof (self)weakSelf = self;
    [AliyunResourceRequestManager fetchPasterCategoryWithType:kPasterCategoryBack success:^(NSArray *resourceListArray) {
        [weakSelf dealWithData:resourceListArray];
    } failure:^(NSString *errorStr) {
        NSLog(@"资源列表请求失败:%@", errorStr);
    }];
}


- (void)MVList {
    __weak __typeof (self)weakSelf = self;
    [AliyunResourceRequestManager fetchMVListSuccess:^(NSArray *resourceListArray) {
        [weakSelf dealWithData:resourceListArray];
    } failure:^(NSString *errorStr) {
        NSLog(@"资源列表请求失败:%@", errorStr);
    }];
}

- (void)dealWithData:(NSArray *)resourceListArray{
    for (NSDictionary *resourceDic in resourceListArray) {
        AliyunEffectResourceModel *model = [[AliyunEffectResourceModel alloc] initWithDictionary:resourceDic error:nil];
        [model setValue:@(self.effectType) forKey:@"effectType"];
        BOOL isContain = [self.dbHelper queryOneResourseWithEffectResourceModel:model];
        [model setValue:@(isContain) forKey:@"isDBContain"];
        
        if (isContain) {
            // 已经下载了的 放在最上面
            [self.dataArray insertObject:model atIndex:0];
        } else {
            [self.dataArray addObject:model];
        }
    };
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.effectMoreView.tableView reloadData];
    });
}

#pragma mark - AliyunEffectManagerViewControllerDelegate
- (void)deleteResourceWithModel:(AliyunEffectResourceModel *)model {
    //AliyunEffectResourceModel *resourceModel in self.dataArray
    for (int i=0; i<self.dataArray.count; i++){
        AliyunEffectResourceModel *resourceModel = self.dataArray[i];
        if (resourceModel.eid == model.eid) {
            NSInteger index = [self.dataArray indexOfObject:resourceModel];
            AliyunEffectMoreTableViewCell *cell = [self.effectMoreView.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
            [cell setButtontType:(EffectTableViewButtonDownload)];
            resourceModel.isDBContain = NO;
            self.dataArray[index] = resourceModel;
        }
    }
    
}

#pragma mark - AliyunEffectManagerViewDelegate
- (void)onClickBackButton {

    [self.dbHelper closeDB];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onClickNextButton {
    
    AliyunEffectManagerViewController *managerVC = [[AliyunEffectManagerViewController alloc] initWithManagerType:self.effectType];
    managerVC.delegate = self;
    [self.navigationController pushViewController:managerVC animated:YES];
}


#pragma mark - TableViewdelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    AliyunEffectResourceModel *model = self.dataArray[indexPath.row];
    
    if ([indexPath isEqual:self.selectIndexPath]) {
        AliyunEffectMorePreviewCell *cell = [tableView dequeueReusableCellWithIdentifier:EffectMorePreviewTableViewIndentifier forIndexPath:indexPath];
        cell.delegate= self;
        [cell setEffectModel:model];
        return cell;
    } else {
        NSString *cellIdentifier = [NSString stringWithFormat:@"%@%ld", EffectMoreTableViewIndentifier, indexPath.row];
        AliyunEffectMoreTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[AliyunEffectMoreTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        [cell setEffectResourceModel:model];
        cell.delegate = self;
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([indexPath isEqual:self.selectIndexPath]) {
        return SizeHeight(300);
    }
    return SizeHeight(74);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self stopPreviewLastCell];
    
    NSMutableArray *indePaths = [NSMutableArray array];
    if (self.selectIndexPath) {
        [indePaths addObject:self.selectIndexPath];
    }
    if (![self.selectIndexPath isEqual:indexPath]) {
        [indePaths addObject:indexPath];
    }
    
    self.selectIndexPath = indexPath;
    
    [tableView reloadRowsAtIndexPaths:indePaths withRowAnimation:(UITableViewRowAnimationFade)];
    
}


#pragma mark - EffectMoreTableViewCellDelegate
- (void)onClickFuncButtonWithCell:(AliyunEffectMoreTableViewCell *)cell {
    NSLog(@"click download/use button");
    NSIndexPath *indexPath = [self.effectMoreView.tableView indexPathForCell:cell];
    AliyunEffectResourceModel *model = self.dataArray[indexPath.row];
    if (cell.buttontType == EffectTableViewButtonDownload) {
        cell.funcButton.userInteractionEnabled = NO;
        switch (self.effectType) {
            case AliyunEffectTypeFont:
                
                break;
            case AliyunEffectTypePaster:
                [self pasterListWithModel:model cell:cell indexPath:indexPath];
                break;
            case AliyunEffectTypeMV:
                [self dealWithResourceList:nil model:model cell:cell indexPath:indexPath];
                break;
            case AliyunEffectTypeFilter:
                
                break;
            case AliyunEffectTypeMusic:
                
                break;
            case AliyunEffectTypeCaption:
                [self textPasterListWithModel:model cell:cell indexPath:indexPath];
                break;
            case AliyunEffectTypeSpecialFilter:
                
                break;
            default:
                break;
        }
    } else {
        // 使用该资源
        [self closeWithEffectModel:model];
    }
}


- (void)textPasterListWithModel:(AliyunEffectResourceModel *)model
                           cell:(AliyunEffectMoreTableViewCell *)cell
                      indexPath:(NSIndexPath *)indexPath{
    __weak typeof(self)weakSelf = self;
    //请求资源下载地址
    [AliyunResourceRequestManager fetchTextPasterListWithTextPasterCategoryId:model.eid success:^(NSArray<AliyunEffectPasterInfo> *resourceListArray) {
        [weakSelf dealWithResourceList:resourceListArray
                                 model:model
                                  cell:cell
                             indexPath:indexPath];
    } failure:^(NSString *errorStr) {
        NSLog(@"%@",errorStr);
    }];
}

- (void)pasterListWithModel:(AliyunEffectResourceModel *)model
                       cell:(AliyunEffectMoreTableViewCell *)cell
                  indexPath:(NSIndexPath *)indexPath{
    __weak typeof(self)weakSelf = self;
    //请求资源下载地址
    [AliyunResourceRequestManager fetchPasterListWithType:kPasterCategoryBack pasterCategoryId:model.eid success:^(NSArray<AliyunEffectPasterInfo> *resourceListArray) {
        
        [weakSelf dealWithResourceList:resourceListArray
                                 model:model
                                  cell:cell
                             indexPath:indexPath];
        
    } failure:^(NSString *errorStr) {
        NSLog(@"%@",errorStr);
    }];
}

//下载资源
- (void)dealWithResourceList:(NSArray<AliyunEffectPasterInfo> *)resourceListArray
                       model:(AliyunEffectResourceModel *)model
                        cell:(AliyunEffectMoreTableViewCell *)cell
                   indexPath:(NSIndexPath *)indexPath
{
    if (resourceListArray) {
        model.pasterList = resourceListArray;
    }
    //下载
    AliyunResourceDownloadTask *task = [[AliyunResourceDownloadTask alloc] initWithModel:model];
    AliyunResourceDownloadManager *manager = [[AliyunResourceDownloadManager alloc] init];
    [manager addDownloadTask:task progress:^(CGFloat progress) {
        
        [cell updateDownlaodProgress:progress];
        
    } completionHandler:^(AliyunEffectResourceModel *newModel, NSError *error) {
        
        if (error) {
            [MBProgressHUD showMessage:@"网络不给力" inView:self.view];
            [cell updateDownloadFaliure];
        } else {
            
            self.dataArray[indexPath.row] = newModel;
            [self.dbHelper insertDataWithEffectResourceModel:newModel];
            if (self.effectMoreCallback) {
                self.effectMoreCallback(nil);
            }
        }
    }];
}


#pragma mark - AliyunEffectMorePreviewViewDelegate
- (void)onClickPreviewCell:(AliyunEffectMorePreviewCell *)cell {
    
    //    NSIndexPath *indexPath = [self.effectMoreView.tableView indexPathForCell:cell];
    NSArray *indexPaths = @[self.selectIndexPath];
    self.selectIndexPath = nil;
    [self.effectMoreView.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:(UITableViewRowAnimationFade)];
}


#pragma mark - UI
- (void)closeWithEffectModel:(AliyunEffectResourceModel *)model {
    [self.dbHelper closeDB];
    AliyunEffectInfo *infoModel = [[AliyunEffectModelTransManager manager] transEffectInfoModelWithResourceModel:model];
    
    if (self.effectMoreCallback) {
        self.effectMoreCallback(infoModel);
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)stopPreviewLastCell {
    
    AliyunEffectMorePreviewCell *lastCell = [self.effectMoreView.tableView cellForRowAtIndexPath:self.selectIndexPath];
    if (lastCell) {
        [lastCell stopPreview];
    }
}


#pragma mark - Setter
- (NSMutableArray *)dataArray {
    
    if (!_dataArray) {
        _dataArray = [[NSMutableArray alloc] init];
    }
    return _dataArray;
}

- (AliyunDBHelper *)dbHelper {
    
    if (!_dbHelper) {
        _dbHelper = [[AliyunDBHelper alloc] init];
    }
    return _dbHelper;
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
