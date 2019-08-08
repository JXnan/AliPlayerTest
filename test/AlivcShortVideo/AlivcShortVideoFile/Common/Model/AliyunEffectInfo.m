//
//  AliyunEffectInfo.m
//  AliyunVideo
//
//  Created by dangshuai on 17/3/11.
//  Copyright (C) 2010-2017 Alibaba Group Holding Limited. All rights reserved.
//

#import "AliyunEffectInfo.h"
#import "AliyunEffectResourceModel.h"

@implementation AliyunEffectInfo

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (NSString *)localFilterIconPath {
    return nil;
}

- (NSString *)localFilterResourcePath {
    return nil;
}

- (NSString *)filterTypeName{
    NSString *typeName = @"";
    switch (_filterType) {
        case AliyunFilterTypNone:
            typeName = @"";
            break;
        case AliyunFilterTypeFace:
            typeName = @"人物类";
            break;
        case AliyunFilterTypeFood:
            typeName = @"食物类";
            break;
        case AliyunFilterTypeScenery:
            typeName = @"风景类";
            break;
        case AliyunFilterTypePet:
            typeName = @"宠物类";
            break;
        case AliyunFilterTypeSpecialStyle:
            typeName = @"特殊风格类";
            break;
        default:
            break;
    }
    return typeName;
}


@end
