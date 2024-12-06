//
//  MKDeviceInterface+DeviceSet.m
//  CyweeBleSDK-iOS
//
//  Created by cywee on 2024/10/9.
//

#import "MKDeviceInterface+DeviceSet.h"

#import "MKDeviceInterface+config.h"
#import "mk_fitpoloDefines.h"
#import "mk_fitpoloCentralManager.h"
#import "MKDeviceInterfaceAdopter.h"
#import "mk_fitpoloAdopter.h"
#import "CBPeripheral+mk_fitpolo701.h"
#import "CBPeripheral+mk_fitpoloCurrent.h"

#define connectedPeripheral (currentCentral.connectedPeripheral)
#define currentCentral ([mk_fitpoloCentralManager sharedInstance])
@implementation MKDeviceInterface (DeviceSet)

// 设置用户信息 0x01
+ (void)setUserInfoWithsucBlock:(id <MKUserInfoProtocol>)protocol
                       sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                     failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    NSString *userInfoString = [NSString stringWithFormat:@"{\"name\":\"%@\",\"male\":%d,\"birth\":%d,\"height\":%d,\"weight\":%d,\"hand\":%d,\"MHR\":%d}", protocol.name, (int)protocol.male, (int)protocol.birth, (int)protocol.height, (int)protocol.weight, (int)protocol.hand, (int)protocol.MHR];
