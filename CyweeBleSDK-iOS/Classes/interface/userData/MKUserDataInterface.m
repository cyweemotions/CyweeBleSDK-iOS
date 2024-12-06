//
//  MKUserDataInterface.m
//  MKFitpoloUserData
//
//  Created by aa on 2019/1/2.
//  Copyright © 2019 MK. All rights reserved.
//

#import "MKUserDataInterface.h"
#import "mk_fitpoloDefines.h"
#import "mk_fitpoloCentralManager.h"
#import "MKUserDataInterfaceAdopter.h"
#import "mk_fitpoloAdopter.h"
#import "CBPeripheral+mk_fitpolo701.h"
#import "CBPeripheral+mk_fitpoloCurrent.h"
#import "mk_fitpoloTaskOperation.h"
#import "MKSportDataModel.h"

#define connectedPeripheral (currentCentral.connectedPeripheral)
#define currentCentral ([mk_fitpoloCentralManager sharedInstance])

typedef NS_ENUM(NSInteger, readDataWithTimeStamp) {
    readStepDataWithTimeStamp,         //时间戳请求计步数据
    readSleepIndexDataWithTimeStamp,   //时间戳请求睡眠index数据
    readSleepRecordDataWithTimeStamp,  //时间戳请求睡眠record数据
    readHeartRateDataWithTimeStamp,    //时间戳请求心率数据
};

@implementation MKUserDataInterface

+ (void)readStepDataWithTimeStamp:(id <MKReadDeviceDataTimeProtocol>)protocol
                         sucBlock:(mk_userDataInterfaceSucBlock)sucBlock
                      failedBlock:(mk_userDataInterfaceFailedBlock)failedBlock{
    if (![MKUserDataInterfaceAdopter validTimeProtocol:protocol]) {
        [mk_fitpoloAdopter operationParamsErrorBlock:failedBlock];
        return;
    }
    NSString *hexTime = [MKUserDataInterfaceAdopter getTimeString:protocol];
    if (!mk_validStr(hexTime)) {
        [mk_fitpoloAdopter operationParamsErrorBlock:failedBlock];
        return;
    }
    if (currentCentral.deviceType == mk_fitpolo701) {
        [self read701PeripheralData:hexTime dataType:readStepDataWithTimeStamp sucBlock:^(id returnData) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                NSArray *dataList = [MKUserDataInterfaceAdopter fetchStepModelList:returnData[@"result"]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (sucBlock) {
                        sucBlock(dataList);
                    }
                });
            });
        } failBlock:failedBlock];
        return;
    }
    [self readCurrentPeripheralStepData:hexTime sucBlock:^(id returnData) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSArray *dataList = [MKUserDataInterfaceAdopter fetchStepModelList:returnData[@"result"]];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (sucBlock) {
                    sucBlock(dataList);
                }
            });
        });
    } failBlock:failedBlock];
}

+ (void)readSleepDataWithTimeStamp:(id <MKReadDeviceDataTimeProtocol>)protocol
                          sucBlock:(mk_userDataInterfaceSucBlock)sucBlock
                       failedBlock:(mk_userDataInterfaceFailedBlock)failedBlock{
    if (![MKUserDataInterfaceAdopter validTimeProtocol:protocol]) {
        [mk_fitpoloAdopter operationParamsErrorBlock:failedBlock];
        return;
    }
    NSString *hexTime = [MKUserDataInterfaceAdopter getTimeString:protocol];
    if (!mk_validStr(hexTime)) {
        [mk_fitpoloAdopter operationParamsErrorBlock:failedBlock];
        return;
    }
    dispatch_async(dispatch_queue_create("readSleepDataQueue", DISPATCH_QUEUE_SERIAL), ^{
        NSArray *indexList = [self fetchSleepIndexData:hexTime];
        if (!indexList) {
            [mk_fitpoloAdopter operationRequestDataErrorBlock:failedBlock];
            return ;
        }
        if (indexList.count == 0) {
            mk_fitpolo_main_safe(^{
                if (sucBlock) {
                    sucBlock(@[]);
                }
            });
            return;
        }
        NSArray *recordList = [self fetchSleepRecordData:hexTime];
        if (!mk_validArray(recordList)) {
            [mk_fitpoloAdopter operationRequestDataErrorBlock:failedBlock];
            return;
        }
        NSArray *sleepList = [MKUserDataInterfaceAdopter getSleepDataList:indexList recordList:recordList];
        NSArray *dataList = [MKUserDataInterfaceAdopter fetchSleepModelList:sleepList];
        mk_fitpolo_main_safe(^{
            if (sucBlock) {
                sucBlock(dataList);
            }
        });
    });
}

+ (void)readHeartDataWithTimeStamp:(id <MKReadDeviceDataTimeProtocol>)protocol
                          sucBlock:(mk_userDataInterfaceSucBlock)sucBlock
                       failedBlock:(mk_userDataInterfaceFailedBlock)failedBlock{
    if (![MKUserDataInterfaceAdopter validTimeProtocol:protocol]) {
        [mk_fitpoloAdopter operationParamsErrorBlock:failedBlock];
        return;
    }
    NSString *hexTime = [MKUserDataInterfaceAdopter getTimeString:protocol];
    if (!mk_validStr(hexTime)) {
        [mk_fitpoloAdopter operationParamsErrorBlock:failedBlock];
        return;
    }
    dispatch_async(dispatch_queue_create("readHeartRateDataQueue", 0), ^{
        NSArray *list = [self fetchHeartRate:hexTime];
        NSDictionary *dataDic = [MKUserDataInterfaceAdopter fetchHeartModelList:list];
        mk_fitpolo_main_safe(^{
            if (sucBlock) {
                sucBlock(dataDic);
            }
        });
    });
}

#pragma mark - 705、706、707

+ (void)readUserDataWithSucBlock:(mk_userDataInterfaceSucBlock)sucBlock
                     failedBlock:(mk_userDataInterfaceFailedBlock)failedBlock{
    if (currentCentral.deviceType == mk_fitpolo701) {
        [mk_fitpoloAdopter operationUnsupportCommandErrorBlock:failedBlock];
        return;
    }
    [self addUserReadTaskWithTaskID:mk_readUserInfoOperation
                       resetNum:NO
                  commandString:@"b00e00"
                       sucBlock:sucBlock
                      failBlock:failedBlock];
}

