//
//  mk_fitpoloCentralManager.m
//  mk_fitpoloCentralManager
//
//  Created by aa on 2018/12/10.
//  Copyright © 2018 mk_fitpolo. All rights reserved.
//

#import "mk_fitpoloCentralManager.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "mk_fitpoloAdopter.h"
#import "CBPeripheral+mk_fitpolo701.h"
#import "CBPeripheral+mk_fitpoloCurrent.h"
#import "mk_fitpoloTaskOperation.h"
#import "mk_fitpoloLogManager.h"
#import "mk_fitpoloCurrentParser.h"
#import "DailTask.h"

typedef NS_ENUM(NSInteger, currentManagerAction) {
    currentManagerActionDefault,
    currentManagerActionScan,
    currentManagerActionConnectPeripheral,
    currentManagerActionConnectPeripheralWithScan,
};

@interface NSObject (MKFitpoloSDK)

@end

@implementation NSObject (MKFitpoloSDK)

+ (void)load{
    [mk_fitpoloCentralManager sharedInstance];
}

@end

@implementation mk_fitpoloScanDeviceModel
@end
NSString *const mk_peripheralConnectStateChangedNotification = @"mk_peripheralConnectStateChangedNotification";
//外设固件升级结果通知,由于升级固件采用的是无应答定时器发送数据包，所以当产生升级结果的时候，需要靠这个通知来结束升级过程
NSString *const mk_peripheralUpdateResultNotification = @"mk_peripheralUpdateResultNotification";
//监听计步数据
NSString *const mk_listeningStateStepDataNotification = @"mk_listeningStateStepDataNotification";
//搜索手机通知
NSString *const mk_searchMobilePhoneNotification = @"mk_searchMobilePhoneNotification";
//表盘接收通知
NSString *const mk_dailResponseNotification = @"mk_dailResponseNotification";
//监听运动中数据
NSString *const mk_sportDataNotification = @"mk_sportDataNotification";



static mk_fitpoloCentralManager *manager = nil;
static dispatch_once_t onceToken;
static NSInteger const scanConnectMacCount = 2;
static NSString const *sportType = @"0"; // 运动类型：0-户外步行、 1-户外跑步、 2-室内步行、 3-室内跑步

@interface mk_fitpoloCentralManager ()<CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong)CBCentralManager *centralManager;

@property (nonatomic, strong)CBPeripheral *connectedPeripheral;

@property (nonatomic, strong)dispatch_queue_t centralManagerQueue;

@property (nonatomic, copy)mk_connectFailedBlock connectFailBlock;

@property (nonatomic, copy)mk_connectSuccessBlock connectSucBlock;

@property (nonatomic, assign)BOOL scanTimeout;

@property (nonatomic, assign)NSInteger scanConnectCount;

@property (nonatomic, copy)NSString *identifier;

@property (nonatomic, strong)dispatch_source_t scanTimer;

@property (nonatomic, strong)dispatch_source_t connectTimer;

@property (nonatomic, assign)currentManagerAction managerAction;

@property (nonatomic, assign)mk_fitpoloConnectStatus connectStatus;

@property (nonatomic, assign)mk_fitpoloCentralManagerState centralStatus;

@property (nonatomic, assign)BOOL connectTimeout;

@property (nonatomic, assign)BOOL isConnecting;

@property (nonatomic, assign)mk_fitpoloDeviceType deviceType;

@end

@implementation mk_fitpoloCentralManager

- (void)dealloc{
    NSLog(@"mk_fitpoloCentralManager销毁");
}

-(instancetype) initInstance {
    if (self = [super init]) {
        _centralManagerQueue = dispatch_queue_create("moko.com.centralManager", DISPATCH_QUEUE_SERIAL);
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:_centralManagerQueue];
    }
    return self;
}

+ (mk_fitpoloCentralManager *)sharedInstance{
    dispatch_once(&onceToken, ^{
        if (!manager) {
            manager = [[mk_fitpoloCentralManager alloc] initInstance];
        }
    });
    return manager;
}

