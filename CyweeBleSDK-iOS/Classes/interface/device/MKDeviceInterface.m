//
//  MKDeviceInterface.m
//  MKFitpoloDevice
//
//  Created by aa on 2018/12/14.
//  Copyright © 2018 MK. All rights reserved.
//

#import "MKDeviceInterface.h"
#import "mk_fitpoloDefines.h"
#import "mk_fitpoloCentralManager.h"
#import "MKDeviceInterfaceAdopter.h"
#import "mk_fitpoloAdopter.h"
#import "CBPeripheral+mk_fitpolo701.h"
#import "CBPeripheral+mk_fitpoloCurrent.h"

#define connectedPeripheral (currentCentral.connectedPeripheral)
#define currentCentral ([mk_fitpoloCentralManager sharedInstance])
@interface MKDeviceInterface()

@property (nonatomic,strong) NSString *str;


@end

@implementation MKDeviceInterface

#pragma mark - 功能类型

// 获取电量 0x03
+ (void)getBatteryWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                   failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    [self addReadTaskWithTaskID:mk_getBattery
                       resetNum:NO
                  commandString:@"ff0602030100ffff"
                       sucBlock:^(id returnData) {
        NSString *content= returnData[@"result"][@"result"];
        if (!mk_validStr(content)) {
            content = @"";
            NSDictionary *dic = @{
                @"msg":@"success",
                @"code":@"2",
                @"result":@"",
            };
            if (sucBlock) {
                sucBlock(dic);
            }
            return;
        }
        NSLog(@"获取电量%@",content);
        NSString *value = [content substringWithRange:NSMakeRange(10, 2)];
        unsigned int battery = strtoul([value UTF8String], NULL, 16);
        NSLog(@"获取电量%d",battery);
        NSDictionary *dic = @{
                              @"msg":@"success",
                              @"code":@"1",
                              @"result":@(battery),
                              };
        if (sucBlock) {
            sucBlock(dic);
        }
    }
                      failBlock:failedBlock];
}
// 查找手表 0x04
+ (void)searchDeviceWithsucBlock:(NSString *)action
                        sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                     failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    
    NSArray *strings = @[@"ff06020401", action, @"ffff"];
    NSString *commandString = [strings componentsJoinedByString:@""];
    [self addReadTaskWithTaskID:mk_findDevice
                         resetNum:NO
                  commandString:commandString
                         sucBlock:^(id returnData) {
        NSString *content= returnData[@"result"][@"result"];
        if (!mk_validStr(content)) {
            content = @"";
            NSDictionary *dic = @{
                @"msg":@"success",
                @"code":@"2",
                @"result":@"",
            };
            if (sucBlock) {
                sucBlock(dic);
            }
            return;
        }
        NSString *value = [content substringWithRange:NSMakeRange(10, 2)];
        NSLog(@"查找手表状态%@",value);
        NSDictionary *dic = @{
                              @"msg":@"success",
                              @"code":@"1",
                              @"result":value,
                              };
        if (sucBlock) {
            sucBlock(dic);
        }
    }
                      failBlock:failedBlock];
}
// 解绑手表 0x06
+ (void)unbindDeviceWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                     failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    [self addReadTaskWithTaskID:mk_unbindDevice
                         resetNum:NO
                    commandString:@"ff0602060101ffff"
                         sucBlock:^(id returnData) {
        NSString *content= returnData[@"result"][@"result"];
        if (!mk_validStr(content)) {
            content = @"";
            NSDictionary *dic = @{
                @"msg":@"success",
                @"code":@"2",
                @"result":@"",
            };
            if (sucBlock) {
                sucBlock(dic);
            }
            return;
        }
        NSString *value = [content substringWithRange:NSMakeRange(10, 2)];
        NSLog(@"解绑手表状态%@",value);
        NSDictionary *dic = @{
                              @"msg":@"success",
                              @"code":@"1",
                              @"result":value,
                              };
        if (sucBlock) {
            sucBlock(dic);
        }
    }
                        failBlock:failedBlock];
}
// 运动控制 0x0c
+ (void)motionControlWithsucBlock:(id <MKMotionControlProtocol>)protocol
                         sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                     failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    NSMutableArray<NSNumber *> *dataList = [NSMutableArray array];
    [dataList addObject:@((Byte)(protocol.type & 0xFF))];
    [dataList addObject:@((Byte)(protocol.action & 0xFF))];
    NSUInteger dataLength = dataList.count;

    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(5 + dataLength)];
    [byteList addObject:@(mk_function)];
    [byteList addObject:@(0x0c)]; //orderType
    [byteList addObject:@(dataLength)];
    [byteList addObjectsFromArray:dataList];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0xFF)];
    // 转换为字节数组
    NSMutableData *dataBytes = [NSMutableData dataWithCapacity:byteList.count];
    for (NSNumber *num in byteList) {
    Byte byteValue = [num unsignedCharValue];
    [dataBytes appendBytes:&byteValue length:sizeof(Byte)];
    }
    NSString *commandString = [mk_fitpoloAdopter hexStringFromData:dataBytes];
    [self addReadTaskWithTaskID:mk_motionControl
                         resetNum:NO
                    commandString:commandString
                         sucBlock:^(id returnData) {
        NSString *content= returnData[@"result"][@"result"];
        if (!mk_validStr(content)) {
            content = @"";
            NSDictionary *dic = @{
                @"msg":@"success",
                @"code":@"2",
                @"result":@"",
            };
            if (sucBlock) {
                sucBlock(dic);
            }
            return;
        }
        NSString *value = [content substringWithRange:NSMakeRange(10, 2)];
        NSLog(@"运动控制状态%@",value);
        NSDictionary *dic = @{
                              @"msg":@"success",
                              @"code":@"1",
                              @"result":value,
                              };
        if (sucBlock) {
            sucBlock(dic);
        }
    }
                        failBlock:failedBlock];
}
// 语言支持 0x07
+ (void)getLanguageSupportWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                           failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0x04)];
    [byteList addObject:@(mk_function)];
    [byteList addObject:@(0x07)]; //orderType
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0xFF)];
    // 转换为字节数组
    NSMutableData *dataBytes = [NSMutableData dataWithCapacity:byteList.count];
    for (NSNumber *num in byteList) {
        Byte byteValue = [num unsignedCharValue];
        [dataBytes appendBytes:&byteValue length:sizeof(Byte)];
    }
    NSString *commandString = [mk_fitpoloAdopter hexStringFromData:dataBytes];

    [self addReadTaskWithTaskID:mk_getLanguageSupport
                         resetNum:NO
                    commandString:commandString
                         sucBlock:^(id returnData) {
        NSData *content = [mk_fitpoloAdopter stringToData:returnData[@"result"][@"result"]];
        if ([content length] == 0) {
            content = @"";
            NSDictionary *dic = @{
                @"msg":@"success",
                @"code":@"2",
                @"result":@"",
            };
            if (sucBlock) {
                sucBlock(dic);
            }
            return;
        }
        const uint8_t *bytes = content.bytes;
        int dataLength = (int)bytes[4];
        NSData *data = [content subdataWithRange:NSMakeRange(5, dataLength)];
        const uint8_t *dataBytes = [data bytes];// 获取数据的字节指针
        
        NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:32];
        for (int i = 0; i < data.length * 8; i++) {
            int byteIndex = i / 8;
            int bitIndex = 7 - (i % 8); // 从高位开始取位
            uint8_t bit = (dataBytes[byteIndex] >> bitIndex) & 1;
            NSInteger value = (NSInteger)bit;
            [resultArray addObject:@(value)];
        }
//        NSLog(@"resultArray===: %@", resultArray);
        NSDictionary *dic = @{
                              @"msg":@"success",
                              @"code":@"1",
                              @"result":resultArray,
                              };
        if (sucBlock) {
            sucBlock(dic);
        }
    }
                        failBlock:failedBlock];
}

