//
//  SPlaYer.h
//  SPlaYer
//
//  Created by iSmicro on 2020/9/10.
//  Copyright © 2020 iSmicro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MPlaYer/MPlaYer.h>

@interface SPlaYer : NSObject
/// 是否只是抓取 PCM
@property (nonatomic , assign) BOOL isJustFetchPCM;
/// PCM 数据独立回调
@property (nonatomic , copy) void (^pcmCallback)(AudioBuffer ioData);
/// 播放器状态回调
@property (nonatomic , copy) void (^playerStatusCallback)(MPlaYerStatus status);
/// 媒体信息回调
@property (nonatomic , copy) void (^mediaInfoCallback)(NSObject *mediaInfo);

/// 播放
/// 支持的格式：
/// 1. URL -> (Himalaya + Radio)
/// 2. Media id （QQ）
- (void) play:(id)identifier;
/// 恢复播放
- (void) resume;
/// 暂停
- (void) pause;
/// 停止
- (void) stop;

/// 当前只有 Himalaya 支持
- (void) seekTo:(NSTimeInterval)time;
@end