+ (void)singletonDestroyed{
    onceToken = 0;
    manager = nil;
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    mk_fitpoloCentralManagerState managerState = mk_fitpoloCentralManagerStateUnable;
    if (central.state == CBCentralManagerStatePoweredOn) {
        managerState = mk_fitpoloCentralManagerStateEnable;
    }
    self.centralStatus = managerState;
    if ([self.stateDelegate respondsToSelector:@selector(mk_centralStateChanged:manager:)]) {
        mk_fitpolo_main_safe(^{
            [self.stateDelegate mk_centralStateChanged:managerState manager:manager];
        });
    }
    if (central.state == CBCentralManagerStatePoweredOn) {
        return;
    }
    if (self.connectedPeripheral) {
        [self.connectedPeripheral setFitpoloCurrentCharacteNil];
        self.connectedPeripheral = nil;
        [self.operationQueue cancelAllOperations];
    }
    if (self.connectStatus == mk_fitpoloConnectStatusConnected) {
        [self updateManagerStateConnectState:mk_fitpoloConnectStatusDisconnect];
    }
    if (self.managerAction == currentManagerActionDefault) {
        return;
    }
    if (self.managerAction == currentManagerActionScan) {
        self.managerAction = currentManagerActionDefault;
        self.deviceType = mk_fitpoloUnknow;
        [self.centralManager stopScan];
        mk_fitpolo_main_safe(^{
            if ([self.scanDelegate respondsToSelector:@selector(mk_centralStopScan:)]) {
                [self.scanDelegate mk_centralStopScan:manager];
            }
        });
        return;
    }
    if (self.managerAction == currentManagerActionConnectPeripheralWithScan) {
        [self.centralManager stopScan];
    }
    [self connectPeripheralFailed];
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                  RSSI:(NSNumber *)RSSI{
    dispatch_async(_centralManagerQueue, ^{
        [self scanNewPeripheral:peripheral advDic:advertisementData rssi:RSSI];
    });
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    [mk_fitpoloLogManager writeCommandToLocalFile:@[@"连接设备成功，尚未发现特征"] sourceInfo:mk_logDataSourceAPP];
//    if (self.connectTimeout || self.deviceType == mk_fitpoloUnknow) {
//        return;
//    }
    self.connectedPeripheral = peripheral;
    self.connectedPeripheral.delegate = self;
//    if (self.deviceType == mk_fitpolo701) {
//        [self.connectedPeripheral setFitpolo701CharacterNil];
//        [self.connectedPeripheral discoverServices:@[[CBUUID UUIDWithString:@"FFC0"]]];
//        return;
//    }
    [self.connectedPeripheral setFitpoloCurrentCharacteNil];
    [self.connectedPeripheral discoverServices:@[]];
    NSLog(@"连接设备成功，尚未发现特征");
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    if (error) {
        [mk_fitpoloLogManager writeCommandToLocalFile:@[@"设备连接出现了错误:%@",[error localizedDescription]]
                                          sourceInfo:mk_logDataSourceAPP];
    }
    [self connectPeripheralFailed];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"断开连接");
    self.isConnecting = NO;
    if (error) {
        [mk_fitpoloLogManager writeCommandToLocalFile:@[@"设备断开了连接:%@",[error localizedDescription]]
                                          sourceInfo:mk_logDataSourceAPP];
    }
    self.isConnecting = NO;
    if (self.deviceType == mk_fitpoloUnknow) {
        return;
    }
    if (self.connectStatus != mk_fitpoloConnectStatusConnected) {
        //如果是连接过程中发生的断开连接不处理
        [mk_fitpoloLogManager writeCommandToLocalFile:@[@"连接过程中的断开连接不需处理"] sourceInfo:mk_logDataSourceAPP];
        return;
    }
    if (self.deviceType == mk_fitpolo701) {
        [self.connectedPeripheral setFitpolo701CharacterNil];
    }else{
        [self.connectedPeripheral setFitpoloCurrentCharacteNil];
    }
    self.deviceType = mk_fitpoloUnknow;
    self.connectedPeripheral = nil;
    [self updateManagerStateConnectState:mk_fitpoloConnectStatusDisconnect];
    [self.operationQueue cancelAllOperations];
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"didDiscoverServices");
    for (CBService *service in peripheral.services) {
        NSLog(@"didDiscoverServices：%@",service.UUID);
        if ([service.UUID isEqual:[CBUUID UUIDWithString:datapush]]) {
            //通用服务
            [peripheral discoverCharacteristics:@[]
                                     forService:service];
        }
        if ([service.UUID isEqual:[CBUUID UUIDWithString:setting]]) {
            //通用服务
            [peripheral discoverCharacteristics:@[]
                                     forService:service];
        }
        if ([service.UUID isEqual:[CBUUID UUIDWithString:xoframe]]) {
            //通用服务
            [peripheral discoverCharacteristics:@[]
                                     forService:service];
        }
        if ([service.UUID isEqual:[CBUUID UUIDWithString:ota]]) {
            //OTA服务
            [peripheral discoverCharacteristics:@[]
                                     forService:service];
        }
    }
    [self.connectedPeripheral setFitpoloCurrentCharacteNil];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error) {
        [mk_fitpoloLogManager writeCommandToLocalFile:@[@"发现特征出错:%@",[error localizedDescription]]
                                          sourceInfo:mk_logDataSourceAPP];
        [self connectPeripheralFailed];
        return;
    }
    [self.connectedPeripheral updateCurrentCharacteristicsForService:service];

}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) {
        [mk_fitpoloLogManager writeCommandToLocalFile:@[@"接受数据出错:%@",[error localizedDescription]]
                                          sourceInfo:mk_logDataSourceAPP];
        return;
    }
    
    NSLog(@"特征值:%@",characteristic.UUID);
    NSLog(@"特征返回值:%@",characteristic.value);
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:otaIndicate]]){
        NSLog(@"特征返回值-ota:%@",characteristic.value);
        //抛出升级结果通知，@"00"成功@"01"超时@"02"校验码错误@"03"文件错误
        [[NSNotificationCenter defaultCenter] postNotificationName:mk_peripheralUpdateResultNotification
                                                                    object:nil
                                                                  userInfo:@{@"data" : characteristic.value}];
    }else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:datapushCharcter]]){
        NSData *readData = characteristic.value;
        const uint8_t *bytes = readData.bytes;
        NSString *content = [mk_fitpoloAdopter hexStringFromData:readData];
        if (!mk_validData(readData) || !mk_validStr(content)) {
            return;
        }
        if (self.operationQueue.operationCount == 0){
            //判断实时运动数据
            if ((int)bytes[3] == 6) {//判断类型
                if ((int)bytes[2] == 3){//第二位是cmd 判断是否是Function
                    int dataLength = (int)bytes[4];
                    NSArray *result = [self parseInMotionData:characteristic];
                    NSLog(@"解析后运动中数据======: %@", result);
                    //发送实时运动数据
                    [[NSNotificationCenter defaultCenter] postNotificationName:mk_sportDataNotification
                                                                        object:nil
                                                                      userInfo:@{@"sportData" : result}];
                    return;
                }
            }
        }
    }else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FFB1"]]){
        //寻找手机功能
        NSData *readData = characteristic.value;
        NSString *content = [mk_fitpoloAdopter hexStringFromData:readData];
        if (content.length >= 6 && [[content substringWithRange:NSMakeRange(0, 2)] isEqualToString:@"b3"]) {
            NSString *function = [content substringWithRange:NSMakeRange(2, 2)];
            if ([function isEqualToString:@"17"] && [[content substringWithRange:NSMakeRange(6, 2)] isEqualToString:@"01"]) {
                //手机需要响铃+震动
                [[NSNotificationCenter defaultCenter] postNotificationName:mk_searchMobilePhoneNotification object:nil];
                return;
            }
        }
    }else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:xoframeNotify]]){
        [[NSNotificationCenter defaultCenter] postNotificationName:mk_dailResponseNotification
                                                                    object:nil
                                                                  userInfo:@{@"data" : characteristic.value}];
        [DailTask calcuMtu:characteristic.value];
    }
    NSLog(@"didUpdateValueForCharacteristic");
    BOOL isSuccess = [self.connectedPeripheral fitpoloCurrentConnectSuccess];
    if (isSuccess) {
        NSLog(@"didUpdateValueForCharacteristic11");
        //发现所有的特征不能认为是连接成功，必须等到要监听的所有特征都监听成功了才认为是连接成功
        [self connectPeripheralSuccess];
    }
    
    @synchronized(self.operationQueue) {
        NSArray *operations = [self.operationQueue.operations copy];
        for (mk_fitpoloTaskOperation *operation in operations) {
            if (operation.executing) {
                [operation peripheral:peripheral didUpdateValueForCharacteristic:characteristic error:NULL];
                
                NSLog(@"队列返回值:%d",self.operationQueue.operationCount);
                break;
            }
        }
    }
}
- (NSArray *)parseInMotionData:(CBCharacteristic *)characteristic{
    NSData *readData = characteristic.value;
    const uint8_t *bytes = readData.bytes;
    
    int dataLength = (int)bytes[4];
    NSData *result = [readData subdataWithRange:NSMakeRange(5, dataLength)];
    NSData *sportData = [result subdataWithRange:NSMakeRange(2, dataLength-2)];
    NSString *sportDataHexString = [mk_fitpoloAdopter hexStringFromData:sportData];
    NSString *sportDataString = [mk_fitpoloAdopter stringFromHexString:sportDataHexString];
//    NSLog(@"result: %@", result);
    NSLog(@"解析运动中数据: %@", sportDataString);
    //解析数据数组
    NSMutableArray *stringArray = [NSMutableArray array];
    // 使用正则表达式去除所有非数字字符
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^\\d]" options:0 error:nil];
    if ([sportDataString hasPrefix:@"[1]"]) {//运动开始
        sportDataString = [sportDataString stringByReplacingOccurrencesOfString:@"[1]" withString:@""];
//        NSLog(@"resultString--: %@", sportDataString);
        NSArray *fruits = [sportDataString componentsSeparatedByString:@","];
        [stringArray addObject:@"1"];//运动状态
        [stringArray addObject:fruits[0]];//运动开始时间
        sportType = [fruits[1] substringToIndex:1];
        [stringArray addObject:sportType];//运动类型
    } else if ([sportDataString hasPrefix:@"[2]"]) {//运动中数据
        sportDataString = [sportDataString stringByReplacingOccurrencesOfString:@"[2]" withString:@""];
        NSArray *fruits = [sportDataString componentsSeparatedByString:@","];
        [stringArray addObject:@"2"];//运动状态
        if ([sportType isEqualToString:@"5"]) {//骑行
            [stringArray addObject:fruits[0]];//开始时间——171945 hhmmss
            [stringArray addObject:fruits[3]];//实时心率 次/分
            [stringArray addObject:fruits[5]];//实时速度 每公里用时
            [stringArray addObject:fruits[7]];//平均心率 次/分
            [stringArray addObject:fruits[9]];//距离 米
            [stringArray addObject:fruits[10]];//卡路里 千卡
            [stringArray addObject:fruits[12]];//平均速度 每公里用时
            NSString *lastValue = [regex stringByReplacingMatchesInString:fruits[13] options:0 range:NSMakeRange(0, [fruits[13] length]) withTemplate:@""];
            [stringArray addObject:lastValue]; //时间 秒
        } else {
            [stringArray addObject:fruits[0]];//开始时间——171945 hhmmss
            [stringArray addObject:fruits[1]];//步频 步/分
            [stringArray addObject:fruits[2]];//实时速度 秒 每公里用时
            [stringArray addObject:fruits[3]];//实时心率 次/分
            [stringArray addObject:fruits[7]];//平均心率 次/分
            [stringArray addObject:fruits[8]];//平均速度 秒 每公里用时
            [stringArray addObject:fruits[9]];//距离 米
            [stringArray addObject:fruits[10]];//卡路里 千卡
            [stringArray addObject:fruits[11]];//步数
            NSString *lastValue = [regex stringByReplacingMatchesInString:fruits[12] options:0 range:NSMakeRange(0, [fruits[12] length]) withTemplate:@""];
            [stringArray addObject:lastValue]; //时间 秒
        }
    } else if ([sportDataString hasPrefix:@"[3]"]) {//运动暂停
        sportDataString = [sportDataString stringByReplacingOccurrencesOfString:@"[3]" withString:@""];
        NSArray *fruits = [sportDataString componentsSeparatedByString:@","];
        [stringArray addObject:@"3"];//运动状态
        NSString *lastValue = [regex stringByReplacingMatchesInString:fruits[0] options:0 range:NSMakeRange(0, [fruits[0] length]) withTemplate:@""];
        [stringArray addObject:lastValue];//开始时间——171945 hhmmss
    } else if ([sportDataString hasPrefix:@"[4]"]) {//运动继续
        sportDataString = [sportDataString stringByReplacingOccurrencesOfString:@"[4]" withString:@""];
        NSArray *fruits = [sportDataString componentsSeparatedByString:@","];
        [stringArray addObject:@"4"];//运动状态
        NSString *lastValue = [regex stringByReplacingMatchesInString:fruits[0] options:0 range:NSMakeRange(0, [fruits[0] length]) withTemplate:@""];
        [stringArray addObject:lastValue];//开始时间——171945 hhmmss
    } else if ([sportDataString hasPrefix:@"[5]"]) {//运动结束
        sportDataString = [sportDataString stringByReplacingOccurrencesOfString:@"[5]" withString:@""];
        NSArray *fruits = [sportDataString componentsSeparatedByString:@","];
        [stringArray addObject:@"5"];//状态——无数据结束
        [stringArray addObject:fruits[0]];//开始时间— yyMMddHHmmss —240927164832
        [stringArray addObject:fruits[1]];//结束时间— YYMMddHHmmss —240927165058
        [stringArray addObject:fruits[2]];//运动类型
        if ([sportType isEqualToString:@"5"]) {//骑行
            [stringArray addObject:fruits[4]];//距离
            [stringArray addObject:fruits[5]];//卡路里
            [stringArray addObject:fruits[15]];//心率区间——热身 例：2, 1, 9, 0, 0, 17%
            [stringArray addObject:fruits[16]];//心率区间——燃脂 8%
            [stringArray addObject:fruits[17]];//心率区间——有氧 75%
            [stringArray addObject:fruits[18]];//心率区间——无氧 0%
            [stringArray addObject:fruits[19]];//心率区间——极限 0%
            [stringArray addObject:fruits[20]];//平均心率
            [stringArray addObject:fruits[21]];//最大心率
            [stringArray addObject:fruits[22]];//最低心率
            [stringArray addObject:fruits[24]];//时长——分钟
            [stringArray addObject:fruits[34]];//平均配速
        } else {
            [stringArray addObject:fruits[3]];//步数
            [stringArray addObject:fruits[4]];//距离
            [stringArray addObject:fruits[5]];//卡路里
            [stringArray addObject:fruits[7]];//平均步频
            [stringArray addObject:fruits[8]];//最大步频
            [stringArray addObject:fruits[10]];//平均步长
            [stringArray addObject:fruits[12]];//平均配速
            [stringArray addObject:fruits[13]];//最大配速
            [stringArray addObject:fruits[14]];//最低心率
            [stringArray addObject:fruits[15]];//心率区间——热身 例：2, 1, 9, 0, 0, 17%
            [stringArray addObject:fruits[16]];//心率区间——燃脂 8%
            [stringArray addObject:fruits[17]];//心率区间——有氧 75%
            [stringArray addObject:fruits[18]];//心率区间——无氧 0%
            [stringArray addObject:fruits[19]];//心率区间——极限 0%
            [stringArray addObject:fruits[20]];//平均心率
            [stringArray addObject:fruits[21]];//最大心率
            [stringArray addObject:fruits[22]];//最小心率
            [stringArray addObject:fruits[23]];//最大摄氧量
            [stringArray addObject:fruits[24]];//时长——分钟
        }
    } else {//运动无数据结束
        sportDataString = [sportDataString stringByReplacingOccurrencesOfString:@"[6]" withString:@""];
        NSArray *fruits = [sportDataString componentsSeparatedByString:@","];
        [stringArray addObject:@"6"];//状态——无数据结束
        [stringArray addObject:fruits[0]];//240927164832
        [stringArray addObject:fruits[1]];//240927164832
        NSString *lastValue = [regex stringByReplacingMatchesInString:fruits[2] options:0 range:NSMakeRange(0, [fruits[2] length]) withTemplate:@""];
        [stringArray addObject:lastValue];//运动类型
    }
    return stringArray;
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
//    if (error) {
//        [mk_fitpoloLogManager writeCommandToLocalFile:@[@"设置监听属性回调发生了错误",[error localizedDescription]]
//                                          sourceInfo:mk_logDataSourceAPP];
//        return;
//    }
//    if (self.connectTimeout || self.deviceType == mk_fitpoloUnknow) {
//        return;
//    }
//    NSLog(@"didUpdateNotificationStateForCharacteristic: %d",characteristic.isNotifying);
//    [mk_fitpoloLogManager writeCommandToLocalFile:@[@"设置监听属性回调成功",characteristic.UUID.UUIDString] sourceInfo:mk_logDataSourceAPP];
//    if (self.deviceType == mk_fitpolo701) {
        [self.connectedPeripheral update701NotifySuccess:characteristic];
        if ([self.connectedPeripheral fitpolo701ConnectSuccess]) {
            //发现所有的特征不能认为是连接成功，必须等到要监听的所有特征都监听成功了才认为是连接成功
            [self connectPeripheralSuccess];
        }