// 设备信息 0x08
+ (void)getDeviceInfoWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                           failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0x04)];
    [byteList addObject:@(mk_function)];
    [byteList addObject:@(0x08)]; //orderType
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0xFF)];
    // 转换为字节数组
    NSMutableData *dataBytes = [NSMutableData dataWithCapacity:byteList.count];
    for (NSNumber *num in byteList) {
        Byte byteValue = [num unsignedCharValue];
        [dataBytes appendBytes:&byteValue length:sizeof(Byte)];
    }
    NSString *commandString = [mk_fitpoloAdopter hexStringFromData:dataBytes];

    [self addReadTaskWithTaskID:mk_getLanguageSupport
                         resetNum:NO
                    commandString:commandString
                         sucBlock:^(id returnData) {
        NSData *content = [mk_fitpoloAdopter stringToData:returnData[@"result"][@"result"]];
        if ([content length] == 0) {
            content = @"";
            NSDictionary *dic = @{
                @"msg":@"success",
                @"code":@"2",
                @"result":@"",
            };
            if (sucBlock) {
                sucBlock(dic);
            }
            return;
        }
        NSLog(@"设备信息content===: %@", content);
        const uint8_t *bytes = content.bytes;
        int dataLength = (int)bytes[4];
        NSData *data = [content subdataWithRange:NSMakeRange(5, dataLength)];
        NSDictionary *dataDic;
        @try {
            dataDic = [mk_fitpoloAdopter turnArrDic:data];
            NSLog(@"设备信息dataDic===: %@", dataDic);
            NSDictionary *dic = @{
                                  @"msg":@"success",
                                  @"code":@"1",
                                  @"result":dataDic,
                                  };
            if (sucBlock) {
                sucBlock(dic);
            }
        } @catch (NSException *exception) {
            dataDic = @{};
            NSLog(@"获取设备信息失败");
            NSDictionary *dic = @{
                                  @"msg":@"success",
                                  @"code":@"2",
                                  @"result":dataDic,
                                  };
            if (sucBlock) {
                sucBlock(dic);
            }
        }
    }
                        failBlock:failedBlock];
}
// 时间校准 0x01
+ (void)timeAlignWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                  failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    NSDate *currentDate = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitWeekday) fromDate:currentDate];
    NSInteger year = components.year % 2000;
    NSInteger month = components.month;
    NSInteger day = components.day;
    NSInteger hour = components.hour;
    NSInteger minute = components.minute;
    NSInteger second = components.second;
    NSInteger weekday = components.weekday;
    NSLog(@"当前日期和时间: %ld年%ld月%ld日 %ld时%ld分%ld秒", (long)year, (long)month, (long)day, (long)hour, (long)minute, (long)second);
    
    NSMutableArray<NSNumber *> *dataList = [NSMutableArray array];
    [dataList addObject:@((Byte)(year & 0xFF))];
    [dataList addObject:@((Byte)(month & 0xFF))];
    [dataList addObject:@((Byte)(day & 0xFF))];
    [dataList addObject:@((Byte)(hour & 0xFF))];
    [dataList addObject:@((Byte)(minute & 0xFF))];
    [dataList addObject:@((Byte)(second & 0xFF))];
    [dataList addObject:@((Byte)(weekday & 0xFF))];
    NSUInteger dataLength = dataList.count;
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(5 + dataLength)];
    [byteList addObject:@(mk_function)];
    [byteList addObject:@(0x01)]; //orderType
    [byteList addObject:@(dataLength)];
    [byteList addObjectsFromArray:dataList];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0xFF)];
    // 转换为字节数组
    NSMutableData *dataBytes = [NSMutableData dataWithCapacity:byteList.count];
    for (NSNumber *num in byteList) {
        Byte byteValue = [num unsignedCharValue];
        [dataBytes appendBytes:&byteValue length:sizeof(Byte)];
    }
    NSString *commandString = [mk_fitpoloAdopter hexStringFromData:dataBytes];

    [self addReadTaskWithTaskID:mk_timeAlign
                         resetNum:NO
                    commandString:commandString
                         sucBlock:^(id returnData) {
        NSString *content= returnData[@"result"][@"result"];
        if (!mk_validStr(content)) {
            content = @"";
            NSDictionary *dic = @{
                @"msg":@"success",
                @"code":@"2",
                @"result":@"",
            };
            if (sucBlock) {
                sucBlock(dic);
            }
            return;
        }
        NSLog(@"时间校准状态content===%@",content);
        NSString *value = [content substringWithRange:NSMakeRange(11, 1)];
        NSLog(@"时间校准状态%@",value);
        NSDictionary *dic = @{
                              @"msg":@"success",
                              @"code":@"1",
                              @"result":value,
                              };
            if (sucBlock) {
                sucBlock(dic);
            }
    }
                        failBlock:failedBlock];
}
// 消息通知 0x0a
+ (void)messageNotifyWithsucBlock:(id <MKMessageNotifyProtocol>)protocol
                         sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                      failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    
    NSMutableArray<NSNumber *> *dataList = [NSMutableArray array];
    [dataList addObject:@((Byte)(protocol.appType & 0xFF))];
    [dataList addObject:@((Byte)(protocol.year & 0xFF))];
    [dataList addObject:@((Byte)(protocol.month & 0xFF))];
    [dataList addObject:@((Byte)(protocol.day & 0xFF))];
    [dataList addObject:@((Byte)(protocol.hour & 0xFF))];
    [dataList addObject:@((Byte)(protocol.minute & 0xFF))];
    [dataList addObject:@((Byte)(protocol.second & 0xFF))];
    
    //标题
    NSLog(@"消息通知标题1=%d",protocol.title.length);
    NSString * titleHexString = [mk_fitpoloAdopter hexStringFromString:protocol.title];
    NSLog(@"消息通知标题2=%@",titleHexString);
    NSLog(@"消息通知标题3=%d",titleHexString.length);
    NSMutableArray<NSNumber *> *titleList = [NSMutableArray array];
    if (titleHexString.length > (19*2)) {
        titleList = [mk_fitpoloAdopter limitArrayFromHexString:titleHexString limit:19];
    } else {
        titleList = [mk_fitpoloAdopter arrayFromHexString:titleHexString];
    }
    [dataList addObject:@((Byte)(titleList.count & 0xFF))];
    [dataList addObjectsFromArray:titleList];
    //内容
    NSLog(@"消息通知内容1=%d",protocol.content.length);
    NSString * contentHexString = [mk_fitpoloAdopter hexStringFromString:protocol.content];
    NSLog(@"消息通知内容2=%@",contentHexString);
    NSLog(@"消息通知内容3=%d",contentHexString.length);
    NSMutableArray<NSNumber *> *contentList = [NSMutableArray array];
    if (contentHexString.length > (190*2)) {
        contentList = [mk_fitpoloAdopter limitArrayFromHexString:contentHexString limit:190];
    } else {
        contentList = [mk_fitpoloAdopter arrayFromHexString:contentHexString];
    }
    [dataList addObject:@((Byte)(contentList.count & 0xFF))];
    [dataList addObjectsFromArray:contentList];
    
    NSUInteger dataLength = dataList.count;
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(5 + dataLength)];
    [byteList addObject:@(mk_function)];
    [byteList addObject:@(0x0a)]; //orderType
    [byteList addObject:@(dataLength)];
    [byteList addObjectsFromArray:dataList];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0xFF)];
    // 转换为字节数组
    NSMutableData *dataBytes = [NSMutableData dataWithCapacity:byteList.count];
    for (NSNumber *num in byteList) {
        Byte byteValue = [num unsignedCharValue];
        [dataBytes appendBytes:&byteValue length:sizeof(Byte)];
    }
    NSString *commandString = [mk_fitpoloAdopter hexStringFromData:dataBytes];

    [self addReadTaskWithTaskID:mk_messageNotify
                         resetNum:NO
                    commandString:commandString
                         sucBlock:^(id returnData) {
        NSString *content= returnData[@"result"][@"result"];
        if (!mk_validStr(content)) {
            content = @"";
            NSDictionary *dic = @{
                @"msg":@"success",
                @"code":@"2",
                @"result":@"",
            };
            if (sucBlock) {
                sucBlock(dic);
            }
            return;
        }
        NSLog(@"消息通知状态content===%@",content);
        NSString *value = [content substringWithRange:NSMakeRange(11, 1)];
        NSLog(@"消息通知状态%@",value);
        NSDictionary *dic = @{
                              @"msg":@"success",
                              @"code":@"1",
                              @"result":value,
                              };
            if (sucBlock) {
                sucBlock(dic);
            }
    }
                        failBlock:failedBlock];
}
// 查询绑定信息 0xFF
+ (void)queryInfoWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                  failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    NSMutableArray<NSNumber *> *dataList = [NSMutableArray array];
    [dataList addObject:@(0x00)];
    NSUInteger dataLength = dataList.count;
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(5 + dataLength)];
    [byteList addObject:@(mk_function)];
    [byteList addObject:@(0xFF)]; //orderType
    [byteList addObject:@(dataLength)];
    [byteList addObjectsFromArray:dataList];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0xFF)];
    // 转换为字节数组
    NSMutableData *dataBytes = [NSMutableData dataWithCapacity:byteList.count];
    for (NSNumber *num in byteList) {
        Byte byteValue = [num unsignedCharValue];
        [dataBytes appendBytes:&byteValue length:sizeof(Byte)];
    }
    NSString *commandString = [mk_fitpoloAdopter hexStringFromData:dataBytes];

    [self addReadTaskWithTaskID:mk_queryInfo
                       resetNum:NO
                  commandString:commandString
                       sucBlock:^(id returnData) {
        NSData *content = [mk_fitpoloAdopter stringToData:returnData[@"result"][@"result"]];
        if ([content length] == 0) {
            content = @"";
            NSDictionary *dic = @{
                @"msg":@"success",
                @"code":@"2",
                @"result":@"",
            };
            if (sucBlock) {
                sucBlock(dic);
            }
            return;
        }
        const uint8_t *bytes = content.bytes;
        int dataLength = (int)bytes[4];
        NSData *data = [content subdataWithRange:NSMakeRange(5, dataLength)];
        const uint8_t *dataBytes2 = data.bytes;
        int type = (int)dataBytes2[0];
        int status = (int)dataBytes2[0];
        NSMutableArray<NSNumber*> *resultArray = [[NSMutableArray alloc]init];
        [resultArray addObject:@(type)];
        [resultArray addObject:@(status)];
        NSLog(@"resultArray===: %@", resultArray);
        NSDictionary *dic = @{
                              @"msg":@"success",
                              @"code":@"1",
                              @"result":resultArray,
                              };
            if (sucBlock) {
                sucBlock(dic);
            }
    }
                      failBlock:failedBlock];
}

