//
//  ViewController.m
//  test
//
//  Created by edz on 2019/8/2.
//  Copyright © 2019 edz. All rights reserved.
//

#import "ViewController.h"
#import "ModelManage.h"
#import "Model.h"
#import <MJRefresh/MJRefresh.h>

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource, ModelManageDelegate>
@property(nonatomic, strong) ModelManage * manage;

@property(nonatomic, strong) UITableView * tab;

@property(nonatomic,copy) NSArray<Model *> * list;
@end

@implementation ViewController


- (ModelManage *)manage {
    if (_manage) {
        return _manage;
    }
    _manage = [ModelManage new];
    _manage.modelClass = [Model class];
    _manage.delegate = self;
    return _manage;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    CGRect react = [UIScreen mainScreen].bounds;
//    
//    self.tab = [[UITableView alloc] initWithFrame:react style:UITableViewStyleGrouped];
//    self.tab.backgroundColor = [UIColor yellowColor];
//    self.tab.delegate = self;
//    self.tab.dataSource = self;
//    __weak ViewController * weakSelf = self;
//    self.tab.mj_header = [MJRefreshGifHeader headerWithRefreshingBlock:^{
//        [weakSelf fetchData:NO];
//    }];
//    self.tab.mj_footer = [MJRefreshBackGifFooter footerWithRefreshingBlock:^{
//        [weakSelf fetchData:YES];
//    }];
//    
//    
//    [self.view addSubview:self.tab];
//    [self fetchData: NO];
}


- (void)fetchData:(BOOL)isMore {
    [self.manage fetchData:nil params:nil keyPath:@"data.user" isMore:isMore];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"123"];
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"123" forIndexPath:indexPath];
    Model * model = self.list[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@今年%ld岁了",model.name, model.age];
    
   
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.list.count;
}

- (void)reload:(NSArray *)dataList currentPage:(NSInteger)page hasMore:(BOOL)hasMore {
    self.list = dataList;
    [self.tab.mj_header endRefreshing];
    
    if(hasMore == NO) {
        [self.tab.mj_footer endRefreshingWithNoMoreData];
    }else {
        [self.tab.mj_footer endRefreshing];
    }
    [self.tab reloadData];
}


@end