//        return;
//    }
    [self.connectedPeripheral updateCurrentNotifySuccess:characteristic];
    if ([self.connectedPeripheral fitpoloCurrentConnectSuccess]) {
        //发现所有的特征不能认为是连接成功，必须等到要监听的所有特征都监听成功了才认为是连接成功
        [self connectPeripheralSuccess];
    }
}

#pragma mark - ***********************public method************************
#pragma mark - scan method
- (BOOL)scanDevice{
    if (self.isConnecting) {
        return NO;
    }
    if (self.centralManager.state != CBCentralManagerStatePoweredOn) {
        //蓝牙状态不可用
        return NO;
    }
    self.managerAction = currentManagerActionScan;
    if ([self.scanDelegate respondsToSelector:@selector(mk_centralStartScan:)]) {
        mk_fitpolo_main_safe(^{
            [self.scanDelegate mk_centralStartScan:manager];
        });
    }
    [mk_fitpoloLogManager writeCommandToLocalFile:@[@"开始扫描"] sourceInfo:mk_logDataSourceAPP];
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"23C0"]] options:nil];
    return YES;
}

- (void)stopScan{
    if ([self.scanDelegate respondsToSelector:@selector(mk_centralStopScan:)]) {
        mk_fitpolo_main_safe(^{
            [self.scanDelegate mk_centralStopScan:manager];
        });
    }
    [mk_fitpoloLogManager writeCommandToLocalFile:@[@"停止扫描"] sourceInfo:mk_logDataSourceAPP];
    if (self.isConnecting) {
        //连接过程中不允许调用
        return;
    }
    [self.centralManager stopScan];
    self.managerAction = currentManagerActionDefault;
}