#pragma mark - 鉴权
// 鉴权 0x01
+ (void)deviceBindWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                       failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    
    [currentCentral addNeedResetNumTaskWithTaskID:mk_deviceBind
                                           number:10
                                      commandData:@"ff0b040106000100000001ffff"
                                   characteristic:connectedPeripheral.readData
                                     successBlock:^(id returnData) {
        NSData *content = [mk_fitpoloAdopter stringToData:returnData[@"result"][@"result"]];
        if ([content length] == 0) {
            content = @"";
            NSDictionary *dic = @{
                @"msg":@"success",
                @"code":@"2",
                @"result":@"",
            };
            if (sucBlock) {
                sucBlock(dic);
            }
            return;
        }
        const uint8_t *bytes = content.bytes;
        int dataLength = (int)bytes[4];
        NSLog(@"鉴权原始数据%@",content);
        NSData *resultData = [content subdataWithRange:NSMakeRange(5, dataLength)];
        int resType = (int)bytes[5];
        int result = (int)bytes[6];
        NSString *resultStr = [NSString stringWithFormat:@"%d", result];
        NSLog(@"鉴权状态===result=========%d",result);
        if(resType == 0 && result == 1) {
            NSLog(@"请在设备端点击确认");
        } else if(resType == 0 && result == 2) {
            NSLog(@"设备已被绑定");
            [currentCentral cancelOpration:mk_deviceBind];
            NSDictionary *dic = @{
                                  @"msg":@"success",
                                  @"code":@"1",
                                  @"result":resultStr,
                                  };
            if (sucBlock) {
                sucBlock(dic);
            }
        } else if(resType == 0 && result == 3) {
            [currentCentral cancelOpration:mk_deviceBind];
            NSDictionary *dic = @{
                                  @"msg":@"success",
                                  @"code":@"1",
                                  @"result":resultStr,
                                  };
            if (sucBlock) {
                sucBlock(dic);
            }
            [self deviceBindEnterWithsucBlock:^(id returnData) {
                NSLog(@"设备绑定确认-成功");
            } failedBlock:^(NSError *error) {
                NSLog(@"设备绑定确认-失败");
            }];
            
        } else if(resType == 0 && result == 4) {//用户取消绑定
            [currentCentral cancelOpration:mk_deviceBind];
            NSDictionary *dic = @{
                                  @"msg":@"success",
                                  @"code":@"1",
                                  @"result":resultStr,
                                  };
            if (sucBlock) {
                sucBlock(dic);
            }
        }
    }
                                     failureBlock:failedBlock];
}
//绑定确认
+ (void)deviceBindEnterWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                       failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    [self addReadTaskWithTaskID:mk_deviceBindEnter
                       resetNum:NO
                  commandString:@"ff0b040106000200000000ffff"
                       sucBlock:^(id returnData) {
        NSData *content = [mk_fitpoloAdopter stringToData:returnData[@"result"][@"result"]];
        if ([content length] == 0) {
            content = @"";
            NSDictionary *dic = @{
                @"msg":@"success",
                @"code":@"2",
                @"result":@"",
            };
            if (sucBlock) {
                sucBlock(dic);
            }
            return;
        }
        const uint8_t *bytes = content.bytes;
        int dataLength = (int)bytes[4];
        NSData *resultData = [content subdataWithRange:NSMakeRange(5, dataLength)];
        int resType = (int)bytes[5];
        int resResult = (int)bytes[6];
        int reason = (int)bytes[7];
        NSLog(@"鉴权原始数据%d%d%d",resType,resResult,reason);
        if((resType == 0) && (resResult == 2) && (reason == 2)) {
            sucBlock;
        } else {
            failedBlock;
        }
    }
                      failBlock:failedBlock];
}
// 查询鉴权状态 0x02
+ (void)queryAuthStateWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                       failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    [self addReadTaskWithTaskID:mk_queryAuthState
                         resetNum:NO
                    commandString:@"ff0604020100ffff"
                         sucBlock:^(id returnData) {
        NSString *content= returnData[@"result"][@"result"];
        if (!mk_validStr(content)) {
            content = @"";
            NSDictionary *dic = @{
                @"msg":@"success",
                @"code":@"2",
                @"result":@"",
            };
            if (sucBlock) {
                sucBlock(dic);
            }
            return;
        }
        NSString *value = [content substringWithRange:NSMakeRange(12, 2)];
        NSLog(@"查询鉴权状态%@",value);
        NSDictionary *dic = @{
                              @"msg":@"success",
                              @"code":@"1",
                              @"result":value,
                              };
        if (sucBlock) {
            sucBlock(dic);
        }
    }
                      failBlock:failedBlock];

}



