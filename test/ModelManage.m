//
//  ModelManage.m
//  test
//
//  Created by edz on 2019/8/2.
//  Copyright © 2019 edz. All rights reserved.
//

#import "ModelManage.h"
#import <MJExtension/MJExtension.h>
#import "Model.h"

@interface ModelManage ()

@property(nonatomic, strong) NSMutableArray * list;

@property(nonatomic, assign) NSInteger page;



@end

@implementation ModelManage

- (instancetype)init
{
    self = [super init];
    if (self) {
        _page = 0;
        _list = [NSMutableArray array];
    }
    return self;
}

// 假数据
- (NSDictionary *)getDataWithPage:(NSInteger)page {
    NSArray * tmpArray = @[@0,@1,@2,@3,@4,@5,@6,@7,@8,@9];
    
    if (page > 5) {
        tmpArray = @[@0,@1,@2,@3,@4,@5,@6];
    }

    NSMutableArray<NSString *> * mArr = [NSMutableArray new];
    for (NSNumber * num in tmpArray) {
        Model * model = [Model new];
        model.age = [num integerValue] + page * 10;
        model.name = [NSString stringWithFormat:@"王%ld花",(long)model.age];
        [mArr addObject:[model mj_JSONString]];
    }
    NSDictionary * dic = @{
                           @"code":@"200",
                           @"data":@{@"user":[mArr copy]},
                           @"msg":@"请求成功"
                           };
    return dic;
}


// 模拟请求
- (void)fetchData:(NSString *)url params:(NSDictionary<NSString* ,id> *)params keyPath:(NSString *)keyPath isMore:(BOOL)isMore {
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSInteger page = isMore ? self.page + 1 : 0;
        
        NSDictionary * result = [self getDataWithPage:page];
        NSArray * array = [self.modelClass mj_objectArrayWithKeyValuesArray:[result valueForKeyPath:keyPath]];
        if(isMore) {
            
            [self.list addObjectsFromArray:array];
        }else {
            self.list = [array mutableCopy];
        }
        self.page = page;
        
        if ([self.delegate respondsToSelector:@selector(reload:currentPage:hasMore:)]) {
            [self.delegate reload:[self.list copy] currentPage:page hasMore:([array count] == 10)];
        }
    });
}
@end