//    NSString *userInfoString = @"{\"MHR\":200,\"birth\":20001109,\"hand\":0,\"height\":170,\"male\":0,\"name\":\"小明\",\"weight\":60}";
    //    NSLog(@"这是设置用户指令==%@", userInfoString);
    NSString *userInfoHexString = [mk_fitpoloAdopter hexStringFromString:userInfoString];
    NSData *userInfoNSData = [mk_fitpoloAdopter dataWithHexString:userInfoHexString];
    
    const unsigned char *bytes = [userInfoNSData bytes];
    NSUInteger length = [userInfoNSData length];
    NSMutableArray<NSNumber *> *userDataArray = [NSMutableArray array];
    for (NSUInteger i = 0; i < length; i++) {
        [userDataArray addObject:@(bytes[i])];
    }
    NSUInteger dataLength = userDataArray.count;
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(5 + dataLength)];
    [byteList addObject:@(mk_setting)];
    [byteList addObject:@(0x01)]; //orderType
    [byteList addObject:@(dataLength)];
    [byteList addObjectsFromArray:userDataArray];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0xFF)];
    // 转换为字节数组
    NSMutableData *dataBytes = [NSMutableData dataWithCapacity:byteList.count];
    for (NSNumber *num in byteList) {
        Byte byteValue = [num unsignedCharValue];
        [dataBytes appendBytes:&byteValue length:sizeof(Byte)];
    }
    NSString *commandString = [mk_fitpoloAdopter hexStringFromData:dataBytes];
    
    [self addReadTaskWithTaskID:mk_setUserInfo
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
        NSString *value = [content substringWithRange:NSMakeRange(11, 1)];
        NSLog(@"设置用户信息状态%@",value);
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
// 获取用户信息 0x01
+ (void)getUserInfoWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                     failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0x04)];
    [byteList addObject:@(mk_getSetting)];
    [byteList addObject:@(0x01)]; //orderType
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0xFF)];
    // 转换为字节数组
    NSMutableData *dataBytes = [NSMutableData dataWithCapacity:byteList.count];
    for (NSNumber *num in byteList) {
        Byte byteValue = [num unsignedCharValue];
        [dataBytes appendBytes:&byteValue length:sizeof(Byte)];
    }
    NSString *commandString = [mk_fitpoloAdopter hexStringFromData:dataBytes];
    
    [self addReadTaskWithTaskID:mk_getUserInfo
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
//        NSLog(@"获取用户信息content===: %@", content);
        const uint8_t *bytes = content.bytes;
        int dataLength = (int)bytes[4];
        NSData *data = [content subdataWithRange:NSMakeRange(5, dataLength)];
        NSDictionary *dataDic;
        @try {
            dataDic = [mk_fitpoloAdopter turnArrDic:data];
            NSLog(@"获取用户信息dataDic===: %@", dataDic);
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
            NSLog(@"获取用户信息dataDic===: %@", dataDic);
            NSDictionary *dic = @{
                                  @"msg":@"faild",
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
// 目标设置 0x02
+ (void)setTargetWithsucBlock:(int)step
                     distance:(int)distance
                      calorie:(int)calorie
                         time:(int)time
                     sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                  failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    NSMutableArray<NSNumber *> *dataList = [NSMutableArray array];
    [dataList addObject:@((Byte)(step & 0xFF))];
    [dataList addObject:@((Byte)(distance & 0xFF))];
    [dataList addObject:@((Byte)(calorie & 0xFF))];
    [dataList addObject:@((Byte)(time & 0xFF))];

    NSUInteger dataLength = dataList.count;
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(5 + dataLength)];
    [byteList addObject:@(mk_setting)];
    [byteList addObject:@(0x02)]; //orderType
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
    
    [self addReadTaskWithTaskID:mk_setTarget
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
        NSString *value = [content substringWithRange:NSMakeRange(11, 1)];
        NSLog(@"目标设置状态%@",value);
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
// 目标获取 0x02
+ (void)getTargetWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                  failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0x04)];
    [byteList addObject:@(mk_getSetting)];
    [byteList addObject:@(0x02)]; //orderType
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0xFF)];
    // 转换为字节数组
    NSMutableData *dataBytes = [NSMutableData dataWithCapacity:byteList.count];
    for (NSNumber *num in byteList) {
        Byte byteValue = [num unsignedCharValue];
        [dataBytes appendBytes:&byteValue length:sizeof(Byte)];
    }
    NSString *commandString = [mk_fitpoloAdopter hexStringFromData:dataBytes];
    
    [self addReadTaskWithTaskID:mk_getTarget
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
        const uint8_t *byteArray = data.bytes;
        NSArray *resultArray = @[@(byteArray[0]), @(byteArray[1]), @(byteArray[2]), @(byteArray[3]),];
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

// 运动目标设置 0x0a
+ (void)setMotionTargetWithsucBlock:(id <MKMotionTargetProtocol>) protocol
                           sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                        failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    NSMutableArray<NSNumber *> *dataList = [NSMutableArray array];
    [dataList addObject:@((Byte)(protocol.setType & 0xFF))];
    [dataList addObject:@((Byte)(protocol.sportType & 0xFF))];
    if(protocol.setType == 0) {
        [dataList addObject:@((Byte)(protocol.distance & 0xFF))];
        [dataList addObject:@((Byte)(protocol.sportTime & 0xFF))];
        [dataList addObject:@((Byte)(protocol.calorie & 0xFF))];
        [dataList addObject:@((Byte)(protocol.targetType & 0xFF))];
    } else {
        [dataList addObject:@((Byte)(protocol.autoPauseSwitch & 0xFF))];
    }

    NSUInteger dataLength = dataList.count;
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(5 + dataLength)];
    [byteList addObject:@(mk_setting)];
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
    
    [self addReadTaskWithTaskID:mk_setMotionTarget
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
        NSString *value = [content substringWithRange:NSMakeRange(11, 1)];
        NSLog(@"运动目标设置状态%@",value);
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

// 运动目标获取 0x0a
+ (void)getMotionTargetWithsucBlock:(int)sportType
                           sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                        failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    
    NSMutableArray<NSNumber *> *dataList = [NSMutableArray array];
    [dataList addObject:@(0x00)];
    [dataList addObject:@((Byte)(sportType & 0xFF))];
    NSUInteger dataLength = dataList.count;
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0x04)];
    [byteList addObject:@(mk_getSetting)];
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
    
    [self addReadTaskWithTaskID:mk_getMotionTarget
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
        const uint8_t *byteArray = data.bytes;
        int distanceTarget = (int)byteArray[2];
        int timeTarget = (int)byteArray[3];
        int calorieTarget = (int)byteArray[4];
        int targetType = (int)byteArray[5];
        
        NSArray *resultArray = @[@(distanceTarget), @(timeTarget), @(calorieTarget), @(targetType)];
        NSLog(@"运动目标获取resultArray==》%@",resultArray);
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
//运动自动暂停 0x0a
+ (void)getMotionAutoPauseWithsucBlock:(int)sportType
                              sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                           failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    
    NSMutableArray<NSNumber *> *dataList = [NSMutableArray array];
    [dataList addObject:@(0x01)];
    [dataList addObject:@((Byte)(sportType & 0xFF))];
    NSUInteger dataLength = dataList.count;
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0x04)];
    [byteList addObject:@(mk_getSetting)];
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
    
    [self addReadTaskWithTaskID:mk_getMotionAutoPause
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
        const uint8_t *byteArray = data.bytes;
        NSString *toggle = [NSString stringWithFormat:@"%d", (int)byteArray[2]];
        NSLog(@"运动目标获取resultArray==》%@",toggle);
        NSDictionary *dic = @{
            @"msg":@"success",
            @"code":@"1",
            @"result":toggle,
        };
        if (sucBlock) {
            sucBlock(dic);
        }
    }
                      failBlock:failedBlock];
}
// 语言设置 0x0c
+ (void)setLanguageWithsucBlock:(NSInteger) language
                       sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                    failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    if (language != 0 && language != 1 && language != 2) {
        NSLog(@"语言设置参数错误");
        return;
    }
    NSMutableArray<NSNumber *> *dataList = [NSMutableArray array];
    [dataList addObject:@((Byte)(language & 0xFF))];
    NSUInteger dataLength = dataList.count;
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(5 + dataLength)];
    [byteList addObject:@(mk_setting)];
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
    
    [self addReadTaskWithTaskID:mk_setLanguage
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
        NSString *value = [content substringWithRange:NSMakeRange(11, 1)];
        NSLog(@"语言设置状态%@",value);
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
// 久坐提醒设置 0x05
+ (void)setSitLongTimeAlertWithsucBlock:(int) toggle
                               interval:(int) interval
                              startTime:(int) startTime
                                endTime:(int) endTime
                               sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                            failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    NSMutableArray<NSNumber *> *dataList = [NSMutableArray array];
    [dataList addObject:@((Byte)(toggle & 0xFF))]; //开关
    NSArray<NSNumber *> *intervalData = [mk_fitpoloAdopter arrayFromHexString:[NSString stringWithFormat:@"%x", interval]];
    [dataList addObjectsFromArray:intervalData];//间隔
    NSArray<NSNumber *> *startTimeData = [mk_fitpoloAdopter convert:startTime byteType:mk_word];
    [dataList addObjectsFromArray:startTimeData];//开始时间
    NSArray<NSNumber *> *endTimeData = [mk_fitpoloAdopter convert:endTime byteType:mk_word];
    [dataList addObjectsFromArray:endTimeData];//结束时间
    [dataList addObject:@(0x00)];
    NSUInteger dataLength = dataList.count;
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(5 + dataLength)];
    [byteList addObject:@(mk_setting)];
    [byteList addObject:@(0x05)]; //orderType
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
    
    [self addReadTaskWithTaskID:mk_setSitLongTimeAlert
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
        NSString *value = [content substringWithRange:NSMakeRange(11, 1)];
        NSLog(@"久坐提醒设置状态%@",value);
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
// 久坐提醒获取 0x05
+ (void)getSitLongTimeAlertWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                            failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0x04)];
    [byteList addObject:@(mk_getSetting)];
    [byteList addObject:@(0x05)]; //orderType
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0xFF)];
    // 转换为字节数组
    NSMutableData *dataBytes = [NSMutableData dataWithCapacity:byteList.count];
    for (NSNumber *num in byteList) {
        Byte byteValue = [num unsignedCharValue];
        [dataBytes appendBytes:&byteValue length:sizeof(Byte)];
    }
    NSString *commandString = [mk_fitpoloAdopter hexStringFromData:dataBytes];
    
    [self addReadTaskWithTaskID:mk_getSitLongTimeAlert
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
        const uint8_t *byteArray = data.bytes;
        int sitAlertSwitch = (int)byteArray[0];
        int timeValue = (int)byteArray[1];
        NSData *startTime = [data subdataWithRange:NSMakeRange(2, 2)];
        NSString *startHexString = [mk_fitpoloAdopter hexStringFromData:startTime];
        unsigned int startTimeValue = strtoul([startHexString UTF8String], NULL, 16);
        
        NSData *endTime = [data subdataWithRange:NSMakeRange(4, 2)];
        NSString *endHexString = [mk_fitpoloAdopter hexStringFromData:endTime];
        unsigned int endTimeValue = strtoul([endHexString UTF8String], NULL, 16);
        
        NSArray *resultArray = @[@(sitAlertSwitch), @(timeValue), @(startTimeValue), @(endTimeValue),];
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

// 抬手亮屏设置 0x06
+ (void)setAutoLightenWithsucBlock:(int) toggle
                          sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                       failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    NSMutableArray<NSNumber *> *dataList = [NSMutableArray array];
    [dataList addObject:@((Byte)(toggle & 0xFF))]; //开关
    NSUInteger dataLength = dataList.count;
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(5 + dataLength)];
    [byteList addObject:@(mk_setting)];
    [byteList addObject:@(0x06)]; //orderType
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
    
    [self addReadTaskWithTaskID:mk_setAutoLighten
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
        NSString *value = [content substringWithRange:NSMakeRange(11, 1)];
        NSLog(@"抬手亮屏设置状态%@",value);
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
// 抬手亮屏获取 0x06
+ (void)getAutoLightenWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                       failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0x04)];
    [byteList addObject:@(mk_getSetting)];
    [byteList addObject:@(0x06)]; //orderType
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0xFF)];
    // 转换为字节数组
    NSMutableData *dataBytes = [NSMutableData dataWithCapacity:byteList.count];
    for (NSNumber *num in byteList) {
        Byte byteValue = [num unsignedCharValue];
        [dataBytes appendBytes:&byteValue length:sizeof(Byte)];
    }
    NSString *commandString = [mk_fitpoloAdopter hexStringFromData:dataBytes];
    
    [self addReadTaskWithTaskID:mk_getAutoLighten
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
        const uint8_t *byteArray = data.bytes;
        NSString *toggle = [NSString stringWithFormat:@"%d", (int)byteArray[0]];
        
        NSDictionary *dic = @{
            @"msg":@"success",
            @"code":@"1",
            @"result":toggle,
        };
        if (sucBlock) {
            sucBlock(dic);
        }
    }
                      failBlock:failedBlock];
}
// 心率监测设置 0x07
+ (void)setHeartRateMonitorWithsucBlock:(int)monitorSwitch
                               interval:(int)interval
                            alarmSwitch:(int)alarmSwitch
                               minLimit:(int)minLimit
                               maxLimit:(int)maxLimit
                               sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                            failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    if(interval < 0 || interval > 60) {
        NSLog(@"心率监控间隔时间错误");
        return;
    }
    if(minLimit < 0 || minLimit > 100) {
        NSLog(@"低心率限制值错误");
        return;
    }
    if(maxLimit < 100 || maxLimit > 250) {
        NSLog(@"高心率限制值错误");
        return;
    }
    NSMutableArray<NSNumber *> *dataList = [NSMutableArray array];
    [dataList addObject:@((Byte)(monitorSwitch & 0xFF))]; //监控开关
    [dataList addObject:@((Byte)(interval & 0xFF))]; //监控间隔时间/min
    [dataList addObject:@((Byte)(alarmSwitch & 0xFF))]; //报警开关
    [dataList addObject:@((Byte)(minLimit & 0xFF))]; //低心率限制
    [dataList addObject:@((Byte)(maxLimit & 0xFF))]; //高心率限制
    NSUInteger dataLength = dataList.count;
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(5 + dataLength)];
    [byteList addObject:@(mk_setting)];
    [byteList addObject:@(0x07)]; //orderType
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
    
    [self addReadTaskWithTaskID:mk_setHeartRateMonitor
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
        NSString *value = [content substringWithRange:NSMakeRange(11, 1)];
        NSLog(@"心率监测设置状态%@",value);
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
// 心率监测获取 0x07
+ (void)getHeartRateMonitorWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                            failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0x04)];
    [byteList addObject:@(mk_getSetting)];
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
    
    [self addReadTaskWithTaskID:mk_getHeartRateMonitor
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
        const uint8_t *byteArray = data.bytes;
        int monitorSwitch = (int)byteArray[0];
        int interval = (int)byteArray[1];
        int alarmSwitch = (int)byteArray[2];
        int minLimit = (int)byteArray[3];
        int maxLimit = (int)byteArray[4];
        
        NSArray *resultArray = @[@(monitorSwitch), @(interval), @(alarmSwitch), @(minLimit), @(maxLimit)];
        NSLog(@"心率监测状态resultArray==》%@",resultArray);
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
// 来电提醒设置 0x09
+ (void)setCallReminderWithsucBlock:(int) toggle
                           sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                        failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    NSMutableArray<NSNumber *> *dataList = [NSMutableArray array];
    [dataList addObject:@((Byte)(toggle & 0xFF))]; //开关
    NSUInteger dataLength = dataList.count;
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(5 + dataLength)];
    [byteList addObject:@(mk_setting)];
    [byteList addObject:@(0x09)]; //orderType
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
    
    [self addReadTaskWithTaskID:mk_setCallReminder
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
        NSString *value = [content substringWithRange:NSMakeRange(11, 1)];
        NSLog(@"来电提醒设置状态%@",value);
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
// 来电提醒获取  0x09
+ (void)getCallReminderWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                        failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0x04)];
    [byteList addObject:@(mk_getSetting)];
    [byteList addObject:@(0x09)]; //orderType
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0xFF)];
    // 转换为字节数组
    NSMutableData *dataBytes = [NSMutableData dataWithCapacity:byteList.count];
    for (NSNumber *num in byteList) {
        Byte byteValue = [num unsignedCharValue];
        [dataBytes appendBytes:&byteValue length:sizeof(Byte)];
    }
    NSString *commandString = [mk_fitpoloAdopter hexStringFromData:dataBytes];
    
    [self addReadTaskWithTaskID:mk_getCallReminder
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
        const uint8_t *byteArray = data.bytes;
        NSString *toggle = [NSString stringWithFormat:@"%d", (int)byteArray[0]];
        
        NSDictionary *dic = @{
            @"msg":@"success",
            @"code":@"1",
            @"result":toggle,
        };
        if (sucBlock) {
            sucBlock(dic);
        }
    }
                      failBlock:failedBlock];
}
// 通知设置 0x0d
+ (void)setNotifyWithsucBlock:(id <MKNotifyTypeProtocol>)protocol
                     sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                  failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    NSMutableArray<NSNumber *> *dataList = [NSMutableArray array];
    NSMutableArray<NSNumber *> *notifyList = [self notifyData2List:protocol];
    [dataList addObject:@((Byte)(protocol.toggle & 0xFF))]; //开关
    [dataList addObjectsFromArray:notifyList];
    NSUInteger dataLength = dataList.count;
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(5 + dataLength)];
    [byteList addObject:@(mk_setting)];
    [byteList addObject:@(0x0d)]; //orderType
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
    
    [self addReadTaskWithTaskID:mk_setNotify
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
        NSLog(@"通知设置状态1231  %@",content);
        NSString *value = [content substringWithRange:NSMakeRange(11, 1)];
        NSLog(@"通知设置状态%@",value);
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
// 亮屏时长设置 0x0e
+ (void)setOnScreenDurationWithsucBlock:(int) duration
                               sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                            failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    NSMutableArray<NSNumber *> *dataList = [NSMutableArray array];
    [dataList addObject:@((Byte)(duration & 0xFF))]; //亮屏时长
    NSUInteger dataLength = dataList.count;
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(5 + dataLength)];
    [byteList addObject:@(mk_setting)];
    [byteList addObject:@(0x0e)]; //orderType
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
    
    [self addReadTaskWithTaskID:mk_setOnScreenDuration
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
        NSString *value = [content substringWithRange:NSMakeRange(11, 1)];
        NSLog(@"亮屏时长设置状态%@",value);
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
// 亮屏时长获取 0x0e
+ (void)getOnScreenDurationWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                            failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0x04)];
    [byteList addObject:@(mk_getSetting)];
    [byteList addObject:@(0x0e)]; //orderType
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0xFF)];
    // 转换为字节数组
    NSMutableData *dataBytes = [NSMutableData dataWithCapacity:byteList.count];
    for (NSNumber *num in byteList) {
        Byte byteValue = [num unsignedCharValue];
        [dataBytes appendBytes:&byteValue length:sizeof(Byte)];
    }
    NSString *commandString = [mk_fitpoloAdopter hexStringFromData:dataBytes];
    
    [self addReadTaskWithTaskID:mk_getOnScreenDuration
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
        const uint8_t *byteArray = data.bytes;
        NSString *duration = [NSString stringWithFormat:@"%d", (int)byteArray[0]];
        
        NSDictionary *dic = @{
            @"msg":@"success",
            @"code":@"1",
            @"result":duration,
        };
        if (sucBlock) {
            sucBlock(dic);
        }
    }
                      failBlock:failedBlock];
}
// 勿扰设置 0x0f
+ (void)setDoNotDisturbWithsucBlock:(int)allToggle
                         partToggle:(int)partToggle
                          startTime:(int)startTime
                            endTime:(int)endTime
                           sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                        failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    NSMutableArray<NSNumber *> *dataList = [NSMutableArray array];
    [dataList addObject:@((Byte)(allToggle & 0xFF))];//全天勿扰开关
    [dataList addObject:@((Byte)(partToggle & 0xFF))];//时段勿扰开关
    NSArray<NSNumber *> *startTimeData = [mk_fitpoloAdopter convert:startTime byteType:mk_word];
    [dataList addObjectsFromArray:startTimeData];//开始时间
    NSArray<NSNumber *> *endTimeData = [mk_fitpoloAdopter convert:endTime byteType:mk_word];
    [dataList addObjectsFromArray:endTimeData];//结束时间
    NSUInteger dataLength = dataList.count;
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(5 + dataLength)];
    [byteList addObject:@(mk_setting)];
    [byteList addObject:@(0x0f)]; //orderType
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
    
    [self addReadTaskWithTaskID:mk_setDoNotDisturb
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
        NSString *value = [content substringWithRange:NSMakeRange(11, 1)];
        NSLog(@"亮屏时长设置状态%@",value);
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

// 勿扰获取 0x0f
+ (void)getDoNotDisturbWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                        failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0x04)];
    [byteList addObject:@(mk_getSetting)];
    [byteList addObject:@(0x0f)]; //orderType
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0xFF)];
    // 转换为字节数组
    NSMutableData *dataBytes = [NSMutableData dataWithCapacity:byteList.count];
    for (NSNumber *num in byteList) {
        Byte byteValue = [num unsignedCharValue];
        [dataBytes appendBytes:&byteValue length:sizeof(Byte)];
    }
    NSString *commandString = [mk_fitpoloAdopter hexStringFromData:dataBytes];
    
    [self addReadTaskWithTaskID:mk_getDoNotDisturb
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
        const uint8_t *byteArray = data.bytes;
        int allToggle = (int)byteArray[0];
        int partToggle = (int)byteArray[1];
        NSData *startTime = [data subdataWithRange:NSMakeRange(2, 2)];
        NSString *startHexString = [mk_fitpoloAdopter hexStringFromData:startTime];
        unsigned int startTimeValue = strtoul([startHexString UTF8String], NULL, 16);
        
        NSData *endTime = [data subdataWithRange:NSMakeRange(4, 2)];
        NSString *endHexString = [mk_fitpoloAdopter hexStringFromData:endTime];
        unsigned int endTimeValue = strtoul([endHexString UTF8String], NULL, 16);
        
        NSArray *resultArray = @[@(allToggle), @(partToggle), @(startTimeValue), @(endTimeValue),];
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

// 通讯录设置 0x11
+ (void)setAddressBookWithsucBlock:(int)action// 0-添加 1-删除
                              name:(NSString*)name //名字
                       phoneNumber:(NSString*)phoneNumber //电话
                          sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                        failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    NSMutableArray<NSNumber *> *dataList = [NSMutableArray array];
    [dataList addObject:@((Byte)(action & 0xFF))];//添加删除
    NSString* nameHexStr = [mk_fitpoloAdopter hexStringFromString:name];
    NSArray<NSNumber *> *nameArray = [mk_fitpoloAdopter limitArrayFromHexString:nameHexStr limit:20];
    [dataList addObjectsFromArray:nameArray];//名字
    NSString* phoneHexStr = [mk_fitpoloAdopter hexStringFromString:phoneNumber];
    NSArray<NSNumber *> *phoneArray = [mk_fitpoloAdopter limitArrayFromHexString:phoneHexStr limit:15];
    [dataList addObjectsFromArray:phoneArray];//电话
    NSUInteger dataLength = dataList.count;
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(5 + dataLength)];
    [byteList addObject:@(mk_setting)];
    [byteList addObject:@(0x11)]; //orderType
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
    
    [self addReadTaskWithTaskID:mk_setAddressBook
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
        NSString *value = [content substringWithRange:NSMakeRange(11, 1)];
        NSLog(@"通讯录设置状态%@",value);
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
// 通讯录获取 0x11
+ (void)getAddressBookWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                       failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0x04)];
    [byteList addObject:@(mk_getSetting)];
    [byteList addObject:@(0x11)]; //orderType
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0xFF)];
    // 转换为字节数组
    NSMutableData *dataBytes = [NSMutableData dataWithCapacity:byteList.count];
    for (NSNumber *num in byteList) {
        Byte byteValue = [num unsignedCharValue];
        [dataBytes appendBytes:&byteValue length:sizeof(Byte)];
    }
    NSString *commandString = [mk_fitpoloAdopter hexStringFromData:dataBytes];
    
    __block NSString *result = @"";
    [currentCentral addNeedResetNumTaskWithTaskID:mk_getAddressBook
                                           number:1
                                      commandData:commandString
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
        NSLog(@"通讯录数据====content=====%@", content);
        const uint8_t *bytes = content.bytes;
        int dataLength = (int)bytes[4]+5;
        NSInteger packType = (int)bytes[5];
        NSData *addressBookData = [content subdataWithRange:NSMakeRange(7, dataLength-7)];
        NSLog(@"通讯录数据====addressBookData=====%@", addressBookData);
        NSString *addressBookDataHexString = [mk_fitpoloAdopter hexStringFromData:addressBookData];
        NSLog(@"通讯录数据====addressBookDataHexString=====%@", addressBookDataHexString);
        result = [result stringByAppendingString:addressBookDataHexString];
        NSLog(@"通讯录数据====result=====%@", result);
        if (packType == 2 || packType == 0) {
            ///解析到最后一包触发
            [currentCentral cancelOpration:mk_getAddressBook];
            //最终数据数组
            NSMutableArray<NSDictionary*> *dataList = [NSMutableArray array];
            NSArray<NSNumber *> *resultArray = [mk_fitpoloAdopter arrayFromHexString:result];
            int totals = (int)(resultArray.count / 35);
            NSLog(@"通讯录数据%d", totals);
            for (NSUInteger i=0; i<totals; i++){
                NSArray<NSNumber *> *albumInfo = [resultArray subarrayWithRange:NSMakeRange(i*35, 35)];
                NSArray<NSNumber *> *nameArray = [mk_fitpoloAdopter removeArrayZero:[albumInfo subarrayWithRange:NSMakeRange(0, 20)]];
                NSArray<NSNumber *> *phoneArray = [mk_fitpoloAdopter removeArrayZero:[albumInfo subarrayWithRange:NSMakeRange(20, 15)]];
                NSString *nameHexStr = [mk_fitpoloAdopter nsArrayFromHexString:nameArray];
                NSString *phoneHexStr = [mk_fitpoloAdopter nsArrayFromHexString:phoneArray];
                NSString *nameStr;
                NSString *phoneStr;
                @try {
                    nameStr = [mk_fitpoloAdopter stringFromHexString:nameHexStr];
                    phoneStr = [mk_fitpoloAdopter stringFromHexString:phoneHexStr];
                } @catch (NSException *exception) {
                    nameStr = @"";
                    phoneStr = @"";
                }
                NSLog(@"通讯录数据名字===%@", nameStr);
                NSLog(@"通讯录数据电话===%@", phoneStr);
                NSDictionary* addressBookItem = @{
                    @"name": nameStr,
                    @"phone": phoneStr,
                };
                [dataList addObject:addressBookItem];
            }
            NSLog(@"通讯录数据====dataList=====%@", dataList);
            NSDictionary *dic = @{
                                  @"msg":@"success",
                                  @"code":@"1",
                                  @"result":dataList,
                                  };
            if (sucBlock) {
                sucBlock(dic);
            }
        }
    }
                                     failureBlock:failedBlock];
}
// 睡眠设置 0x04
+ (void)setSleepWithsucBlock:(int) toggle
                   startTime:(int) startTime
                     endTime:(int) endTime
                    sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                 failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    NSMutableArray<NSNumber *> *dataList = [NSMutableArray array];
    [dataList addObject:@((Byte)(toggle & 0xFF))]; //开关
    NSArray<NSNumber *> *startTimeData = [mk_fitpoloAdopter convert:startTime byteType:mk_word];
    [dataList addObjectsFromArray:startTimeData];//开始时间
    NSArray<NSNumber *> *endTimeData = [mk_fitpoloAdopter convert:endTime byteType:mk_word];
    [dataList addObjectsFromArray:endTimeData];//结束时间
    [dataList addObject:@(0x00)];
    NSUInteger dataLength = dataList.count;
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(5 + dataLength)];
    [byteList addObject:@(mk_setting)];
    [byteList addObject:@(0x04)]; //orderType
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
    
    [self addReadTaskWithTaskID:mk_setSleep
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
        NSString *value = [content substringWithRange:NSMakeRange(11, 1)];
        NSLog(@"睡眠设置状态%@",value);
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
// 睡眠获取 0x04
+ (void)getSleepWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                 failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0x04)];
    [byteList addObject:@(mk_getSetting)];
    [byteList addObject:@(0x04)]; //orderType
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0xFF)];
    // 转换为字节数组
    NSMutableData *dataBytes = [NSMutableData dataWithCapacity:byteList.count];
    for (NSNumber *num in byteList) {
        Byte byteValue = [num unsignedCharValue];
        [dataBytes appendBytes:&byteValue length:sizeof(Byte)];
    }
    NSString *commandString = [mk_fitpoloAdopter hexStringFromData:dataBytes];
    
    [self addReadTaskWithTaskID:mk_getSleep
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
        const uint8_t *byteArray = data.bytes;
        int sitAlertSwitch = (int)byteArray[0];
        NSData *startTime = [data subdataWithRange:NSMakeRange(1, 2)];
        NSString *startHexString = [mk_fitpoloAdopter hexStringFromData:startTime];
        unsigned int startTimeValue = strtoul([startHexString UTF8String], NULL, 16);
        
        NSData *endTime = [data subdataWithRange:NSMakeRange(3, 2)];
        NSString *endHexString = [mk_fitpoloAdopter hexStringFromData:endTime];
        unsigned int endTimeValue = strtoul([endHexString UTF8String], NULL, 16);
        
        NSArray *resultArray = @[@(sitAlertSwitch), @(startTimeValue), @(endTimeValue),];
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
// 时间格式设置 0x03
+ (void)setDateTimeFormatWithsucBlock:(int)timeFormat
                           dateFormat:(int)dateFormat
                             timeZone:(int)timeZone
                             sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                          failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    NSMutableArray<NSNumber *> *dataList = [NSMutableArray array];
    [dataList addObject:@((Byte)(timeFormat & 0xFF))]; //时间格式
    [dataList addObject:@((Byte)(dateFormat & 0xFF))]; //日期格式
    [dataList addObject:@((Byte)(timeZone & 0xFF))]; //整数时区
    NSUInteger dataLength = dataList.count;
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(5 + dataLength)];
    [byteList addObject:@(mk_setting)];
    [byteList addObject:@(0x03)]; //orderType
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
    
    [self addReadTaskWithTaskID:mk_setDateTimeFormat
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
        NSString *value = [content substringWithRange:NSMakeRange(11, 1)];
        NSLog(@"时间格式设置状态%@",value);
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
// 时间格式获取 0x03
+ (void)getDateTimeFormatWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                          failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0x04)];
    [byteList addObject:@(mk_getSetting)];
    [byteList addObject:@(0x03)]; //orderType
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0xFF)];
    // 转换为字节数组
    NSMutableData *dataBytes = [NSMutableData dataWithCapacity:byteList.count];
    for (NSNumber *num in byteList) {
        Byte byteValue = [num unsignedCharValue];
        [dataBytes appendBytes:&byteValue length:sizeof(Byte)];
    }
    NSString *commandString = [mk_fitpoloAdopter hexStringFromData:dataBytes];
    
    [self addReadTaskWithTaskID:mk_getDateTimeFormat
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
        const uint8_t *byteArray = data.bytes;
        int timeFormat = (int)byteArray[0];
        int dateFormat = (int)byteArray[1];
        int timeZone = (int)byteArray[2];
        
        NSArray *resultArray = @[@(timeFormat), @(dateFormat), @(timeZone),];
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
// 达标提醒设置 0x0b
+ (void)setStandardAlertWithsucBlock:(int)toggle
                            sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                         failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    NSMutableArray<NSNumber *> *dataList = [NSMutableArray array];
    [dataList addObject:@((Byte)(toggle & 0xFF))]; //开关
    NSUInteger dataLength = dataList.count;
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(5 + dataLength)];
    [byteList addObject:@(mk_setting)];
    [byteList addObject:@(0x0b)]; //orderType
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
    
    [self addReadTaskWithTaskID:mk_setStandardAlert
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
        NSString *value = [content substringWithRange:NSMakeRange(11, 1)];
        NSLog(@"达标提醒设置状态%@",value);
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
// 达标提醒获取 0x0b
+ (void)getStandardAlertWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                          failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0x04)];
    [byteList addObject:@(mk_getSetting)];
    [byteList addObject:@(0x0b)]; //orderType
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0xFF)];
    // 转换为字节数组
    NSMutableData *dataBytes = [NSMutableData dataWithCapacity:byteList.count];
    for (NSNumber *num in byteList) {
        Byte byteValue = [num unsignedCharValue];
        [dataBytes appendBytes:&byteValue length:sizeof(Byte)];
    }
    NSString *commandString = [mk_fitpoloAdopter hexStringFromData:dataBytes];
    
    [self addReadTaskWithTaskID:mk_getStandardAlert
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
        const uint8_t *byteArray = data.bytes;
        NSString *toggle = [NSString stringWithFormat:@"%d", (int)byteArray[0]];
        
        NSDictionary *dic = @{
            @"msg":@"success",
            @"code":@"1",
            @"result":toggle,
        };
        if (sucBlock) {
            sucBlock(dic);
        }
    }
                      failBlock:failedBlock];
}
// 省电模式设置 0x10
+ (void)setPowerSaveWithsucBlock:(int)toggle
                        sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                     failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    NSMutableArray<NSNumber *> *dataList = [NSMutableArray array];
    [dataList addObject:@((Byte)(toggle & 0xFF))]; //开关
    NSUInteger dataLength = dataList.count;
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(5 + dataLength)];
    [byteList addObject:@(mk_setting)];
    [byteList addObject:@(0x10)]; //orderType
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
    
    [self addReadTaskWithTaskID:mk_setPowerSave
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
        NSString *value = [content substringWithRange:NSMakeRange(11, 1)];
        NSLog(@"省电模式设置状态%@",value);
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
// 省电模式获取 0x10
+ (void)getPowerSaveWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                     failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0x04)];
    [byteList addObject:@(mk_getSetting)];
    [byteList addObject:@(0x10)]; //orderType
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0xFF)];
    // 转换为字节数组
    NSMutableData *dataBytes = [NSMutableData dataWithCapacity:byteList.count];
    for (NSNumber *num in byteList) {
        Byte byteValue = [num unsignedCharValue];
        [dataBytes appendBytes:&byteValue length:sizeof(Byte)];
    }
    NSString *commandString = [mk_fitpoloAdopter hexStringFromData:dataBytes];
    
    [self addReadTaskWithTaskID:mk_getPowerSave
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
        const uint8_t *byteArray = data.bytes;
        NSString *toggle = [NSString stringWithFormat:@"%d", (int)byteArray[0]];
        
        NSDictionary *dic = @{
            @"msg":@"success",
            @"code":@"1",
            @"result":toggle,
        };
        if (sucBlock) {
            sucBlock(dic);
        }
    }
                      failBlock:failedBlock];
}
// 睡眠算法设置 0x13
+ (void)setSleepMonitorWithsucBlock:(int)accuracyToggle
                      breatheToggle:(int)breatheToggle
                           sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                        failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    NSMutableArray<NSNumber *> *dataList = [NSMutableArray array];
    [dataList addObject:@((Byte)(accuracyToggle & 0xFF))]; //睡眠高精度监测开关
    [dataList addObject:@((Byte)(breatheToggle & 0xFF))]; //睡眠呼吸质量监测开关
    NSUInteger dataLength = dataList.count;
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(5 + dataLength)];
    [byteList addObject:@(mk_setting)];
    [byteList addObject:@(0x13)]; //orderType
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
    
    [self addReadTaskWithTaskID:mk_setSleepMonitor
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
        NSString *value = [content substringWithRange:NSMakeRange(11, 1)];
        NSLog(@"睡眠算法设置状态%@",value);
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
// 睡眠算法获取 0x13
+ (void)getSleepMonitorWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                        failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock{
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0x04)];
    [byteList addObject:@(mk_getSetting)];
    [byteList addObject:@(0x13)]; //orderType
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(0xFF)];
    // 转换为字节数组
    NSMutableData *dataBytes = [NSMutableData dataWithCapacity:byteList.count];
    for (NSNumber *num in byteList) {
        Byte byteValue = [num unsignedCharValue];
        [dataBytes appendBytes:&byteValue length:sizeof(Byte)];
    }
    NSString *commandString = [mk_fitpoloAdopter hexStringFromData:dataBytes];
    
    [self addReadTaskWithTaskID:mk_getSleepMonitor
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
        const uint8_t *byteArray = data.bytes;
        int accuracyToggle = (int)byteArray[0];
        int breatheToggle = (int)byteArray[1];
        
        NSArray *resultArray = @[@(accuracyToggle), @(breatheToggle)];
        NSLog(@"睡眠算法设置状态resultArray==》%@",resultArray);
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

#pragma mark - other mothed
+ (NSMutableArray<NSNumber *>*) notifyData2List: (id <MKNotifyTypeProtocol>)protocol {
    NSMutableArray<NSNumber *> *dataList = [NSMutableArray array];
    [dataList addObject:@((Byte)(protocol.common & 0xFF))];
    [dataList addObject:@((Byte)(protocol.facebook & 0xFF))];
    [dataList addObject:@((Byte)(protocol.instagram & 0xFF))];
    [dataList addObject:@((Byte)(protocol.kakaotalk & 0xFF))];
    [dataList addObject:@((Byte)(protocol.line & 0xFF))];
    [dataList addObject:@((Byte)(protocol.linkedin & 0xFF))];
    [dataList addObject:@((Byte)(protocol.SMS & 0xFF))];
    [dataList addObject:@((Byte)(protocol.QQ & 0xFF))];
    [dataList addObject:@((Byte)(protocol.twitter & 0xFF))];
    [dataList addObject:@((Byte)(protocol.viber & 0xFF))];
    [dataList addObject:@((Byte)(protocol.vkontaket & 0xFF))];
    [dataList addObject:@((Byte)(protocol.whatsapp & 0xFF))];
    [dataList addObject:@((Byte)(protocol.wechat & 0xFF))];
    [dataList addObject:@((Byte)(protocol.other1 & 0xFF))];
    [dataList addObject:@((Byte)(protocol.other2 & 0xFF))];
    [dataList addObject:@((Byte)(protocol.other3 & 0xFF))];
    
    NSMutableArray<NSNumber *> *list = [NSMutableArray array];
    uint8_t byte1 = 0;
    uint8_t byte2 = 0;

    for (NSInteger i = dataList.count - 1; i >= 0; i--) {
        NSInteger value = [dataList[i] integerValue];

        if (i < 8) {
            // 设置 byte1 的比特位
            byte1 = (byte1 << 1) | value;
        } else {
            // 设置 byte2 的比特位
            byte2 = (byte2 << 1) | value;
        }
    }

    [list addObject:@(byte2)];
    [list addObject:@(byte1)];
    
    NSLog(@"Byte 2: %@", [self binaryStringForByte:byte2]);
    NSLog(@"Byte 1: %@", [self binaryStringForByte:byte1]);
    
    NSLog(@"list====: %@", list);
    return [list copy]; // 返回不可变数组
}
+ (NSString *)binaryStringForByte:(uint8_t)byte {
    NSMutableString *binaryString = [NSMutableString stringWithCapacity:8];
    for (NSInteger i = 7; i >= 0; i--) {
        [binaryString appendString:((byte & (1 << i)) ? @"1" : @"0")];
    }
    return binaryString;
}
#pragma mark -
+ (void)addReadTaskWithTaskID:(mk_taskOperationID)taskID
                     resetNum:(BOOL)resetNum
                commandString:(NSString *)commandString
                     sucBlock:(mk_communicationSuccessBlock)sucBlock
                    failBlock:(mk_communicationFailedBlock)failBlock{
    CBCharacteristic *character = connectedPeripheral.readData;
    [currentCentral addTaskWithTaskID:taskID
                             resetNum:resetNum
                          commandData:commandString
                       characteristic:character
                         successBlock:sucBlock
                         failureBlock:failBlock];
}
@end