#pragma mark - connect method

- (void)connectWithIdentifier:(NSString *)identifier
                   deviceType:(mk_fitpoloDeviceType)deviceType
              connectSucBlock:(mk_connectSuccessBlock)successBlock
             connectFailBlock:(mk_connectFailedBlock)failedBlock{
    if (self.isConnecting) {
        [mk_fitpoloAdopter operationConnectingErrorBlock:failedBlock];
        return;
    }
    self.isConnecting = YES;
    if (![mk_fitpoloAdopter checkIdenty:identifier]) {
        //参数错误
        self.isConnecting = NO;
        [mk_fitpoloAdopter operationConnectFailedBlock:failedBlock];
        return;
    }
    if (self.centralManager.state != CBCentralManagerStatePoweredOn) {
        //蓝牙状态不可用
        self.isConnecting = NO;
        [mk_fitpoloAdopter operationCentralBlePowerOffBlock:failedBlock];
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self mk_connectWithIdentifier:identifier
                        deviceType:deviceType
                      successBlock:^(CBPeripheral *connectedPeripheral) {
                          if (successBlock) {
                              successBlock(connectedPeripheral);
                          }
                          [weakSelf clearConnectBlock];
                      }
                         failBlock:^(NSError *error) {
                             if (failedBlock) {
                                 failedBlock(error);
                             }
                             [weakSelf clearConnectBlock];
                         }];
}

- (void)connectPeripheral:(CBPeripheral *)peripheral
               deviceType:(mk_fitpoloDeviceType)deviceType
          connectSucBlock:(mk_connectSuccessBlock)successBlock
         connectFailBlock:(mk_connectFailedBlock)failedBlock{
    if (self.isConnecting) {
        [mk_fitpoloAdopter operationConnectingErrorBlock:failedBlock];
        return;
    }
    self.isConnecting = YES;
    if (!peripheral) {
        self.isConnecting = NO;
        [mk_fitpoloAdopter operationConnectFailedBlock:failedBlock];
        return;
    }
    if (self.centralManager.state != CBCentralManagerStatePoweredOn) {
        //蓝牙状态不可用
        self.isConnecting = NO;
        [mk_fitpoloAdopter operationCentralBlePowerOffBlock:failedBlock];
        return;
    }
    self.deviceType = deviceType;
    __weak typeof(self) weakSelf = self;
    NSLog(@"设备蓝牙信息:%@",peripheral);
    [self connectWithPeripheral:peripheral sucBlock:^(CBPeripheral *connectedPeripheral) {
        NSLog(@"已连接设备:%@",connectedPeripheral);
        if (successBlock) {
            successBlock(connectedPeripheral);
        }
        [weakSelf clearConnectBlock];
    } failedBlock:^(NSError *error) {
        if (failedBlock) {
            failedBlock(error);
        }
        [weakSelf clearConnectBlock];
    }];
}

/**
 断开当前连接的外设
 */
- (void)disconnectConnectedPeripheral{
    if (!self.connectedPeripheral
        || self.centralManager.state != CBCentralManagerStatePoweredOn
        || self.deviceType == mk_fitpoloUnknow) {
        return;
    }
    NSLog(@"disconnectConnectedPeripheral");
    [self.connectedPeripheral setFitpoloCurrentCharacteNil];
    [self.centralManager cancelPeripheralConnection:self.connectedPeripheral];
    self.isConnecting = NO;
}

#pragma mark ****************************** task **********************************

- (BOOL)sendUpdateData:(NSData *)updateData{
    CBCharacteristic *character = self.connectedPeripheral.otaData;
    [self.connectedPeripheral writeValue:updateData
                       forCharacteristic:character
                                    type:CBCharacteristicWriteWithoutResponse];
    NSString *string = [NSString stringWithFormat:@"%@:%@",@"固件升级数据",[mk_fitpoloAdopter hexStringFromData:updateData]];
    [mk_fitpoloLogManager writeCommandToLocalFile:@[string] sourceInfo:mk_logDataSourceAPP];
    return YES;
}