+ (void)readBatteryWithSucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                    failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
//    if (currentCentral.deviceType == mk_fitpolo701) {
        [self readPeripheralMemoryDataWithSucBlock:^(id returnData) {
            NSString *battery = returnData[@"result"][@"battery"];
            if (!mk_validStr(battery)) {
                battery = @"";
            }
            NSDictionary *dic = @{
                                  @"msg":@"success",
                                  @"code":@"1",
                                  @"result":@{
                                          @"battery":battery,
                                          },
                                  };
            if (sucBlock) {
                sucBlock(dic);
            }
        }
                                         failBlock:failedBlock];
        return;
//    }
    [self addReadTaskWithTaskID:mk_readBatteryOperation
                       resetNum:NO
                  commandString:@"b01900"
                       sucBlock:sucBlock
                      failBlock:failedBlock];
}

+ (void)readFirmwareVersionWithSucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                            failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    NSString *commandString = (currentCentral.deviceType == mk_fitpolo701 ? @"1606" : @"b01100");
    [self addReadTaskWithTaskID:mk_readFirmwareVersionOperation
                       resetNum:NO
                  commandString:commandString
                       sucBlock:sucBlock
                      failBlock:failedBlock];
}

+ (void)readHardwareParametersWithSucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                               failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    NSString *commandString = (currentCentral.deviceType == mk_fitpolo701 ? @"1622" : @"b01000");
    [self addReadTaskWithTaskID:mk_readHardwareParametersOperation
                       resetNum:NO
                  commandString:commandString
                       sucBlock:sucBlock
                      failBlock:failedBlock];
}

+ (void)readLastChargingTimeWithSucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                             failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    if (currentCentral.deviceType == mk_fitpolo701) {
        [self readHardwareParametersWithSucBlock:^(id returnData) {
            NSDictionary *dic = @{
                                  @"msg":@"success",
                                  @"code":@"1",
                                  @"result":@{
                                            @"chargingTime":returnData[@"result"][@"hardwareParameters"][@"chargingTime"]
                                          },
                                  };
            if (sucBlock) {
                sucBlock(dic);
            }
        } failedBlock:failedBlock];
        return;
    }
    [self addReadTaskWithTaskID:mk_readLastChargingTimeOperation
                       resetNum:NO
                  commandString:@"b01800"
                       sucBlock:sucBlock
                      failBlock:failedBlock];
}

+ (void)readUnitWithSucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                 failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    if (currentCentral.deviceType == mk_fitpolo701) {
        [self readConfigParamsWithSucBlock:^(id returnData) {
            NSString *unit = returnData[@"result"][@"configurationParameters"][@"unit"];
            if (!mk_validStr(unit)) {
                unit = @"";
            }
            NSDictionary *dic = @{
                                  @"msg":@"success",
                                  @"code":@"1",
                                  @"result":@{
                                          @"unit":unit,
                                          },
                                  };
            sucBlock(dic);
        } failedBlock:failedBlock];
        return;
    }
    [self addReadTaskWithTaskID:mk_readUnitDataOperation
                       resetNum:NO
                  commandString:@"aaa00700"
                       sucBlock:sucBlock
                      failBlock:failedBlock];
}

