//
//  ModelManage.h
//  test
//
//  Created by edz on 2019/8/2.
//  Copyright © 2019 edz. All rights reserved.
//

#import <Foundation/Foundation.h>



NS_ASSUME_NONNULL_BEGIN

@protocol ModelManageDelegate <NSObject>

- (void)reload:(NSArray *)dataList currentPage:(NSInteger)page hasMore:(BOOL)hasMore;

@end

@interface ModelManage : NSObject

//模型类
@property(nonatomic, weak) Class modelClass;

@property(nonatomic, weak) id<ModelManageDelegate> delegate;

@property(nonatomic, assign) NSInteger pageCount;


// router = [@"data",@"user"]
- (void)fetchData:(NSString *)url params:(NSDictionary<NSString*, id> *)params keyPath:(NSString *)keyPath isMore:(BOOL)isMore;

@end

NS_ASSUME_NONNULL_END