- (BOOL)sendDailData:(NSData *)updateData{
    NSLog(@"xonFrameWrite:%@",updateData);
    CBCharacteristic *character = self.connectedPeripheral.xonFrameWrite;
    [self.connectedPeripheral writeValue:updateData
                       forCharacteristic:character
                                    type:CBCharacteristicWriteWithoutResponse];
    NSString *string = [NSString stringWithFormat:@"%@:%@",@"表盘数据更新",[mk_fitpoloAdopter hexStringFromData:updateData]];
    [mk_fitpoloLogManager writeCommandToLocalFile:@[string] sourceInfo:mk_logDataSourceAPP];
    return YES;
}

- (void)addTaskWithTaskID:(mk_taskOperationID)operationID
                 resetNum:(BOOL)resetNum
              commandData:(NSString *)commandData
           characteristic:(CBCharacteristic *)characteristic
             successBlock:(mk_communicationSuccessBlock)successBlock
             failureBlock:(mk_communicationFailedBlock)failureBlock{
    mk_fitpoloTaskOperation *operation = [self generateOperationWithOperationID:operationID
                                                                      resetNum:resetNum
                                                                   commandData:commandData
                                                                characteristic:characteristic
                                                                  successBlock:successBlock
                                                                  failureBlock:failureBlock];
    if (!operation) {
        return;
    }
    @synchronized(self.operationQueue) {
        [self.operationQueue addOperation:operation];
    }
}

- (void)addNeedPartOfDataTaskWithTaskID:(mk_taskOperationID)operationID
                            commandData:(NSString *)commandData
                         characteristic:(CBCharacteristic *)characteristic
                           successBlock:(mk_communicationSuccessBlock)successBlock
                           failureBlock:(mk_communicationFailedBlock)failureBlock{
    mk_fitpoloTaskOperation *operation = [self generateOperationWithOperationID:operationID
                                                                      resetNum:YES
                                                                   commandData:commandData
                                                                characteristic:characteristic
                                                                  successBlock:successBlock
                                                                  failureBlock:failureBlock];
    if (!operation) {
        return;
    }
    SEL selNeedPartOfData = sel_registerName("needPartOfData:");
    if ([operation respondsToSelector:selNeedPartOfData]) {
        ((void (*)(id, SEL, NSNumber*))(void *) objc_msgSend)((id)operation, selNeedPartOfData, @(YES));
    }
    @synchronized(self.operationQueue) {
        [self.operationQueue addOperation:operation];
    }
}

- (void)addNeedResetNumTaskWithTaskID:(mk_taskOperationID)operationID
                               number:(NSInteger)number
                          commandData:(NSString *)commandData
                       characteristic:(CBCharacteristic *)characteristic
                         successBlock:(mk_communicationSuccessBlock)successBlock
                         failureBlock:(mk_communicationFailedBlock)failureBlock{
    if (number < 1) {
        return;
    }
    mk_fitpoloTaskOperation *operation = [self generateOperationWithOperationID:operationID
                                                                      resetNum:NO
                                                                   commandData:commandData
                                                                characteristic:characteristic
                                                                  successBlock:successBlock
                                                                  failureBlock:failureBlock];
    if (!operation) {
        return;
    }
    operation.needPartOfTimeout = number;
    SEL setNum = sel_registerName("setRespondCount:");
    NSString *numberString = [NSString stringWithFormat:@"%ld",(long)number];
    if ([operation respondsToSelector:setNum]) {
        ((void (*)(id, SEL, NSString*))(void *) objc_msgSend)((id)operation, setNum, numberString);
    }
    @synchronized(self.operationQueue) {
        [self.operationQueue addOperation:operation];
    }
}

- (void)addUpdateFirmwareTaskWithCrcData:(NSData *)crcData
                             packageSize:(NSData *)packageSize
                            successBlock:(mk_communicationSuccessBlock)successBlock
                             failedBlock:(mk_communicationFailedBlock)failedBlock{
    if (!mk_validData(crcData) || !mk_validData(packageSize)) {
        [mk_fitpoloAdopter operationParamsErrorBlock:failedBlock];
        return;
    }
    
    ///开始组装数据
    
    NSData *headerData = [mk_fitpoloAdopter stringToData:@"28"];
    NSMutableData *commandData = [NSMutableData dataWithData:headerData];
    [commandData appendData:crcData];
    
    [commandData appendData:packageSize];
    NSString *commandString = [mk_fitpoloAdopter hexStringFromData:commandData];
    CBCharacteristic *character = [mk_fitpoloCentralManager sharedInstance].connectedPeripheral.otaData;
    mk_fitpoloTaskOperation *operation = [self generateOperationWithOperationID:mk_startUpdateOperation
                                                                      resetNum:NO
                                                                   commandData:commandString
                                                                characteristic:character
                                                                  successBlock:successBlock
                                                                  failureBlock:failedBlock];
    if (!operation) {
        return;
    }
    operation.receiveTimeout = 5.f;
    @synchronized(self.operationQueue) {
        [self.operationQueue addOperation:operation];
    }
}



#pragma mark - ***************private method******************
#pragma mark - scan
- (void)scanNewPeripheral:(CBPeripheral *)peripheral advDic:(NSDictionary *)advDic rssi:(NSNumber *)rssi{
//    if (self.managerAction == currentManagerActionDefault
//        || !mk_validDict(advDic)) {
//        return;
//    }
    mk_fitpoloScanDeviceModel *dataModel = [self parseDeviceModel:advDic rssi:rssi];
//    NSString *startChar = @"River-01"; // 过滤设备名称
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF BEGINSWITH %@", startChar];
//    BOOL matches = [predicate evaluateWithObject:dataModel.deviceName];
//     
//    if (matches) {
//        NSLog(@"过滤设备名称===设备名：", dataModel.deviceName);
//    } else {
//        return;
//    }
    dataModel.peripheral = peripheral;
    NSString *name = [NSString stringWithFormat:@"扫描到的设备名字:%@", dataModel.deviceName];
    NSString *uuid = [NSString stringWithFormat:@"设备UUID:%@", peripheral.identifier.UUIDString];
    NSString *mac = [NSString stringWithFormat:@"设备MAC地址:%@", dataModel.deviceMac];
    NSLog(@"扫描到的设备名字:%@",peripheral.name);
    [mk_fitpoloLogManager writeCommandToLocalFile:@[name,uuid,mac] sourceInfo:mk_logDataSourceAPP];
    if (self.managerAction == currentManagerActionScan) {
        //扫描情况下
        if ([self.scanDelegate respondsToSelector:@selector(mk_centralDidDiscoverPeripheral:centralManager:)]) {
            mk_fitpolo_main_safe(^{
                if(!dataModel) return;
                [self.scanDelegate mk_centralDidDiscoverPeripheral:dataModel centralManager:manager];
            });
        }
        return;
    }
    if (self.managerAction != currentManagerActionConnectPeripheralWithScan
        || self.scanTimeout
        || self.scanConnectCount > 2) {
        return;
    }
    if (![self isTargetPeripheral:dataModel]) {
        return;
    }
    self.connectedPeripheral = peripheral;
    //开始连接目标设备
    [self centralConnectPeripheral:peripheral];
}

