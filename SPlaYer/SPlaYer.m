//
//  SPlaYer.m
//  SPlaYer
//
//  Created by wuwenhao on 2020/9/10.
//  Copyright © 2020 MOSI. All rights reserved.
//

#import "SPlaYer.h"
#import "QPlayHandler.h"
#import "MOSISYstemEx.h"

typedef NS_ENUM(NSInteger, SourceType) {
    SourceTypeQQ,
    SourceTypeHIMALAYA,
    SourceTypeM3U8,
};

@interface SPlaYer ()
@property (nonatomic , strong) MPlaYer *mPlayer;
@property (nonatomic , strong) QPlayHandler *qPlayHandler;
@end

@implementation SPlaYer
{
    SourceType _type;
}

- (id) init {
    self = [super init];
    if (self) {
        _mPlayer = [[MPlaYer alloc]init];
        _qPlayHandler = [[QPlayHandler alloc]init];
    }
    return self;
}

/// 播放
/// 支持的格式：
/// 1. URL -> (Himalaya + Radio)
/// 2. Media id （QQ）
- (void) play:(id)identifier {
    if ([identifier isKindOfClass:[NSURL class]]) {
        if ([(NSURL *)identifier isAvalidM3U8URL] || [(NSURL *)identifier isAvalidTsNetURL]) {
            _type = SourceTypeM3U8;
        }
        else {
            _type = SourceTypeHIMALAYA;
        }
        self.mPlayer.playerStatusCallback = self.playerStatusCallback;
        self.qPlayHandler.playerStatusCallback = nil;
        self.qPlayHandler.playerProgressCallback = nil;
        self.mPlayer.playerProgressCallback = self.playerProgressCallback;
    }
    else {
        _type = SourceTypeQQ;
        self.qPlayHandler.playerStatusCallback = self.playerStatusCallback;
        self.mPlayer.playerStatusCallback = nil;
        self.qPlayHandler.playerProgressCallback = self.playerProgressCallback;
        self.mPlayer.playerProgressCallback = nil;
    }
    
    if (_type == SourceTypeQQ) {
        [self.mPlayer pause];
        [self.qPlayHandler play:(NSString *)identifier];
    }
    else {
        [self.qPlayHandler pause];
        [self.mPlayer play:identifier];
    }
}
/// 恢复播放
- (void) resume {
    if (_type == SourceTypeQQ) {
        [self.mPlayer pause];
        [self.qPlayHandler resume];
    }
    else {
        [self.qPlayHandler pause];
        [self.mPlayer resume];
    }
}
/// 暂停
- (void) pause {
    if (_type == SourceTypeQQ) {
        [self.mPlayer pause];
        [self.qPlayHandler pause];
    }
    else {
        [self.qPlayHandler pause];
        [self.mPlayer pause];
    }
}
/// 停止
- (void) stop {
    if (_type == SourceTypeQQ) {
        [self.mPlayer pause];
        [self.qPlayHandler stop];
    }
    else {
        [self.qPlayHandler pause];
        [self.mPlayer stop];
    }
}

/// 当前只有 Himalaya 支持
- (void) seekTo:(float)progress{
    if (_type == SourceTypeHIMALAYA) {
        [self.mPlayer seekTo:progress];
    }
}

@end