+ (void)readMovingTargetWithSucBlock:(mk_userDataInterfaceSucBlock)sucBlock
                         failedBlock:(mk_userDataInterfaceFailedBlock)failedBlock{
    if (currentCentral.deviceType == mk_fitpolo701) {
        [mk_fitpoloAdopter operationUnsupportCommandErrorBlock:failedBlock];
        return;
    }
    [self addUserReadTaskWithTaskID:mk_readMovingTargetOperation
                       resetNum:NO
                  commandString:@"b00600"
                       sucBlock:sucBlock
                      failBlock:failedBlock];
}

+ (void)readSportDataWithTimeStamp:(id <MKReadDeviceDataTimeProtocol>)protocol
                          sucBlock:(mk_userDataInterfaceSucBlock)sucBlock
                       failedBlock:(mk_userDataInterfaceFailedBlock)failedBlock {
    if (currentCentral.deviceType == mk_fitpolo701) {
        [mk_fitpoloAdopter operationUnsupportCommandErrorBlock:failedBlock];
        return;
    }
    if (![MKUserDataInterfaceAdopter validTimeProtocol:protocol]) {
        [mk_fitpoloAdopter operationParamsErrorBlock:failedBlock];
        return;
    }
    NSString *hexTime = [MKUserDataInterfaceAdopter getTimeString:protocol];
    if (!mk_validStr(hexTime)) {
        [mk_fitpoloAdopter operationParamsErrorBlock:failedBlock];
        return;
    }
    NSString *commandString = [@"b01605" stringByAppendingString:hexTime];
    [currentCentral addNeedPartOfDataTaskWithTaskID:mk_readSportsDataOperation commandData:commandString characteristic:connectedPeripheral.readData successBlock:^(id returnData) {
        mk_fitpolo_main_safe(^{
            if (sucBlock) {
                sucBlock(returnData);
            }
        });
    } failureBlock:failedBlock];
}

+ (void)readSportHeartRateDataWithTimeStamp:(id <MKReadDeviceDataTimeProtocol>)protocol
                                   sucBlock:(mk_userDataInterfaceSucBlock)sucBlock
                                failedBlock:(mk_userDataInterfaceFailedBlock)failedBlock {
    if (currentCentral.deviceType == mk_fitpolo701) {
        [mk_fitpoloAdopter operationUnsupportCommandErrorBlock:failedBlock];
        return;
    }
    if (![MKUserDataInterfaceAdopter validTimeProtocol:protocol]) {
        [mk_fitpoloAdopter operationParamsErrorBlock:failedBlock];
        return;
    }
    NSString *hexTime = [MKUserDataInterfaceAdopter getTimeString:protocol];
    if (!mk_validStr(hexTime)) {
        [mk_fitpoloAdopter operationParamsErrorBlock:failedBlock];
        return;
    }
    NSString *commandString = [@"b60405" stringByAppendingString:hexTime];
    [currentCentral addNeedPartOfDataTaskWithTaskID:mk_readSportHeartDataOperation commandData:commandString characteristic:connectedPeripheral.readData successBlock:^(id returnData) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSArray *dataList = returnData[@"result"];
            NSMutableArray *tempList = [NSMutableArray array];
            for (NSDictionary *dic in dataList) {
                NSArray *heartList = dic[@"heartList"];
                if (mk_validArray(heartList)) {
                    [tempList addObjectsFromArray:heartList];
                }
            }
            NSDictionary *dataDic = [MKUserDataInterfaceAdopter fetchHeartModelList:tempList];
            mk_fitpolo_main_safe(^{
                if (sucBlock) {
                    sucBlock(dataDic);
                }
            });
        });
    } failureBlock:failedBlock];
}

#pragma mark - 706、707
+ (void)readStepIntervalDataWithTimeStamp:(id <MKReadDeviceDataTimeProtocol>)protocol
                                 sucBlock:(mk_userDataInterfaceSucBlock)sucBlock
                              failedBlock:(mk_userDataInterfaceFailedBlock)failedBlock {
    if (currentCentral.deviceType == mk_fitpolo701
        || currentCentral.deviceType == mk_fitpolo705) {
        [mk_fitpoloAdopter operationUnsupportCommandErrorBlock:failedBlock];
        return;
    }
    if (![MKUserDataInterfaceAdopter validTimeProtocol:protocol]) {
        [mk_fitpoloAdopter operationParamsErrorBlock:failedBlock];
        return;
    }
    NSString *hexTime = [MKUserDataInterfaceAdopter getTimeString:protocol];
    if (!mk_validStr(hexTime)) {
        [mk_fitpoloAdopter operationParamsErrorBlock:failedBlock];
        return;
    }
    NSString *commandString = [NSString stringWithFormat:@"%@%@",@"b40505",hexTime];
    [currentCentral addNeedPartOfDataTaskWithTaskID:mk_readStepIntervalDataOperation
                                        commandData:commandString
                                     characteristic:connectedPeripheral.otaData
                                       successBlock:^(id returnData) {
                                           dispatch_async(dispatch_get_global_queue(0, 0), ^{
                                               NSArray *dataList = returnData[@"result"];
                                               NSMutableArray *tempList = [NSMutableArray array];
                                               for (NSDictionary *dic in dataList) {
                                                   NSArray *stepList = dic[@"stepList"];
                                                   if (mk_validArray(stepList)) {
                                                       [tempList addObjectsFromArray:stepList];
                                                   }
                                               }
                                               mk_fitpolo_main_safe(^{
                                                   if (sucBlock) {
                                                       sucBlock(tempList);
                                                   }
                                               });
                                           });
                                       }
                                       failureBlock:failedBlock];
}


+ (void)syncStepsWithsucBlock:(mk_userDataInterfaceSucBlock)sucBlock
                  failedBlock:(mk_userDataInterfaceFailedBlock)failedBlock{

    [currentCentral addNeedPartOfDataTaskWithTaskID:mk_syncSteps
                                        commandData:@"ff0e0302090107e8081c00000000ffff"
                                     characteristic:connectedPeripheral.updateNotify
                                       successBlock:sucBlock
                                       failureBlock:failedBlock];
}