- (mk_fitpoloScanDeviceModel *)parseDeviceModel:(NSDictionary *)advDic rssi:(NSNumber *)rssi{
    if (!mk_validDict(advDic)) {
        return nil;
    }
    NSData *data = advDic[CBAdvertisementDataManufacturerDataKey];
//    if (data.length != 9) {
//        return nil;
//    }
//    NSString *temp = [mk_fitpoloAdopter hexStringFromData:data];
//    NSString *macAddress = [NSString stringWithFormat:@"%@-%@-%@-%@-%@-%@",
//                            [temp substringWithRange:NSMakeRange(0, 2)],
//                            [temp substringWithRange:NSMakeRange(2, 2)],
//                            [temp substringWithRange:NSMakeRange(4, 2)],
//                            [temp substringWithRange:NSMakeRange(6, 2)],
//                            [temp substringWithRange:NSMakeRange(8, 2)],
//                            [temp substringWithRange:NSMakeRange(10, 2)]];
//    NSString *deviceType = [temp substringWithRange:NSMakeRange(12, 2)];
    mk_fitpoloScanDeviceModel *dataModel = [[mk_fitpoloScanDeviceModel alloc] init];
    dataModel.deviceMac = @"";
//    if ([deviceType isEqualToString:@"02"]) {
//        //701
//        dataModel.deviceType = mk_fitpolo701;
//    }else if ([deviceType isEqualToString:@"05"]) {
//        //705
//        dataModel.deviceType = mk_fitpolo705;
//    }else if ([deviceType isEqualToString:@"06"]) {
//        //706
//        dataModel.deviceType = mk_fitpolo706;
//    }else if ([deviceType isEqualToString:@"07"]) {
//        //707
//        dataModel.deviceType = mk_fitpolo707;
//    }else if ([deviceType isEqualToString:@"09"]) {
        //709
        dataModel.deviceType = mk_fitpolo709;
//    }
    dataModel.deviceName = advDic[CBAdvertisementDataLocalNameKey];
    dataModel.rssi = [NSString stringWithFormat:@"%ld",(long)[rssi integerValue]];
    NSLog(@"dataModel:%@",dataModel);
    return dataModel;
}

- (BOOL)isTargetPeripheral:(mk_fitpoloScanDeviceModel *)deviceModel{
    if (!deviceModel) {
        return NO;
    }
    NSString *macLow = [[deviceModel.deviceMac lowercaseString] substringWithRange:NSMakeRange(12, 5)];
    if ([self.identifier isEqualToString:macLow]) {
        return YES;
    }
    if ([self.identifier isEqualToString:[deviceModel.deviceMac lowercaseString]]) {
        return YES;
    }
    if ([self.identifier isEqualToString:[deviceModel.peripheral.identifier.UUIDString lowercaseString]]) {
        return YES;
    }
    return NO;
}

#pragma mark - connect
- (void)connectWithPeripheral:(CBPeripheral *)peripheral
                     sucBlock:(mk_connectSuccessBlock)sucBlock
                  failedBlock:(mk_connectFailedBlock)failedBlock{
    if (self.connectedPeripheral) {
        [self.centralManager cancelPeripheralConnection:self.connectedPeripheral];
        [self.operationQueue cancelAllOperations];
        [self.connectedPeripheral setFitpoloCurrentCharacteNil];
    }
    
    [mk_fitpoloLogManager writeCommandToLocalFile:@[@"开始连接手环"] sourceInfo:mk_logDataSourceAPP];
    self.connectedPeripheral = nil;
    self.connectedPeripheral = peripheral;
    self.managerAction = currentManagerActionConnectPeripheral;
    self.connectSucBlock = sucBlock;
    self.connectFailBlock = failedBlock;
    NSLog(@"设备蓝牙信息1:%@",peripheral);
    [self centralConnectPeripheral:peripheral];
}

- (void)centralConnectPeripheral:(CBPeripheral *)peripheral{
    if (!peripheral) {
        return;
    }
    if (self.scanTimer) {
        dispatch_cancel(self.scanTimer);
    }
    NSLog(@"设备蓝牙信息2:%@",peripheral);
    [self.centralManager stopScan];
    [self updateManagerStateConnectState:mk_fitpoloConnectStatusConnecting];
    [self initConnectTimer];
    [self.centralManager connectPeripheral:peripheral options:@{}];
    NSLog(@"设备蓝牙信息3:%@",peripheral);
}

- (void)initConnectTimer{
    self.connectTimeout = NO;
    self.connectTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,_centralManagerQueue);
    dispatch_source_set_timer(self.connectTimer, dispatch_time(DISPATCH_TIME_NOW, 20 * NSEC_PER_SEC),  20 * NSEC_PER_SEC, 0);
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(self.connectTimer, ^{
        weakSelf.connectTimeout = YES;
    });
    dispatch_resume(self.connectTimer);
}

- (void)mk_connectWithIdentifier:(NSString *)identifier
                      deviceType:(mk_fitpoloDeviceType)deviceType
                    successBlock:(mk_connectSuccessBlock)successBlock
                       failBlock:(mk_connectFailedBlock)failedBlock{
    self.deviceType = deviceType;
    if (self.connectedPeripheral) {
        [self.centralManager cancelPeripheralConnection:self.connectedPeripheral];
        [self.operationQueue cancelAllOperations];
        [self.connectedPeripheral setFitpoloCurrentCharacteNil];
        [self.connectedPeripheral setFitpolo701CharacterNil];
    }
    self.connectedPeripheral = nil;
    self.identifier = [identifier lowercaseString];
    self.managerAction = currentManagerActionConnectPeripheralWithScan;
    self.connectSucBlock = successBlock;
    self.connectFailBlock = failedBlock;
    //通过扫描方式连接设备的时候，开始扫描应该视为开始连接
    [self updateManagerStateConnectState:mk_fitpoloConnectStatusConnecting];
    [self startConnectPeripheralWithScan];
}

