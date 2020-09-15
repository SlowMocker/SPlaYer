//
//  QPlayHandler.m
//  SPlaYer
//
//  Created by iSmicro on 2020/9/10.
//  Copyright © 2020 iSmicro. All rights reserved.
//

#import "QPlayHandler.h"
#import "QPlayAutoSDK.h"
#import "QPlayAutoManager.h"
#import "MPcmPlaYer.h"
#import "QMediaDesc.h"

@interface QPlayHandler ()
@property (nonatomic , strong) MPcmPlaYer *mPcmPlayer;
@property (nonatomic , assign) MPlaYerStatus status;

@property (nonatomic , strong) QMediaRequestInfo *requestInfo;
@property (nonatomic , strong) QMediaDesc *onePackageDesc;

/// 请求 PCM 队列
@property (nonatomic , strong) NSOperationQueue *requestQueue;
/// PCM 装载队列
@property (nonatomic , strong) NSOperationQueue *eBufferQueue;
/// 单数据已经请求结束
@property (nonatomic , assign) BOOL dataDidRequestFinish;
@end

@implementation QPlayHandler
{
    NSString *_srcId;
}

- (id) init {
    self = [super init];
    if (self) {
        
        // 队列初始化
        self.requestQueue = [[NSOperationQueue alloc]init];
        self.requestQueue.maxConcurrentOperationCount = 1;
        self.eBufferQueue = [[NSOperationQueue alloc]init];
        self.eBufferQueue.maxConcurrentOperationCount = 1;
        
        // 监听 buffer 回调
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveQueueBufferNullNoti:)
                                                     name:kNotificationShouldFillAudioQueueBuffer
                                                   object:nil];
    }
    return self;
}

- (void) receiveQueueBufferNullNoti:(NSNotification *)noti {
   
    __weak typeof(self) weakSelf = self;
    NSOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        __strong typeof(weakSelf) self = weakSelf;
        // 检查是否是最后一个包
        if (self.requestInfo.didRequestLength >= self.requestInfo.totalLength) {
            self.dataDidRequestFinish = YES;
            return;
        }
        self.dataDidRequestFinish = NO;
        
//        NSLog(@"*-*开始获取 index: %d", (int)self.requestInfo.nextRequestIndex);
        
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        [[QPlayAutoManager sharedInstance] requestPcmData:self.requestInfo.mediaId
                                             packageIndex:self.requestInfo.nextRequestIndex
                                                 callback:^(BOOL success, NSDictionary *dict) {
            if (success) {
                __strong typeof(weakSelf) self = weakSelf;
//                NSLog(@"*-*结束获取 index: %d", (int)self.requestInfo.nextRequestIndex);

                // 叠加计算已读数据量
                NSDictionary *desc = dict[@"descDic"];
                self.onePackageDesc = [[QMediaDesc alloc] initWithDic:desc];
                self.requestInfo.didRequestLength += self.onePackageDesc.length;
                
                NSData *pcmData = dict[@"pcmData"];
                
                //                __strong typeof(weakSelf) self = weakSelf;
                AudioBuffer buffer;
                buffer.mData = (short *)pcmData.bytes;
                buffer.mDataByteSize = (uint32_t)pcmData.length;
                buffer.mNumberChannels = self.mPcmPlayer.asbd.mChannelsPerFrame;
                
                [self.mPcmPlayer enqueueAudioBuffer:buffer];
                
                if (self.status == MPlaYerStatusLOADING) {
                    [self callbackStatus:MPlaYerStatusPLAYING];
                }
                
                self.requestInfo.nextRequestIndex ++;
            }
            
            dispatch_semaphore_signal(sema);
        }];
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }];
    
    op.name = [NSString stringWithFormat:@"PCMRequestNO_%d",(int)self.requestInfo.nextRequestIndex];
    [self.requestQueue addOperation:op];
}

