//
//  QUCompressManager.m
//  AliyunVideo
//
//  Created by Worthy on 2017/3/25.
//  Copyright (C) 2010-2017 Alibaba Group Holding Limited. All rights reserved.
//

#import "AliyunCompressManager.h"
#import <AliyunVideoSDKPro/AliyunCrop.h>
#import <AliyunVideoSDKPro/AliyunImageCrop.h>
#import "AVAsset+VideoInfo.h"
#import "MBProgressHUD+AlivcHelper.h"

@interface AliyunCompressManager ()


@property (nonatomic, strong) AliyunCrop *cutPanel;
@property (nonatomic, copy) void(^successCallback)(void);
@property (nonatomic, copy) void(^failureCallback)(int errorCode);
@end

@implementation AliyunCompressManager

- (instancetype)initWithMediaConfig:(AliyunMediaConfig *)config {
    self = [super init];
    if (self) {
        _config = config;
    }
    return self;
}

- (void)compressWithSourcePath:(NSString *)sourcePath
                    outputPath:(NSString *)outputPath
                    outputSize:(CGSize)outputSize
                       success:(void (^)(void))success
                       failure:(void(^)(int errorCode))failure {
    _successCallback = success;
    _failureCallback = failure;
    AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:sourcePath]];
    _cutPanel = [[AliyunCrop alloc] initWithDelegate:(id<AliyunCropDelegate>)self];
    _cutPanel.inputPath = sourcePath;
    _cutPanel.outputSize = outputSize;
    _cutPanel.outputPath = outputPath;
    _cutPanel.startTime = 0;
    _cutPanel.endTime = [asset avAssetVideoTrackDuration];
    _cutPanel.fps = _config.fps;
    _cutPanel.gop = 5;
    // cut mode
    //_cutPanel.cropMode = AliyunImageCropModeAspectCut;
    //_cutPanel.rect = CGRectMake(0, 0, outputSize.width, outputSize.height);
    
    // fill mode
    _cutPanel.cropMode = AliyunImageCropModeAspectFill;
    _cutPanel.rect = CGRectMake(0, 0, 1, 1);
    _cutPanel.videoQuality = AliyunVideoQualityVeryHight;
    if (_config.encodeMode == AliyunEncodeModeHardH264) {
        _cutPanel.encodeMode = 1;
    }else{
        _config.encodeMode = 0;
    }
    _cutPanel.shouldOptimize = NO;
    int res =[_cutPanel startCrop];
    if (res == -100002){
        [MBProgressHUD showWarningMessage:@"当前视频格式不支持" inView:[UIApplication sharedApplication].keyWindow];
    }else if (res == -100003){
        [MBProgressHUD showWarningMessage:@"当前音频格式不支持" inView:[UIApplication sharedApplication].keyWindow];
    }else if (res <0 && res != -314){
        [MBProgressHUD showWarningMessage:[NSString stringWithFormat:@"裁剪失败：%d",res] inView:[UIApplication sharedApplication].keyWindow];
        self.failureCallback(res);
    }
}

- (UIImage *)compressImageWithSourceImage:(UIImage *)sourceImage
                               outputSize:(CGSize)outputSize {
    if (sourceImage == nil) {
        return nil;
    }
    AliyunImageCrop *imageCrop = [[AliyunImageCrop alloc] init];
    imageCrop.originImage = sourceImage;
    imageCrop.cropMode = AliyunImageCropModeAspectFill;
    imageCrop.outputSize = outputSize;
    UIImage *generatedImage = [imageCrop generateImage];
    return generatedImage;
}

- (void)stopCompress {
    
    if (_cutPanel) {
        [_cutPanel cancel];
    }
}

#pragma mark - tool

- (CGSize)calOutputSizeWithAsset:(AVAsset *)asset {
    CGSize size = [asset avAssetNaturalSize];
    CGFloat factor = MAX(size.width, size.height)/1280.f;
    return CGSizeMake((int)(size.width/factor), (int)(size.height/factor));
}


#pragma mark --- AliyunCropDelegate

- (void)cropTaskOnProgress:(float)progress {

}

- (void)cropOnError:(int)error {
    self.failureCallback(error);
}

- (void)cropTaskOnComplete {
    self.successCallback();
    
}

@end