- (void)startConnectPeripheralWithScan{
    [self.centralManager stopScan];
    self.scanTimeout = NO;
    self.scanTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,_centralManagerQueue);
    dispatch_source_set_timer(self.scanTimer, dispatch_time(DISPATCH_TIME_NOW, 6.0 * NSEC_PER_SEC), 6.0 * NSEC_PER_SEC, 0);
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(self.scanTimer, ^{
        [weakSelf scanTimerTimeoutProcess];
    });
    dispatch_resume(self.scanTimer);
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"FFD0"]] options:nil];
}

- (void)scanTimerTimeoutProcess{
    [self.centralManager stopScan];
    if (self.managerAction != currentManagerActionConnectPeripheralWithScan) {
        return;
    }
    self.scanTimeout = YES;
    self.scanConnectCount ++;
    //扫描方式来连接设备
//    if (self.scanConnectCount > scanConnectMacCount) {
//        //如果扫描连接超时，则直接连接失败，停止扫描
//        [self connectPeripheralFailed];
//        return;
//    }
    //如果小于最大的扫描连接次数，则开启下一轮扫描
    self.scanTimeout = NO;
    [mk_fitpoloLogManager writeCommandToLocalFile:@[@"开启新一轮扫描设备去连接"] sourceInfo:mk_logDataSourceAPP];
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"FFD0"]] options:nil];
}

- (void)resetOriSettings{
    if (self.connectTimer) {
        dispatch_cancel(self.connectTimer);
    }
    if (self.scanTimer) {
        dispatch_cancel(self.scanTimer);
    }
    if (self.managerAction == currentManagerActionConnectPeripheralWithScan) {
        [self.centralManager stopScan];
    }
    self.managerAction = currentManagerActionDefault;
    self.scanTimeout = NO;
    self.scanConnectCount = 0;
    self.connectTimeout = NO;
    self.isConnecting = NO;
}

- (void)connectPeripheralFailed{
    NSLog(@"connectPeripheralFailed");
    [self resetOriSettings];
    if (self.connectedPeripheral) {
        [self.centralManager cancelPeripheralConnection:self.connectedPeripheral];
        self.connectedPeripheral.delegate = nil;
        [self.connectedPeripheral setFitpoloCurrentCharacteNil];
    }
    self.connectedPeripheral = nil;
    [self updateManagerStateConnectState:mk_fitpoloConnectStatusConnectedFailed];
    [mk_fitpoloAdopter operationConnectFailedBlock:self.connectFailBlock];
}

- (void)connectPeripheralSuccess{
//    if (self.connectTimeout) {
//        return;
//    }
//    [self resetOriSettings];
//    [self updateManagerStateConnectState:mk_fitpoloConnectStatusConnected];
//    NSString *tempString = [NSString stringWithFormat:@"连接的设备UUID:%@",self.connectedPeripheral.identifier.UUIDString];
//    [mk_fitpoloLogManager writeCommandToLocalFile:@[tempString] sourceInfo:mk_logDataSourceAPP];
    mk_fitpolo_main_safe(^{
        if (self.connectSucBlock) {
            self.connectSucBlock(self.connectedPeripheral);
        }
    });
}

- (void)clearConnectBlock{
    if (self.connectSucBlock) {
        self.connectSucBlock = nil;
    }
    if (self.connectFailBlock) {
        self.connectFailBlock = nil;
    }
}

- (void)updateManagerStateConnectState:(mk_fitpoloConnectStatus)state{
    self.connectStatus = state;
    mk_fitpolo_main_safe(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:mk_peripheralConnectStateChangedNotification object:nil];
        if ([self.stateDelegate respondsToSelector:@selector(mk_peripheralConnectStateChanged:manager:)]) {
            [self.stateDelegate mk_peripheralConnectStateChanged:state manager:manager];
        }
    });
}
#pragma mark --- 通过ID取消操作 -会把所有相同任务ID的都取消
-(void)cancelOpration:(mk_taskOperationID)oprationID{
    [[self operationQueue].operations enumerateObjectsUsingBlock:^(mk_fitpoloTaskOperation *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.operationID == oprationID){
            NSLog(@"cancelOpration:%@",obj);
            [obj cancelReceiverTimer];
        }
    }];
}


