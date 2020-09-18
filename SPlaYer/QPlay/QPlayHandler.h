//
//  QPlayHandler.h
//  SPlaYer
//
//  Created by wuwenhao on 2020/9/10.
//  Copyright © 2020 MOSI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "MPlaYer.h"

NS_ASSUME_NONNULL_BEGIN

@interface QPlayHandler : NSObject
/// 是否只是抓取 PCM
@property (nonatomic , assign) BOOL isJustFetchPCM;
/// PCM 数据独立回调
@property (nonatomic , copy) void (^__nullable pcmCallback)(AudioBuffer ioData);
/// 播放器状态回调
@property (nonatomic , copy) void (^ __nullable playerStatusCallback)(MPlaYerStatus status);
/// 播放器进度回调
@property (nonatomic , copy) void (^ __nullable playerProgressCallback)(float progress);

/// 播放
- (void) play:(NSString *)mediaId;
/// 恢复播放
- (void) resume;
/// 暂停
- (void) pause;
/// 停止
- (void) stop;
@end

NS_ASSUME_NONNULL_END
