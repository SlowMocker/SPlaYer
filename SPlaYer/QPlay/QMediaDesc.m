//
//  QMediaDesc.m
//  SPlaYer
//
//  Created by iSmicro on 2020/9/10.
//  Copyright © 2020 iSmicro. All rights reserved.
//

#import "QMediaDesc.h"

@implementation QMediaDesc

//{
//    descDic =     {
//        Length = 512000;
//        PackageIndex = 13;
//        SongID = "511571|1";
//        TotalLength = 36912228;
//    };
//    pcmData = {length = 512000, bytes = 0x28058f04 1d0b530a 690e880d 090f770e ... a5f4bbe2 46ec3cde };
//}

- (id) initWithDic:(NSDictionary *)dic {
    self = [super init];
    if (self) {
        [self setValuesForKeysWithDictionary:dic];
    }
    return self;
}

- (void) setValue:(id)value forUndefinedKey:(NSString *)key {
    if ([@"Length" isEqualToString:key]) self.length = ((NSNumber *)value).integerValue;
    if ([@"PackageIndex" isEqualToString:key]) self.packageIndex = ((NSNumber *)value).integerValue;
    if ([@"TotalLength" isEqualToString:key]) self.totalLength = ((NSNumber *)value).integerValue;
    if ([@"SongID" isEqualToString:key]) self.mediaId = value;
}
@end

@implementation QMediaRequestInfo
- (id) initWithDic:(NSDictionary *)dic {
    self = [super init];
    if (self) {
        self.didRequestLength = 0;
        self.nextRequestIndex = 0;
        [self setValuesForKeysWithDictionary:dic];
    }
    return self;
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
- (void) setValue:(id)value forUndefinedKey:(NSString *)key {
    if ([@"PCMDataLength" isEqualToString:key]) self.totalLength = ((NSNumber *)value).integerValue;
    if ([@"SongID" isEqualToString:key]) self.mediaId = value;
}
@end