#pragma mark - 数据通信处理方法
- (void)sendCommandToPeripheral:(NSString *)commandData characteristic:(CBCharacteristic *)characteristic{
    if (!self.connectedPeripheral || !mk_validStr(commandData) || !characteristic) {
        return;
    }
    NSData *data = [mk_fitpoloAdopter stringToData:commandData];
    data = [mk_fitpoloAdopter dataWithHexString:commandData];
    if (!mk_validData(data)) {
        return;
    }
    NSLog(@"发送数据为:%@",data);
    [self.connectedPeripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
}

- (BOOL)canSendData{
    if (!self.connectedPeripheral) {
        return NO;
    }
    return (self.connectedPeripheral.state == CBPeripheralStateConnected);
}

- (mk_fitpoloTaskOperation *)generateOperationWithOperationID:(mk_taskOperationID)operationID
                                                    resetNum:(BOOL)resetNum
                                                 commandData:(NSString *)commandData
                                              characteristic:(CBCharacteristic *)characteristic
                                                successBlock:(mk_communicationSuccessBlock)successBlock
                                                failureBlock:(mk_communicationFailedBlock)failureBlock{
    if (![self canSendData]) {
        [mk_fitpoloAdopter operationDisconnectedErrorBlock:failureBlock];
        return nil;
    }
    if (self.deviceType == mk_fitpoloUnknow) {
        [mk_fitpoloAdopter operationDeviceTypeErrorBlock:failureBlock];
        return nil;
    }
    if (!mk_validStr(commandData)) {
        [mk_fitpoloAdopter operationParamsErrorBlock:failureBlock];
        return nil;
    }
    if (!characteristic) {
        [mk_fitpoloAdopter operationCharacteristicErrorBlock:failureBlock];
        return nil;
        
    }
    __weak typeof(self) weakSelf = self;
    NSLog(@"发送数据为空:%@",commandData);
    mk_fitpoloTaskOperation *operation = [[mk_fitpoloTaskOperation alloc] initOperationWithID:operationID deviceType:self.deviceType resetNum:resetNum commandBlock:^{
        [weakSelf sendCommandToPeripheral:commandData characteristic:characteristic];
    } completeBlock:^(NSError * _Nonnull error, mk_taskOperationID operationID, id  _Nonnull returnData) {
        if (error) {
            mk_fitpolo_main_safe(^{
                if (failureBlock) {
                    failureBlock(error);
                }
            });
            return ;
        }
        if (!returnData) {
            [mk_fitpoloAdopter operationRequestDataErrorBlock:failureBlock];
            return ;
        }
        NSLog(@"returnData 返回结果");
//        NSLog(@"%@", returnData);
        NSDictionary *resultDic = @{@"msg":@"success",
                                    @"code":@"1",
                                    @"result":returnData[mk_additionalInformation],
                                    };
        mk_fitpolo_main_safe(^{
            if (successBlock) {
                successBlock(resultDic);
                [operation cancel];
            }
        });
    }];
    return operation;
}

- (void)writeDataToLog:(NSString *)commandData operation:(mk_taskOperationID)operationID{
    if (!mk_validStr(commandData)) {
        return;
    }
    NSString *commandType = [self getCommandType:operationID];
    if (!mk_validStr(commandType)) {
        return;
    }
    NSString *string = [NSString stringWithFormat:@"%@:%@",commandType,commandData];
    [mk_fitpoloLogManager writeCommandToLocalFile:@[string] sourceInfo:mk_logDataSourceAPP];
}

- (NSString *)getCommandType:(mk_taskOperationID)operationID{
    switch (operationID) {
        case mk_readAlarmClockOperation:
            return @"读取手环闹钟数据";
        case mk_readAncsOptionsOperation:
            return @"读取手环ancs选项";
        case mk_readSedentaryRemindOperation:
            return @"读取手环久坐提醒数据";
        case mk_readMovingTargetOperation:
            return @"读取手环运动目标值";
        case mk_readUnitDataOperation:
            return @"读取手环单位信息";
        case mk_readTimeFormatDataOperation:
            return @"读取手环时间进制";
        case mk_readCustomScreenDisplayOperation:
            return @"读取手环屏幕显示";
        case mk_readRemindLastScreenDisplayOperation:
            return @"读取是否显示上一次屏幕";
        case mk_readHeartRateAcquisitionIntervalOperation:
            return @"读取心率采集间隔";
        case mk_readDoNotDisturbTimeOperation:
            return @"读取勿扰时段";
        case mk_readPalmingBrightScreenOperation:
            return @"读取翻腕亮屏信息";
        case mk_readUserInfoOperation:
            return @"读取个人信息";
        case mk_readSportsDataOperation:
            return @"读取运动信息";
        case mk_readLastChargingTimeOperation:
            return @"读取上一次手环充电时间";
        case mk_readBatteryOperation:
            return @"读取手环电池电量";
        case mk_vibrationOperation:
            return @"手环震动";
        case mk_configUnitOperation:
            return @"设置单位信息";
        case mk_configANCSOptionsOperation:
            return @"设置ancs通知选项";
        case mk_configDateOperation:
            return @"设置日期";
        case mk_configUserInfoOperation:
            return @"设置个人信息";
        case mk_configTimeFormatOperation:
            return @"设置时间进制格式";
        case mk_openPalmingBrightScreenOperation:
            return @"设置翻腕亮屏";
        case mk_configAlarmClockOperation:
            return @"设置闹钟";
        case mk_remindLastScreenDisplayOperation:
            return @"设置上一次屏幕显示";
        case mk_configSedentaryRemindOperation:
            return @"设置久坐提醒";
        case mk_configHeartRateAcquisitionIntervalOperation:
            return @"设置心率采集间隔";
        case mk_configScreenDisplayOperation:
            return @"设置屏幕显示";
        case mk_readHardwareParametersOperation:
            return @"获取硬件参数";
        case mk_readFirmwareVersionOperation:
            return @"获取固件版本号";
        case mk_readStepDataOperation:
            return @"获取计步数据";
        case mk_readSleepIndexOperation:
            return @"获取睡眠index数据";
        case mk_readSleepRecordOperation:
            return @"获取睡眠record数据";
        case mk_readHeartDataOperation:
            return @"获取心率数据";
        case mk_startUpdateOperation:
            return @"开启手环升级";
        case mk_configMovingTargetOperation:
            return @"设置运动目标";
        case mk_configDoNotDisturbTimeOperation:
            return @"设置勿扰时段";
        case mk_readSportHeartDataOperation:
            return @"获取运动心率数据";
        case mk_configAlarmClockNumbersOperation:
            return @"设置闹钟组数";
        case mk_readANCSConnectStatusOperation:
            return @"获取手环ancs连接状态";
        case mk_readDialStyleOperation:
            return @"获取手环表盘样式";
        case mk_configDialStyleOperation:
            return @"设置表盘样式";
        case mk_stepChangeMeterMonitoringStatusOperation:
            return @"改变计步监听功能状态";
        case mk_readMemoryDataOperation:
            return @"获取memory数据";
        case mk_readInternalVersionOperation:
            return @"获取内部版本号";
        case mk_readConfigurationParametersOperation:
            return @"获取配置参数";
        case mk_openANCSOperation:
            return @"701手环开启ancs选项";
        case mk_readDateFormatterOperation:
            return @"读取706日期制式";
        case mk_configDateFormatterOperation:
            return @"设置706日期制式";
        case mk_readLanguageOperation:
            return @"读取706当前显示语言";
        case mk_configLanguageOperation:
            return @"设置706当前显示的语言";
        case mk_readVibrationIntensityOfDeviceOperation:
            return @"读取706当前震动强度";
        case mk_configVibrationIntensityOfDeviceOperation:
            return @"设置706当前震动强度";
        case mk_readScreenListOperation:
            return @"读取706屏幕显示列表";
        case mk_configScreenListOperation:
            return @"设置706屏幕显示列表";
        case mk_powerOffDeviceOperation:
            return @"关机设备";
        case mk_clearDeviceDataOperation:
            return @"恢复出厂设置";
        case mk_configStepIntervalOperation:
            return @"设置706计步间隔";
        case mk_readStepIntervalDataOperation:
            return @"读取706间隔计步数据";
        case mk_configSearchPhoneOperation:
            return @"设置搜索手机功能";
        case mk_configCustomDialStyleOperation:
            return @"设置自定义表盘";
        case mk_defaultTaskOperationID:
            return @"";
        default:
            return @"";
    }
}

/**
 监听状态下手环返回的实时计步数据
 
 @param content 手环原始数据
 @return @{}
 */
- (NSDictionary *)getListeningStateStepData:(NSString *)content{
    NSString *stepNumber = [mk_fitpoloAdopter getDecimalStringWithHex:content range:NSMakeRange(0, 8)];
    NSString *activityTime = [mk_fitpoloAdopter getDecimalStringWithHex:content range:NSMakeRange(8, 4)];
    NSString *distance = [NSString stringWithFormat:@"%.1f",(float)[mk_fitpoloAdopter getDecimalWithHex:content range:NSMakeRange(12, 4)] / 10.0];
    NSString *calories = [mk_fitpoloAdopter getDecimalStringWithHex:content range:NSMakeRange(16, 4)];
    
    return @{
             @"stepCount":stepNumber,
             @"sportTime":activityTime,
             @"distance":distance,
             @"burnCalories":calories
             };
}

#pragma mark - setter & getter
- (NSOperationQueue *)operationQueue{
    if (!_operationQueue) {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
    }
    return _operationQueue;
}

@end