/// 播放
- (void) play:(NSString *)mediaId {
    [self callbackStatus:MPlaYerStatusLOADING];
    
    self.dataDidRequestFinish = NO;
    
    
    
    // 重置 pcm player
    if (self.mPcmPlayer) {
        // stop 方法调用后会立即阻断 notification 的发送【BBB】
        [self.mPcmPlayer stop];
        [self.mPcmPlayer releaseGC];
        self.mPcmPlayer = nil;
    }
    
    // 重置队列
    self.requestQueue.suspended = YES;
    // 取消了所有尚未执行的 op【AAA】
    [self.requestQueue cancelAllOperations];
    
    // 这里只需要确保上一个 mediaId 的最后一次 PCM 请求在 op 之前就可以
    // 将 mediaInfo 的请求也放入了 requestQueue，保证了 MediaInfo 和 PCM 的请求始终串行
    // 问题：一旦上一个 mediaId 的最后一次 PCM 请求在 mediaInfo 之后，那么播放当前 mediaId 的 PCM 之前会穿插播放一次上个 mediaId 的 buffer
    // 【BBB】先中断了 notification 的发送
    // 【AAA】取消了所有尚未执行的 PCM 任务，所以此时的任务（可能存在正在执行的上一个 mediaId 的 PCM 任务）只会在 op 之前
    // 在 [self.mPcmPlayer prepareToPlay:[self asbdFromQDic:dict]]; 会重启通知的发送能力，但是 [self.mPcmPlayer stop]; 可能会延时触发通知（待确认）
    // 如果一旦延时触发通知，则有可能在通知恢复后接收到上一个 mediaId 的通知
    NSOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        __weak typeof(self) weakSelf = self;
        [[QPlayAutoManager sharedInstance] requestMediaInfo:mediaId callback:^(BOOL success, NSDictionary *dict) {
            if (success) {
                __strong typeof(weakSelf) self = weakSelf;
                
                self.requestInfo = [[QMediaRequestInfo alloc] initWithDic:dict];
                self.onePackageDesc = nil;
                
                self.mPcmPlayer = [[MPcmPlaYer alloc]init];
                self.pcmCallback = self.mPcmPlayer.pcmCallback;
                self.mPcmPlayer.allBufferNullCallback = ^{
                    __strong typeof(weakSelf) self = weakSelf;
                    if (self.dataDidRequestFinish) {
                        [self callbackStatus:MPlaYerStatusEND];
                    }
                };
                [self.mPcmPlayer prepareToPlay:[self asbdFromQDic:dict]];
                [self.mPcmPlayer play];
            }
            dispatch_semaphore_signal(sema);
        }];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }];
    self.requestQueue.suspended = NO;
    [self.requestQueue addOperation:op];
    
    // 并发去请求 MediaInfo 和 PCM，造成了 requestID 的混乱（mediaInfo requestID 是 10 ，返回的resultID 却是 11，无法找到正确的回调），最好单个单个请求
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        __weak typeof(self) weakSelf = self;
//        [[QPlayAutoManager sharedInstance] requestMediaInfo:mediaId callback:^(BOOL success, NSDictionary *dict) {
//            if (success) {
//                __strong typeof(weakSelf) self = weakSelf;
//
//                self.requestInfo = [[QMediaRequestInfo alloc] initWithDic:dict];
//                self.onePackageDesc = nil;
//
//                self.mPcmPlayer = [[MPcmPlaYer alloc]init];
//                self.pcmCallback = self.mPcmPlayer.pcmCallback;
//                [self.mPcmPlayer prepareToPlay:[self asbdFromQDic:dict]];
//                [self.mPcmPlayer play];
//            }
//        }];
//    });
    
}
/// 恢复播放
- (void) resume {
    if (self.status == MPlaYerStatusPAUSE) {
        [self callbackStatus:MPlaYerStatusPLAYING];
    }
    [self.mPcmPlayer resume];
}
/// 暂停
- (void) pause {
    if (self.status == MPlaYerStatusPLAYING) {
        [self callbackStatus:MPlaYerStatusPAUSE];
    }
    [self.mPcmPlayer pause];
}
/// 停止
- (void) stop {
    if (self.status != MPlaYerStatusSTOP) {
        [self callbackStatus:MPlaYerStatusSTOP];
    }
    [self.mPcmPlayer stop];
}

- (void) setIsJustFetchPCM:(BOOL)isJustFetchPCM {
    _isJustFetchPCM = isJustFetchPCM;
    self.mPcmPlayer.isJustFetchPCM = _isJustFetchPCM;
}

#pragma mark - private methods
// 设置并回调状态
- (void) callbackStatus:(MPlaYerStatus)status {
    self.status = status;
    if (self.playerStatusCallback) {
        self.playerStatusCallback(self.status);
    }
}

/*
 {
     Bit = 16;
     Channel = 2;
     PCMDataLength = 36912228;
     Rate = 44100;
     SongID = "511571|1";
 }
 */

- (AudioStreamBasicDescription) asbdFromQDic:(NSDictionary *)dic {
    AudioStreamBasicDescription asbd;
    memset(&asbd, 0, sizeof(asbd));
    asbd.mSampleRate = ((NSNumber *)dic[@"Rate"]).floatValue;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    asbd.mChannelsPerFrame = ((NSNumber *)dic[@"Channel"]).intValue;
    asbd.mFramesPerPacket = 1;
    asbd.mBitsPerChannel = ((NSNumber *)dic[@"Bit"]).intValue;
    asbd.mBytesPerFrame = (asbd.mBitsPerChannel / 8) * asbd.mChannelsPerFrame;
    asbd.mBytesPerPacket = asbd.mBytesPerFrame * asbd.mFramesPerPacket;
    return asbd;
}
@end