+ (void)readTimeFormatWithSucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                       failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    if (currentCentral.deviceType == mk_fitpolo701) {
        [self readConfigParamsWithSucBlock:^(id returnData) {
            NSString *timeFormat = returnData[@"result"][@"configurationParameters"][@"timeFormat"];
            if (!mk_validStr(timeFormat)) {
                timeFormat = @"";
            }
            NSDictionary *dic = @{
                                  @"msg":@"success",
                                  @"code":@"1",
                                  @"result":@{
                                          @"timeFormat":timeFormat,
                                          },
                                  };
            sucBlock(dic);
        } failedBlock:failedBlock];
        return;
    }
    [self addReadTaskWithTaskID:mk_readTimeFormatDataOperation
                       resetNum:NO
                  commandString:@"b00800"
                       sucBlock:sucBlock
                      failBlock:failedBlock];
}

+ (void)readPalmingBrightScreenWithSucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                                failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    if (currentCentral.deviceType == mk_fitpolo701) {
        [self readConfigParamsWithSucBlock:^(id returnData) {
            NSDictionary *dic = @{
                                  @"isOn":returnData[@"result"][@"configurationParameters"][@"palmingBrightScreen"],
                                  @"startHour":@"",
                                  @"startMin":@"",
                                  @"endHour":@"",
                                  @"endMin":@"",
                                  };
            NSDictionary *resultDic = @{
                                        @"msg":@"success",
                                        @"code":@"1",
                                        @"result":@{
                                                @"palmingBrightScreen":dic,
                                                },
                                        };
            sucBlock(resultDic);
        } failedBlock:failedBlock];
        return;
    }
    [self addReadTaskWithTaskID:mk_readPalmingBrightScreenOperation
                       resetNum:NO
                  commandString:@"b00d00"
                       sucBlock:sucBlock
                      failBlock:failedBlock];
}

+ (void)readHeartRateAcquisitionIntervalWithSucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                                         failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    if (currentCentral.deviceType == mk_fitpolo701) {
        [self readConfigParamsWithSucBlock:^(id returnData) {
            NSString *interval = returnData[@"result"][@"configurationParameters"][@"heartRateAcquisitionInterval"];
            if (!mk_validStr(interval)) {
                interval = @"0";
            }
            NSDictionary *dic = @{
                                  @"msg":@"success",
                                  @"code":@"1",
                                  @"result":@{
                                          @"heartRateAcquisitionInterval":interval,
                                          },
                                  };
            sucBlock(dic);
        } failedBlock:failedBlock];
        return;
    }
    [self addReadTaskWithTaskID:mk_readHeartRateAcquisitionIntervalOperation
                       resetNum:NO
                  commandString:@"b00b00"
                       sucBlock:sucBlock
                      failBlock:failedBlock];
}

+ (void)readSedentaryRemindWithSucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                            failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    NSString *commandString = (currentCentral.deviceType == mk_fitpolo701 ? @"b002" : @"b00400");
    [self addReadTaskWithTaskID:mk_readSedentaryRemindOperation
                       resetNum:NO
                  commandString:commandString
                       sucBlock:^(id returnData) {
                           NSDictionary *dic = [MKDeviceInterfaceAdopter conversionTimeDictionary:returnData[@"result"][@"sedentaryRemind"]];
                           NSDictionary *resultDic = @{
                                                       @"msg":@"success",
                                                       @"code":@"1",
                                                       @"result":@{
                                                               @"sedentaryRemind":dic
                                                               },
                                                       };
                           sucBlock(resultDic);
                       } failBlock:failedBlock];
}

+ (void)readAncsConnectStatusWithSucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                              failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    if (currentCentral.deviceType == mk_fitpolo701) {
        [self readHardwareParametersWithSucBlock:^(id returnData) {
            BOOL status = [returnData[@"result"][@"hardwareParameters"][@"ancsConnectStatus"] boolValue];
            NSDictionary *dic = @{
                                  @"msg":@"success",
                                  @"code":@"1",
                                  @"result":@{
                                          @"connectStatus":@(status),
                                          },
                                  };
            sucBlock(dic);
        } failedBlock:failedBlock];
        return;
    }
    [self addReadTaskWithTaskID:mk_readANCSConnectStatusOperation
                       resetNum:NO
                  commandString:@"b01a00"
                       sucBlock:sucBlock
                      failBlock:failedBlock];
}

+ (void)readAncsOptionsWithSucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                        failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    NSString *commandString = (currentCentral.deviceType == mk_fitpolo701 ? @"1611" : @"b00300");
    [self addReadTaskWithTaskID:mk_readAncsOptionsOperation
                       resetNum:NO
                  commandString:commandString
                       sucBlock:sucBlock
                      failBlock:failedBlock];
}

+ (void)readAlarmClockDatasWithSucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                            failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    __weak typeof(self) weakSelf = self;
    if (currentCentral.deviceType == mk_fitpolo701) {
        //701
        [[mk_fitpoloCentralManager sharedInstance] addNeedResetNumTaskWithTaskID:mk_readAlarmClockOperation
                                                                          number:2
                                                                     commandData:@"b001"
                                                                  characteristic:connectedPeripheral.commandSend
                                                                    successBlock:^(id returnData) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf parseClockDatas:returnData sucBlock:sucBlock];
        }
                                                                    failureBlock:failedBlock];
        return;
    }
    [self addReadTaskWithTaskID:mk_readAlarmClockOperation
                       resetNum:YES
                  commandString:@"b00100"
                       sucBlock:^(id returnData) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf parseClockDatas:returnData sucBlock:sucBlock];
    }
                      failBlock:failedBlock];
}

+ (void)readRemindLastScreenDisplayWithSucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                                    failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    if (currentCentral.deviceType == mk_fitpolo701) {
        [self readConfigParamsWithSucBlock:^(id returnData) {
            BOOL palmingBrightScreen = [returnData[@"result"][@"configurationParameters"][@"remindLastScreenDisplay"] boolValue];
            
            NSDictionary *dic = @{
                                  @"msg":@"success",
                                  @"code":@"1",
                                  @"result":@{
                                          @"isOn":@(palmingBrightScreen),
                                          },
                                  };
            sucBlock(dic);
        } failedBlock:failedBlock];
        return;
    }
    [self addReadTaskWithTaskID:mk_readRemindLastScreenDisplayOperation
                       resetNum:NO
                  commandString:@"b00a00"
                       sucBlock:sucBlock
                      failBlock:failedBlock];
}

+ (void)readCustomScreenDisplayWithSucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                                failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    if (currentCentral.deviceType == mk_fitpolo701) {
        [self readConfigParamsWithSucBlock:^(id returnData) {
            NSDictionary *dic = @{
                                  @"msg":@"success",
                                  @"code":@"1",
                                  @"result":@{
                                          @"customScreenModel":returnData[@"result"][@"configurationParameters"][@"screenDisplayModel"],
                                          },
                                  };
            sucBlock(dic);
        } failedBlock:failedBlock];
        return;
    }
    [self addReadTaskWithTaskID:mk_readCustomScreenDisplayOperation
                       resetNum:NO
                  commandString:@"b00900"
                       sucBlock:sucBlock
                      failBlock:failedBlock];
}

#pragma mark - 701特有
+ (void)readPeripheralMemoryDataWithSucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                                   failBlock:(mk_deviceInterfaceFailedBlock)failBlock{
    if (currentCentral.deviceType != mk_fitpolo701 && currentCentral.deviceType == mk_fitpoloUnknow) {
        [mk_fitpoloAdopter operationUnsupportCommandErrorBlock:failBlock];
        return;
    }
    [self addReadTaskWithTaskID:mk_readMemoryDataOperation
                       resetNum:NO
                  commandString:@"1600"
                       sucBlock:sucBlock
                      failBlock:failBlock];
}