#pragma mark - 数据同步
// 步数同步 0x02
+ (void)syncStepsDataWithsucBlock:(int)year
                            month:(int)month
                              day:(int)day
                             type:(int)type
                         sucBlock:(mk_userDataInterfaceSucBlock)sucBlock
                      failedBlock:(mk_userDataInterfaceFailedBlock)failedBlock{
    
    NSString *commandString = [MKUserDataInterfaceAdopter formatSyncStepsCommandString:year month:month day:day type:type];
//    NSLog(@"步数commandString%@",commandString);
    __block NSInteger index = 1;
    __block NSString *result = @"";
    
    [currentCentral addNeedResetNumTaskWithTaskID:mk_syncSteps
                                           number:1
                                      commandData:commandString
                                   characteristic:connectedPeripheral.updateNotify
                                     successBlock:^(id returnData) {
        NSData *content = [mk_fitpoloAdopter stringToData:returnData[@"result"][@"result"]];
        if ([content length] == 0) {
            [currentCentral cancelOpration:mk_syncSteps];
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
        NSData *stepsData = [content subdataWithRange:NSMakeRange(5, dataLength)];
        if (type == 0) { //当前数据
            NSLog(@"步数同步数据%@",returnData);
            NSData *stepsResult = [stepsData subdataWithRange:NSMakeRange(1, dataLength-1)];
            NSString *stepsDataHexString = [mk_fitpoloAdopter hexStringFromData:stepsResult];
            NSString *stepsDataString = [mk_fitpoloAdopter stringFromHexString:stepsDataHexString];
            // 将字符串转换为 NSData，使用 NSUTF8StringEncoding 编码
            NSData *jsonData = [stepsDataString dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *resultData = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
            NSLog(@"步数同步数据====resultData=====%@",stepsDataString);
//            NSLog(@"Parsed JSON Object: %@", resultData);
            //销毁任务
            [currentCentral cancelOpration:mk_syncSteps];
            NSDictionary *dic = @{
                                  @"msg":@"success",
                                  @"code":@"1",
                                  @"result":resultData,
                                  };
            if (sucBlock) {
                sucBlock(dic);
            }
        } else { //当天记录数据
            NSInteger packType = (int)bytes[6];
            NSInteger packIndex = (int)bytes[7];
            NSLog(@"步数同步数据====stepsData.length=====%d",stepsData.length);
            if (stepsData.length <= 8) {
                [currentCentral cancelOpration:mk_syncSteps];
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
            NSData *stepsResult = [stepsData subdataWithRange:NSMakeRange(8, stepsData.length-8)];
            if(packIndex == index){
                NSString *stepsDataHexString = [mk_fitpoloAdopter hexStringFromData:stepsResult];
                NSString *stepsDataString = [mk_fitpoloAdopter stringFromHexString:stepsDataHexString];
                result = [result stringByAppendingString:stepsDataString];
//                NSLog(@"步数同步数据====result=====%@", result);
                if (packType == 2 || packType == 0) {
                    //最终数据数组
                    NSMutableArray *dataList = [NSMutableArray array];
                    //1、把result分割
                    NSMutableArray *dataArray = [result componentsSeparatedByString:@"\n"];
                    [dataArray removeLastObject];
//                    NSLog(@"步数同步数据====linesArray=====%@", dataArray);
                    //2、遍历把[ST]替换""，
                    for (NSInteger i = 0; i < [dataArray count]; i++) {
                        if(dataArray[i] == @"") return;
                        NSString *itemString = [dataArray[i] stringByReplacingOccurrencesOfString:@"[ST]" withString:@""];
                        NSArray *itemArray = [itemString componentsSeparatedByString:@","];
                        //3、把数据挨个传入一个NSDictionary
                        NSDictionary *itemMap = @{
                                              @"step":itemArray[0],
                                              @"distance":itemArray[1],
                                              @"calorie":itemArray[2],
                                              @"datetime":itemArray[3],
                                              };
//                        NSLog(@"itemMap%@", itemMap);
                        NSString *keyStr = [NSString stringWithFormat:@"%ld", (long)i];
                        //4、把NSDictionary都传入最终数据数组
                        [dataList addObject:itemMap];
                    }
                    NSLog(@"步数同步数据====dataList=====%@", dataList);
                    ///解析到最后一包触发
                    [currentCentral cancelOpration:mk_syncSteps];
                    NSDictionary *dic = @{
                                          @"msg":@"success",
                                          @"code":@"1",
                                          @"result":dataList,
                                          };
                    if (sucBlock) {
                        sucBlock(dic);
                    }
                }
                index ++;
            }
        }
    }
                                     failureBlock:failedBlock];

}
// 心率同步 0x03
+ (void)syncHeartRateDataWithsucBlock:(int)year
                            month:(int)month
                              day:(int)day
                         sucBlock:(mk_userDataInterfaceSucBlock)sucBlock
                      failedBlock:(mk_userDataInterfaceFailedBlock)failedBlock{
    
    NSString *commandString = [MKUserDataInterfaceAdopter formatDataPushCommandString:3
                                                                                 year:year
                                                                                month:month
                                                                                  day:day];
//    NSLog(@"心率commandString%@",commandString);
    __block NSInteger index = 1;
    __block NSString *result = @"";
    
    [currentCentral addNeedResetNumTaskWithTaskID:mk_syncHeartRate
                                           number:2
                                      commandData:commandString
                                   characteristic:connectedPeripheral.updateNotify
                                     successBlock:^(id returnData) {
        NSData *content = [mk_fitpoloAdopter stringToData:returnData[@"result"][@"result"]];
        if ([content length] == 0) {
            [currentCentral cancelOpration:mk_syncHeartRate];
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
        if (dataLength <= 8) {
            [currentCentral cancelOpration:mk_syncHeartRate];
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
        NSData *heartRateData = [content subdataWithRange:NSMakeRange(5, dataLength)];
        NSInteger packType = (int)bytes[6];
        NSInteger packIndex = (int)bytes[7];
        NSData *heartRateResult = [heartRateData subdataWithRange:NSMakeRange(8, heartRateData.length-8)];
        if(packIndex == index){
            NSString *heartRateDataHexString = [mk_fitpoloAdopter hexStringFromData:heartRateResult];
            NSString *heartRateDataString = [mk_fitpoloAdopter stringFromHexString:heartRateDataHexString];
            result = [result stringByAppendingString:heartRateDataString];
//            NSLog(@"心率同步数据====result=====%@", result);
            if (packType == 2 || packType == 0) {
                //最终数据数组
                NSMutableArray *dataList = [NSMutableArray array];
                //1、把result分割
                NSMutableArray *dataArray = [result componentsSeparatedByString:@"\n"];
                [dataArray removeLastObject];
//                NSLog(@"心率同步数据====linesArray=====%@", dataArray);
                //2、遍历把[HR]替换""，
                for (NSInteger i = 0; i < [dataArray count]; i++) {
                    if(dataArray[i] == @"") return;
                    NSString *itemString = [dataArray[i] stringByReplacingOccurrencesOfString:@"[HR]" withString:@""];
                    NSArray *itemArray = [itemString componentsSeparatedByString:@","];
                    //3、把数据挨个传入一个NSDictionary
                    NSDictionary *itemMap = @{
                                          @"heartRate":itemArray[0],
                                          @"datetime":itemArray[1],
                                          };
//                    NSLog(@"itemMap%@", itemMap);
                    NSString *keyStr = [NSString stringWithFormat:@"%ld", (long)i];
                    //4、把NSDictionary都传入最终数据数组
                    [dataList addObject:itemMap];
                }
                NSLog(@"心率同步数据====dataList=====%@", dataList);
                ///解析到最后一包触发
                [currentCentral cancelOpration:mk_syncHeartRate];
                NSDictionary *dic = @{
                                      @"msg":@"success",
                                      @"code":@"1",
                                      @"result":dataList,
                                      };
                if (sucBlock) {
                    sucBlock(dic);
                }
            }
            index ++;
        }
    }
                                     failureBlock:failedBlock];
}

// 血氧同步 0x04
+ (void)syncBloodOxygenDataWithsucBlock:(int)year
                            month:(int)month
                              day:(int)day
                         sucBlock:(mk_userDataInterfaceSucBlock)sucBlock
                      failedBlock:(mk_userDataInterfaceFailedBlock)failedBlock{
    
    NSString *commandString = [MKUserDataInterfaceAdopter formatDataPushCommandString:4
                                                                                 year:year
                                                                                month:month
                                                                                  day:day];
//    NSLog(@"血氧commandString%@",commandString);
    __block NSInteger index = 1;
    __block NSString *result = @"";
    [currentCentral addNeedResetNumTaskWithTaskID:mk_syncBloodOxygen
                                           number:1
                                      commandData:commandString
                                   characteristic:connectedPeripheral.updateNotify
                                     successBlock:^(id returnData) {
        NSLog(@"血氧同步数据====returnData=====%@", returnData);
        NSData *content = [mk_fitpoloAdopter stringToData:returnData[@"result"][@"result"]];
        NSLog(@"血氧同步数据====content=====%@", content);
        if ([content length] == 0) {
            [currentCentral cancelOpration:mk_syncBloodOxygen];
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
        if (dataLength <= 8) {
            [currentCentral cancelOpration:mk_syncBloodOxygen];
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
        NSData *bloodOxygenData = [content subdataWithRange:NSMakeRange(5, dataLength)];
        NSInteger packType = (int)bytes[6];
        NSInteger packIndex = (int)bytes[7];
        NSData *bloodOxygenResult = [bloodOxygenData subdataWithRange:NSMakeRange(8, bloodOxygenData.length-8)];
        if(packIndex == index){
            NSString *bloodOxygenDataHexString = [mk_fitpoloAdopter hexStringFromData:bloodOxygenResult];
            NSString *bloodOxygenDataString = [mk_fitpoloAdopter stringFromHexString:bloodOxygenDataHexString];
            result = [result stringByAppendingString:bloodOxygenDataString];
//            NSLog(@"血氧同步数据====result=====%@", result);
            if (packType == 2 || packType == 0) {
                ///解析到最后一包触发
                [currentCentral cancelOpration:mk_syncBloodOxygen];
                //最终数据数组
                NSMutableArray *dataList = [NSMutableArray array];
                //1、把result分割
                NSMutableArray *dataArray = [result componentsSeparatedByString:@"\n"];
                [dataArray removeLastObject];
//                NSLog(@"血氧同步数据====linesArray=====%@", dataArray);
                //2、遍历把[BO]替换""，
                for (NSInteger i = 0; i < [dataArray count]; i++) {
                    if(dataArray[i] == @"") return;
                    NSString *itemString = [dataArray[i] stringByReplacingOccurrencesOfString:@"[BO]" withString:@""];
                    NSArray *itemArray = [itemString componentsSeparatedByString:@","];
                    //3、把数据挨个传入一个NSDictionary
                    NSDictionary *itemMap = @{
                                          @"bloodOxygen":itemArray[0],
                                          @"datetime":itemArray[1],
                                          };
//                    NSLog(@"itemMap%@", itemMap);
                    //4、把NSDictionary都传入最终数据数组
                    [dataList addObject:itemMap];
                }
                NSLog(@"血氧同步数据====dataList=====%@", dataList);
                NSDictionary *dic = @{
                                      @"msg":@"success",
                                      @"code":@"1",
                                      @"result":dataList,
                                      };
                if (sucBlock) {
                    sucBlock(dic);
                }
            }
            index ++;
        }
    }
                                     failureBlock:failedBlock];
}
// 运动同步 0x06
+ (void)syncSportDataWithsucBlock:(int)fileIndex
                             year:(int)year
                            month:(int)month
                              day:(int)day
                         sucBlock:(mk_userDataInterfaceSucBlock)sucBlock
                      failedBlock:(mk_userDataInterfaceFailedBlock)failedBlock{
    
    NSString *commandString = [MKUserDataInterfaceAdopter formatDataPushCommandString:6
                                                                                 year:year
                                                                                month:month
                                                                                  day:day];
    NSLog(@"运动commandString%@",commandString);
    __block NSInteger sportDataCount = 0;// 运动记录条数
    __block NSInteger location = fileIndex;
    __block NSInteger index = 1;
    __block NSMutableArray *result = [NSMutableArray array];
    __block NSString *sportItem = @"";
    [currentCentral addNeedResetNumTaskWithTaskID:mk_syncSportData
                                           number:2
                                      commandData:commandString
                                   characteristic:connectedPeripheral.updateNotify
                                     successBlock:^(id returnData) {
        NSData *content = [mk_fitpoloAdopter stringToData:returnData[@"result"][@"result"]];
        NSLog(@"运动content=====》%@",content);
        const uint8_t *bytes = content.bytes;
        int dataLength = (int)bytes[4];
        NSData *sportData = [content subdataWithRange:NSMakeRange(5, dataLength)];
        const uint8_t *sportDatabytes = sportData.bytes;
        NSInteger packType = (int)sportDatabytes[1];
        NSInteger fileLocation = (int)sportDatabytes[2]; // 运动记录条数
        NSInteger packIndex = (int)sportDatabytes[3];
        if(packType == 3 && (dataLength == 3)){
            sportDataCount = fileLocation;
            NSLog(@"文件的个数====%d", fileLocation);
            return;
        }
        if(dataLength <= 5) {
            return;
        }
        NSData *sportResult = [sportData subdataWithRange:NSMakeRange(5, sportData.length-5)];
        if(packIndex == index && fileLocation == location){
            NSString *sportDataString = [mk_fitpoloAdopter transformData:sportResult];
//            NSLog(@"每一包数据%@", sportDataString);
            sportItem = [sportItem stringByAppendingString:sportDataString];
            if (packType == 2 || packType == 0) {
                NSLog(@"运动数据========%@", sportItem);
                [result addObject:sportItem];
                sportItem = @"";
                index = 1;
                location++;
            }
            index ++;
        }
        if (packType == 3) {
            [currentCentral cancelOpration:mk_syncSportData];
            if (sportDataCount == 0) {//没有数据
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
            ///解析到最后一包触发
            NSMutableArray<MKSportDataModel *> *dataSource = [[NSMutableArray alloc] init];
            int sportType = 0;
            for (NSInteger i = 0; i < [result count]; i++) {
                NSString * sportSubStr = result[i];
                NSMutableArray *contents = [sportSubStr componentsSeparatedByString:@"\n"];
                NSMutableArray *sportDetails = [NSMutableArray array];
                for (NSInteger j = 0; j < [contents count]; j++) {
                    NSString *contentItem = contents[j];
                    if ([contentItem hasPrefix:@"[1]"]){
                        NSString *contentStr = [contentItem stringByReplacingOccurrencesOfString:@"[1]" withString:@""];
                        NSRange range = [contentStr rangeOfString:@","];
                        if (range.location != NSNotFound) {
                            NSMutableArray *contentList = [sportSubStr componentsSeparatedByString:@","];
                            sportType = [[contentList lastObject] integerValue];
                        }
                    } else if ([contentItem hasPrefix:@"[2]"]) {
                        NSString *contentStr = [contentItem stringByReplacingOccurrencesOfString:@"[2]" withString:@""];
                        [sportDetails addObject:contentStr];
                    } else if ([contentItem hasPrefix:@"[5]"]) {//一条运动记录结束
                        NSString *contentStr = [contentItem stringByReplacingOccurrencesOfString:@"[5]" withString:@""];
                        MKSportDataModel* sportModel = [MKSportDataModel StringTurnModel:contentStr 
                                                                                    type:sportType sportContent:sportDetails rawData:sportSubStr];
                        [dataSource addObject:sportModel];
                    }
                }
            }
            NSLog(@"运动数据dataSource===%@",dataSource);
            
            NSDictionary *dic = @{
                                  @"msg":@"success",
                                  @"code":@"1",
                                  @"result":dataSource,
                                  };
            if (sucBlock) {
                sucBlock(dic);
            }
        }
    }
                                     failureBlock:failedBlock];
}

//天气同步
+ (void) syncWeatherDataWithsucBlock:(NSString *) weatherData
                            sucBlock:(mk_userDataInterfaceSucBlock)sucBlock
                         failedBlock:(mk_userDataInterfaceFailedBlock)failedBlock{
    
    NSMutableArray<NSNumber *> *dataList = [NSMutableArray array];
    NSString* weatherHexStr = [mk_fitpoloAdopter hexStringFromString:weatherData];
    NSArray<NSNumber *> *weatherArray = [mk_fitpoloAdopter arrayFromHexString:weatherHexStr];
    [dataList addObjectsFromArray:weatherArray];
    NSUInteger dataLength = dataList.count;
    
    NSMutableArray<NSNumber *> *byteList = [NSMutableArray array];
    [byteList addObject:@(0xFF)];
    [byteList addObject:@(5 + dataLength)];
    [byteList addObject:@(mk_dataNotify)];
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
    
    [self addUserReadTaskWithTaskID:mk_syncWeatherData
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
        NSLog(@"天气同步状态%@",value);
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

// 睡眠同步 0x05
+ (void)syncSleepDataWithsucBlock:(int)year
                            month:(int)month
                              day:(int)day
                         sucBlock:(mk_userDataInterfaceSucBlock)sucBlock
                      failedBlock:(mk_userDataInterfaceFailedBlock)failedBlock{
    
    NSString *commandString = [MKUserDataInterfaceAdopter formatDataPushCommandString:5
                                                                                 year:year
                                                                                month:month
                                                                                  day:day];
    NSLog(@"睡眠commandString%@",commandString);
    __block NSInteger index = 1;
    __block NSString *result = @"";
    [currentCentral addNeedResetNumTaskWithTaskID:mk_syncSleepData
                                           number:1
                                      commandData:commandString
                                   characteristic:connectedPeripheral.updateNotify
                                     successBlock:^(id returnData) {
        NSData *content = [mk_fitpoloAdopter stringToData:returnData[@"result"][@"result"]];
        if ([content length] == 0) {
            [currentCentral cancelOpration:mk_syncSleepData];
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
        NSLog(@"睡眠同步数据====content=====%@", content);
        const uint8_t *bytes = content.bytes;
        int dataLength = (int)bytes[4];
        if (dataLength <= 8) {
            [currentCentral cancelOpration:mk_syncSleepData];
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
        NSLog(@"睡眠同步数据====dataLength=====%d", dataLength);
        NSData *sleepData = [content subdataWithRange:NSMakeRange(5, dataLength)];
        NSInteger packType = (int)bytes[6];
        NSInteger packIndex = (int)bytes[7];
        NSData *sleepResult = [sleepData subdataWithRange:NSMakeRange(8, sleepData.length-8)];
        if(packIndex == index){
            NSString *sleepDataHexString = [mk_fitpoloAdopter hexStringFromData:sleepResult];
            NSString *sleepDataString = [mk_fitpoloAdopter stringFromHexString:sleepDataHexString];
            result = [result stringByAppendingString:sleepDataString];
            NSLog(@"睡眠同步数据====result=====%@", result);
            if (packType == 2 || packType == 0) {
                ///解析到最后一包触发
                [currentCentral cancelOpration:mk_syncSleepData];
                //最终数据数组
                NSMutableArray *dataList = [NSMutableArray array];
                //1、把result分割
                NSMutableArray *dataArray = [result componentsSeparatedByString:@"\n"];
                [dataArray removeLastObject];
                NSString* sleepRating = @""; //睡眠评分
                NSString* deepSleepContinuity = @""; //深睡连续性
                NSString* respiratoryQuality = @"";//睡眠呼吸质量 255为未开启睡眠呼吸质量开关
//                NSLog(@"睡眠同步数据====linesArray=====%@", dataArray);
                //2、遍历把[SL]、[NA]替换""，
                for (NSInteger i = 0; i < [dataArray count]; i++) {
                    if(dataArray[i] == @"") return;
                    NSMutableString *itemString = [NSMutableString string];
                    NSMutableString *type = [NSMutableString string];
                    if ([dataArray[i] hasPrefix:@"[SL]"]) {
                        itemString = [dataArray[i] stringByReplacingOccurrencesOfString:@"[SL]" withString:@""];
                        type = @"0";
                    } else if([dataArray[i] hasPrefix:@"[NA]"]) {
                        itemString = [dataArray[i] stringByReplacingOccurrencesOfString:@"[NA]" withString:@""];
                        type = @"1";
                    }
                    NSArray *itemArray = [itemString componentsSeparatedByString:@","];
                    NSMutableString *slice = @"0";
                    if(itemArray.count >= 3) {
                        if(itemArray.count > 4) {
                            sleepRating = itemArray[3];
                            deepSleepContinuity = itemArray[4];
                            respiratoryQuality = itemArray[5];
                        }
                        slice = itemArray[2];
                    }
                    //3、把数据挨个传入一个NSDictionary
                    NSDictionary *itemMap = @{
                                          @"type":type,
                                          @"state":itemArray[0],
                                          @"datetime":itemArray[1],
                                          @"slice":slice,
                                          };
//                    NSLog(@"itemMap%@", itemMap);
                    //4、把NSDictionary都传入最终数据数组
                    [dataList addObject:itemMap];
                }
                NSLog(@"睡眠同步数据====dataList=====%@", dataList);
                NSDictionary *sleepResult = @{
                                      @"sleepRating":sleepRating,
                                      @"deepSleepContinuity":deepSleepContinuity,
                                      @"respiratoryQuality":respiratoryQuality,
                                      @"sleepData":dataList,
                                      };
                NSDictionary *dic = @{
                                      @"msg":@"success",
                                      @"code":@"1",
                                      @"result":sleepResult,
                                      };
                if (sucBlock) {
                    sucBlock(dic);
                }
            }
            index ++;
        }
    }
                                     failureBlock:failedBlock];
}
// PAI同步 0x07
+ (void)syncPaiDataWithsucBlock:(int)year
                          month:(int)month
                            day:(int)day
                       sucBlock:(mk_userDataInterfaceSucBlock)sucBlock
                    failedBlock:(mk_userDataInterfaceFailedBlock)failedBlock{
    
    NSString *commandString = [MKUserDataInterfaceAdopter formatDataPushCommandString:7
                                                                                 year:year
                                                                                month:month
                                                                                  day:day];
    NSLog(@"PAIcommandString%@",commandString);
    __block NSInteger index = 1;
    __block NSInteger itemLength = 36;
    __block NSMutableArray<NSNumber *> *result = [NSMutableArray array];
    [currentCentral addNeedResetNumTaskWithTaskID:mk_syncPaiData
                                           number:1
                                      commandData:commandString
                                   characteristic:connectedPeripheral.updateNotify
                                     successBlock:^(id returnData) {
        NSData *content = [mk_fitpoloAdopter stringToData:returnData[@"result"][@"result"]];
        if ([content length] == 0) {
            [currentCentral cancelOpration:mk_syncPaiData];
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
        if (dataLength <= 8) {
            [currentCentral cancelOpration:mk_syncPaiData];
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
        NSData *paiData = [content subdataWithRange:NSMakeRange(5, dataLength)];
        NSInteger packType = (int)bytes[6];
        NSInteger packIndex = (int)bytes[7];
        NSData *paiResult = [paiData subdataWithRange:NSMakeRange(8, paiData.length-8)];
        if(packIndex == index){
            NSString *paiDataHexString = [mk_fitpoloAdopter hexStringFromData:paiResult];
            NSLog(@"PAI同步数据====paiDataHexString=====%@", paiDataHexString);
            NSMutableArray<NSNumber *> *paiDataList = [mk_fitpoloAdopter arrayFromHexString:paiDataHexString];
            [result addObjectsFromArray:paiDataList];
//            NSLog(@"PAI同步数据====result=====%@", result);
            if (packType == 2 || packType == 0) {
                ///解析到最后一包触发
                [currentCentral cancelOpration:mk_syncPaiData];
                //最终数据数组
                NSMutableArray *dataList = [NSMutableArray array];
                int count = (int) (result.count / itemLength);
                NSLog(@"PAI同步数据====count=====%d", count);
                for (NSInteger i=0; i<count; i++) {
                    NSArray *value = [result subarrayWithRange:NSMakeRange(i*itemLength, itemLength)];
                    NSLog(@"PAI同步数据====value=====%@", value);
                    int date = [mk_fitpoloAdopter turnList:[value subarrayWithRange:NSMakeRange(0, 4)]];
                    NSString *dateStr = [NSString stringWithFormat:@"%d", date];
                    int totals = [mk_fitpoloAdopter turnList:[value subarrayWithRange:NSMakeRange(4, 4)]];
                    NSString *totalsStr = [NSString stringWithFormat:@"%d", totals / 1000];
                    int pai = [mk_fitpoloAdopter turnList:[value subarrayWithRange:NSMakeRange(8, 4)]];
                    NSString *paiStr = [NSString stringWithFormat:@"%d", pai / 1000];
                    int low = [mk_fitpoloAdopter turnList:[value subarrayWithRange:NSMakeRange(12, 4)]];
                    NSString *lowStr = [NSString stringWithFormat:@"%d", low / 1000];
                    int medium = [mk_fitpoloAdopter turnList:[value subarrayWithRange:NSMakeRange(16, 4)]];
                    NSString *mediumStr = [NSString stringWithFormat:@"%d", medium / 1000];
                    int high = [mk_fitpoloAdopter turnList:[value subarrayWithRange:NSMakeRange(20, 4)]];
                    NSString *highStr = [NSString stringWithFormat:@"%d", high / 1000];
                    int lowMins = [mk_fitpoloAdopter turnList:[value subarrayWithRange:NSMakeRange(24, 4)]];
                    NSString *lowMinsStr = [NSString stringWithFormat:@"%d", lowMins];
                    int mediumMins = [mk_fitpoloAdopter turnList:[value subarrayWithRange:NSMakeRange(28, 4)]];
                    NSString *mediumMinsStr = [NSString stringWithFormat:@"%d", mediumMins];
                    int highMins = [mk_fitpoloAdopter turnList:[value subarrayWithRange:NSMakeRange(32, 4)]];
                    NSString *highMinsStr = [NSString stringWithFormat:@"%d", highMins];
                    
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:@"yyyyMMdd"];
                    NSDate *dateData = [dateFormatter dateFromString:dateStr];
                    // 获取年月日
                    NSCalendar *calendar = [NSCalendar currentCalendar];
                    NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:dateData];
                    NSString *yearStr = [NSString stringWithFormat:@"%d", components.year];
                    NSString *monthStr = [NSString stringWithFormat:@"%d", components.month];
                    NSString *dayStr = [NSString stringWithFormat:@"%d", components.day];
                    
                    NSDictionary *itemMap = @{
                        @"id":dateStr,
                        @"year":yearStr,
                        @"month":monthStr,
                        @"day":dayStr,
                        @"pai":paiStr,
                        @"totals":totalsStr,
                        @"low":lowStr,
                        @"lowMins":lowMinsStr,
                        @"medium":mediumStr,
                        @"mediumMins":mediumMinsStr,
                        @"high":highStr,
                        @"highMins":highMinsStr,
                    };
                    [dataList addObject:itemMap];
                }
                NSLog(@"PAI同步数据====dataList=====%@", dataList);
                NSDictionary *dic = @{
                    @"msg":@"success",
                    @"code":@"1",
                    @"result":dataList,
                };
                if (sucBlock) {
                    sucBlock(dic);
                }
            }
            index ++;
        }
    }
                                     failureBlock:failedBlock];
}

// 压力同步 0x09
+ (void)syncPressureDataWithsucBlock:(int)year
                               month:(int)month
                                 day:(int)day
                            sucBlock:(mk_userDataInterfaceSucBlock)sucBlock
                         failedBlock:(mk_userDataInterfaceFailedBlock)failedBlock{
    
    NSString *commandString = [MKUserDataInterfaceAdopter formatDataPushCommandString:9
                                                                                 year:year
                                                                                month:month
                                                                                  day:day];
//    NSLog(@"压力commandString%@",commandString);
    __block NSInteger index = 1;
    __block NSString *result = @"";
    [currentCentral addNeedResetNumTaskWithTaskID:mk_syncPressure
                                           number:1
                                      commandData:commandString
                                   characteristic:connectedPeripheral.updateNotify
                                     successBlock:^(id returnData) {
        NSData *content = [mk_fitpoloAdopter stringToData:returnData[@"result"][@"result"]];
        if ([content length] == 0) {
            [currentCentral cancelOpration:mk_syncPressure];
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
        if (dataLength <= 8) {
            [currentCentral cancelOpration:mk_syncPressure];
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
        NSData *pressureData = [content subdataWithRange:NSMakeRange(5, dataLength)];
        NSInteger packType = (int)bytes[6];
        NSInteger packIndex = (int)bytes[7];
        NSData *pressureResult = [pressureData subdataWithRange:NSMakeRange(8, pressureData.length-8)];
        if(packIndex == index){
            NSString *pressureDataHexString = [mk_fitpoloAdopter hexStringFromData:pressureResult];
            NSString *pressureDataString = [mk_fitpoloAdopter stringFromHexString:pressureDataHexString];
            result = [result stringByAppendingString:pressureDataString];
//            NSLog(@"压力同步数据====result=====%@", result);
            if (packType == 2 || packType == 0) {
                ///解析到最后一包触发
                [currentCentral cancelOpration:mk_syncPressure];
                //最终数据数组
                NSMutableArray *dataList = [NSMutableArray array];
                //1、把result分割
                NSMutableArray *dataArray = [result componentsSeparatedByString:@"\n"];
                [dataArray removeLastObject];
//                NSLog(@"压力同步数据====linesArray=====%@", dataArray);
                //2、遍历把[PR]替换""，
                for (NSInteger i = 0; i < [dataArray count]; i++) {
                    if(dataArray[i] == @"") return;
                    NSString *itemString = [dataArray[i] stringByReplacingOccurrencesOfString:@"[PR]" withString:@""];
                    NSArray *itemArray = [itemString componentsSeparatedByString:@","];
                    // 创建日期组件
                    NSDateComponents *components = [[NSDateComponents alloc] init];
                    components.year = year;
                    components.month = month;
                    components.day = day;
                    NSCalendar *calendar = [NSCalendar currentCalendar];
                    NSDate *date = [calendar dateFromComponents:components];
                    NSTimeInterval timestamp = [date timeIntervalSince1970];
                    NSInteger intTimestamp = (NSInteger)timestamp;
                    NSLog(@"时间戳: %f", timestamp); // 输出时间戳
                    NSString *timestampStr = [NSString stringWithFormat:@"%d",intTimestamp];
                    NSString *yearStr = [NSString stringWithFormat:@"%d",year];
                    NSString *monthStr = [NSString stringWithFormat:@"%d",month];
                    NSString *dayStr = [NSString stringWithFormat:@"%d",day];
                    //3、把数据挨个传入一个NSDictionary
                    NSDictionary *itemMap = @{
                        @"id":timestampStr,
                        @"year":yearStr,
                        @"month":monthStr,
                        @"day":dayStr,
                        @"relax":[NSString stringWithFormat:@"%@",itemArray[0]],
                        @"normal":[NSString stringWithFormat:@"%@",itemArray[1]],
                        @"strain":[NSString stringWithFormat:@"%@",itemArray[2]],
                        @"anxiety":[NSString stringWithFormat:@"%@",itemArray[3]],
                        @"highest":[NSString stringWithFormat:@"%@",itemArray[4]],
                        @"minimum":[NSString stringWithFormat:@"%@",itemArray[5]],
                        @"lately":[NSString stringWithFormat:@"%@",itemArray[6]],
                    };
//                    NSLog(@"itemMap%@", itemMap);
                    //4、把NSDictionary都传入最终数据数组
                    [dataList addObject:itemMap];
                }
                NSLog(@"压力同步数据====dataList=====%@", dataList);
                NSDictionary *dic = @{
                    @"msg":@"success",
                    @"code":@"1",
                    @"result":dataList,
                };
                if (sucBlock) {
                    sucBlock(dic);
                }
            }
            index ++;
        }
    }
                                     failureBlock:failedBlock];
}
#pragma mark - private method

/**
 请求数据
 
 @param hexTime 要请求的时间点，返回的是该时间点之后的所有计步数据，
 @param dataType 请求数据类型，目前支持计步、睡眠index、睡眠record、心率
 @param successBlock success callback
 @param failedBlock fail callback
 */
+ (void)read701PeripheralData:(NSString *)hexTime
                     dataType:(readDataWithTimeStamp)dataType
                     sucBlock:(mk_userDataInterfaceSucBlock)successBlock
                    failBlock:(mk_userDataInterfaceFailedBlock)failedBlock{
    //默认是计步
    NSString *function = @"92";
    mk_taskOperationID operationID = mk_readStepDataOperation;
    if (dataType == readSleepIndexDataWithTimeStamp) {
        //睡眠index
        function = @"93";
        operationID = mk_readSleepIndexOperation;
    }else if (dataType == readSleepRecordDataWithTimeStamp){
        //睡眠record
        function = @"94";
        operationID = mk_readSleepRecordOperation;
    }else if (dataType == readHeartRateDataWithTimeStamp){
        //心率
        function = @"a8";
        operationID = mk_readHeartDataOperation;
    }
    NSString *commandString = [NSString stringWithFormat:@"%@%@%@",@"2c",hexTime,function];
    [currentCentral addNeedPartOfDataTaskWithTaskID:operationID
                                        commandData:commandString
                                     characteristic:connectedPeripheral.commandSend
                                       successBlock:successBlock
                                       failureBlock:failedBlock];
}

/**
 请求数据
 
 @param hexTime 要请求的时间点，返回的是该时间点之后的所有计步数据，
 @param successBlock success callback
 @param failedBlock fail callback
 */
+ (void)readCurrentPeripheralStepData:(NSString *)hexTime
                             sucBlock:(mk_userDataInterfaceSucBlock)successBlock
                            failBlock:(mk_userDataInterfaceFailedBlock)failedBlock{
    NSString *commandString = [NSString stringWithFormat:@"%@%@",@"b40105",hexTime];
    [currentCentral addNeedPartOfDataTaskWithTaskID:mk_readStepDataOperation
                                        commandData:commandString
                                     characteristic:connectedPeripheral.otaData
                                       successBlock:successBlock
                                       failureBlock:failedBlock];
}

+ (NSArray *)fetchSleepIndexData:(NSString *)hexTime{
    __block NSArray *resultList = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    if (currentCentral.deviceType == mk_fitpolo701) {
        [self read701PeripheralData:hexTime dataType:readSleepIndexDataWithTimeStamp sucBlock:^(id returnData) {
            resultList = returnData[@"result"];
            dispatch_semaphore_signal(semaphore);
        } failBlock:^(NSError *error) {
            dispatch_semaphore_signal(semaphore);
        }];
    }else{
        NSString *commandString = [NSString stringWithFormat:@"%@%@",@"b01205",hexTime];
        [currentCentral addNeedPartOfDataTaskWithTaskID:mk_readSleepIndexOperation
                                            commandData:commandString
                                         characteristic:connectedPeripheral.readData
                                           successBlock:^(id returnData) {
                                               resultList = returnData[@"result"];
                                               dispatch_semaphore_signal(semaphore);
                                           } failureBlock:^(NSError *error) {
                                               dispatch_semaphore_signal(semaphore);
                                           }];
    }
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return resultList;
}

+ (NSArray *)fetchSleepRecordData:(NSString *)hexTime{
    __block NSArray *resultList = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    if (currentCentral.deviceType == mk_fitpolo701) {
        [self read701PeripheralData:hexTime dataType:readSleepRecordDataWithTimeStamp sucBlock:^(id returnData) {
            resultList = returnData[@"result"];
            dispatch_semaphore_signal(semaphore);
        } failBlock:^(NSError *error) {
            dispatch_semaphore_signal(semaphore);
        }];
    }else{
        NSString *commandString = [NSString stringWithFormat:@"%@%@",@"b01405",hexTime];
        [currentCentral addNeedPartOfDataTaskWithTaskID:mk_readSleepRecordOperation
                                            commandData:commandString
                                         characteristic:connectedPeripheral.readData
                                           successBlock:^(id returnData) {
                                               resultList = returnData[@"result"];
                                               dispatch_semaphore_signal(semaphore);
                                           } failureBlock:^(NSError *error) {
                                               dispatch_semaphore_signal(semaphore);
                                           }];
    }
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return resultList;
}

+ (NSArray *)fetchHeartRate:(NSString *)hexTime{
    __block NSArray *resultList = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    if (currentCentral.deviceType == mk_fitpolo701) {
        [self read701PeripheralData:hexTime dataType:readHeartRateDataWithTimeStamp sucBlock:^(id returnData) {
            NSArray *dataList = returnData[@"result"];
            NSMutableArray *tempList = [NSMutableArray array];
            for (NSDictionary *dic in dataList) {
                NSArray *heartList = dic[@"heartList"];
                if (mk_validArray(heartList)) {
                    [tempList addObjectsFromArray:heartList];
                }
            }
            resultList = [tempList copy];
            dispatch_semaphore_signal(semaphore);
        } failBlock:^(NSError *error) {
            dispatch_semaphore_signal(semaphore);
        }];
    }else{
        NSString *commandString = [NSString stringWithFormat:@"%@%@",@"b60105",hexTime];
        [currentCentral addNeedPartOfDataTaskWithTaskID:mk_readHeartDataOperation
                                            commandData:commandString
                                         characteristic:connectedPeripheral.readData
                                           successBlock:^(id returnData) {
                                               NSArray *dataList = returnData[@"result"];
                                               NSMutableArray *tempList = [NSMutableArray array];
                                               for (NSDictionary *dic in dataList) {
                                                   NSArray *heartList = dic[@"heartList"];
                                                   if (mk_validArray(heartList)) {
                                                       [tempList addObjectsFromArray:heartList];
                                                   }
                                               }
                                               resultList = [tempList copy];
                                               dispatch_semaphore_signal(semaphore);
                                           } failureBlock:^(NSError *error) {
                                               dispatch_semaphore_signal(semaphore);
                                           }];
    }
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return resultList;
}

+ (void)addUserReadTaskWithTaskID:(mk_taskOperationID)taskID
                     resetNum:(BOOL)resetNum
                commandString:(NSString *)commandString
                     sucBlock:(mk_communicationSuccessBlock)sucBlock
                    failBlock:(mk_communicationFailedBlock)failBlock{
    CBCharacteristic *character = connectedPeripheral.updateNotify;
    [currentCentral addTaskWithTaskID:taskID
                             resetNum:resetNum
                          commandData:commandString
                       characteristic:character
                         successBlock:sucBlock
                         failureBlock:failBlock];
}

@end
