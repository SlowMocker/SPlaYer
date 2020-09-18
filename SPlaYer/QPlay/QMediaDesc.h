//
//  QMediaDesc.h
//  SPlaYer
//
//  Created by wuwenhao on 2020/9/10.
//  Copyright © 2020 MOSI. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QMediaDesc : NSObject
// 子包大小
@property (nonatomic , assign) NSInteger length;
// 子包 index
@property (nonatomic , assign) NSInteger packageIndex;
// 有效 PCM 数据总长度
// 有些媒体文件最后会有静音插入，导致实际计算的大小大于 totalLength
@property (nonatomic , assign) NSInteger totalLength;
// 媒体文件的 ID
@property (nonatomic , copy) NSString *mediaId;

- (id) initWithDic:(NSDictionary *)dic;
@end

@interface QMediaRequestInfo : NSObject
// 媒体文件的 ID
@property (nonatomic , copy) NSString *mediaId;
@property (nonatomic , assign) NSInteger totalLength;
// 已经 request 数据总长度
@property (nonatomic , assign) NSInteger didRequestLength;
// 下个要请求的 index
@property (nonatomic , assign) NSInteger nextRequestIndex;
- (id) initWithDic:(NSDictionary *)dic;
@end

NS_ASSUME_NONNULL_END