+ (void)readInternalVersionWithSucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                              failBlock:(mk_deviceInterfaceFailedBlock)failBlock{
    if (currentCentral.deviceType != mk_fitpolo701 && currentCentral.deviceType == mk_fitpoloUnknow) {
        [mk_fitpoloAdopter operationUnsupportCommandErrorBlock:failBlock];
        return;
    }
    [self addReadTaskWithTaskID:mk_readInternalVersionOperation
                       resetNum:NO
                  commandString:@"1609"
                       sucBlock:sucBlock
                      failBlock:failBlock];
}

+ (void)readConfigParamsWithSucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                         failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    if (currentCentral.deviceType != mk_fitpolo701 && currentCentral.deviceType == mk_fitpoloUnknow) {
        [mk_fitpoloAdopter operationUnsupportCommandErrorBlock:failedBlock];
        return;
    }
    [self addReadTaskWithTaskID:mk_readConfigurationParametersOperation
                       resetNum:NO
                  commandString:@"b004"
                       sucBlock:sucBlock
                      failBlock:failedBlock];
}

#pragma mark - 非701特有
+ (void)readDoNotDisturbWithSucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                         failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    if (currentCentral.deviceType == mk_fitpolo701) {
        [mk_fitpoloAdopter operationUnsupportCommandErrorBlock:failedBlock];
        return;
    }
    [self addReadTaskWithTaskID:mk_readDoNotDisturbTimeOperation
                       resetNum:NO
                  commandString:@"b00c00"
                       sucBlock:^(id returnData) {
                           NSDictionary *dic = [MKDeviceInterfaceAdopter conversionTimeDictionary:returnData[@"result"][@"periodTime"]];
                           NSDictionary *resultDic = @{
                                                       @"msg":@"success",
                                                       @"code":@"1",
                                                       @"result":@{
                                                               @"periodTime":dic
                                                               },
                                                       };
                           sucBlock(resultDic);
                       }
                      failBlock:failedBlock];
}

+ (void)readDialStyleWithSucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                      failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    if (currentCentral.deviceType == mk_fitpolo701) {
        [mk_fitpoloAdopter operationUnsupportCommandErrorBlock:failedBlock];
        return;
    }
    [self addReadTaskWithTaskID:mk_readDialStyleOperation
                       resetNum:NO
                  commandString:@"b00f00"
                       sucBlock:sucBlock
                      failBlock:failedBlock];
}

#pragma mark - ***********************706、707特有*******************************

+ (void)readDateFormatterWithSucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                          failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock {
    if (currentCentral.deviceType == mk_fitpolo701 || currentCentral.deviceType == mk_fitpolo705) {
        [mk_fitpoloAdopter operationUnsupportCommandErrorBlock:failedBlock];
        return;
    }
    [self addReadTaskWithTaskID:mk_readDateFormatterOperation
                       resetNum:NO
                  commandString:@"b01d00"
                       sucBlock:sucBlock
                      failBlock:failedBlock];
}

+ (void)readVibrationIntensityOfDeviceWithSucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                                       failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    if (currentCentral.deviceType == mk_fitpolo701 || currentCentral.deviceType == mk_fitpolo705) {
        [mk_fitpoloAdopter operationUnsupportCommandErrorBlock:failedBlock];
        return;
    }
    [self addReadTaskWithTaskID:mk_readVibrationIntensityOfDeviceOperation
                       resetNum:NO
                  commandString:@"b01e00"
                       sucBlock:sucBlock
                      failBlock:failedBlock];
}

+ (void)readDeviceScreenListWithSucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                             failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock {
    if (currentCentral.deviceType == mk_fitpolo701 || currentCentral.deviceType == mk_fitpolo705) {
        [mk_fitpoloAdopter operationUnsupportCommandErrorBlock:failedBlock];
        return;
    }
    [self addReadTaskWithTaskID:mk_readScreenListOperation
                       resetNum:NO
                  commandString:@"b01f00"
                       sucBlock:sucBlock
                      failBlock:failedBlock];
}

#pragma mark -
+ (void)addReadTaskWithTaskID:(mk_taskOperationID)taskID
                     resetNum:(BOOL)resetNum
                commandString:(NSString *)commandString
                     sucBlock:(mk_communicationSuccessBlock)sucBlock
                    failBlock:(mk_communicationFailedBlock)failBlock{
    CBCharacteristic *character = (currentCentral.deviceType == mk_fitpolo701
                                   ? connectedPeripheral.commandSend
                                   : connectedPeripheral.readData);
    [currentCentral addTaskWithTaskID:taskID
                             resetNum:resetNum
                          commandData:commandString
                       characteristic:character
                         successBlock:sucBlock
                         failureBlock:failBlock];
}

#pragma mark -

+ (void)parseClockDatas:(id)returnData
               sucBlock:(mk_deviceInterfaceSucBlock)sucBlock{
    NSArray *list = [MKDeviceInterfaceAdopter parseAlarmClockList:returnData[@"result"]];
    NSDictionary *resultDic = @{@"msg":@"success",
                                @"code":@"1",
                                @"result":list,
                                };
    
    mk_fitpolo_main_safe(^{
        if (sucBlock) {
            sucBlock(resultDic);
        }
    });
}

@end
