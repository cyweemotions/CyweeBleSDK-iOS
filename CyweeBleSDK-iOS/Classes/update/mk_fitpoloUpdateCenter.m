//
//  mk_fitpoloUpdateCenter.m
//  MKFitpolo
//
//  Created by aa on 2019/1/16.
//  Copyright © 2019 MK. All rights reserved.
//

#import "mk_fitpoloUpdateCenter.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "MKUserDataInterface.h"
#import "mk_fitpoloDefines.h"
#import "mk_fitpoloCentralManager.h"
#import "CBPeripheral+mk_fitpoloCurrent.h"
#import "mk_fitpoloAdopter.h"
#import "OTAManager.h"
#import "DailTask.h"

static mk_fitpoloUpdateCenter *updateCenter = nil;
static dispatch_once_t onceToken;

@interface mk_fitpoloUpdateCenter ()<OTAManagerDelegate>

/**
 升级成功回调
 */
@property (nonatomic, copy)mk_fitpoloUpdateProcessSuccessBlock updateSuccessBlock;

/**
 升级失败回调
 */
@property (nonatomic, copy)mk_fitpoloUpdateProcessFailedBlock updateFailedBlock;

/**
 升级进度回调
 */
@property (nonatomic, copy)mk_fitpoloUpdateProgressBlock updateProgressBlock;

@property (nonatomic, copy)mk_fitpoloUpdateBlock updataBlock;
/**
 当前文件数
 */
@property (nonatomic, assign)NSInteger currentFileIndex;
/*
 文件总数
 */
@property (nonatomic, assign)NSInteger allFileSize;

/// 当前文件byte数
@property (nonatomic, assign)NSInteger currentFileSize;

/// 发送的包数
@property (nonatomic, assign)NSInteger currentOffset;

/// 总包数
@property (nonatomic, assign)NSInteger totalPackages;

/// 当前穿文件的内容
@property (nonatomic, strong)NSData *currentTrans;

/// 文件路径数组
@property (nonatomic, strong)NSArray *filePathContents;

///定时器
@property (nonatomic, strong)dispatch_source_t timeOut;
@end

@implementation mk_fitpoloUpdateCenter

#pragma mark - life circle
- (void)dealloc{
    NSLog(@"升级中心销毁");
    [[NSNotificationCenter defaultCenter] removeObserver:self name:mk_peripheralUpdateResultNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:mk_peripheralConnectStateChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:mk_dailResponseNotification object:nil];
}

- (instancetype)init{
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(peripheralConnectStateChanged)
                                                     name:mk_peripheralConnectStateChangedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateResultNotification:)
                                                     name:mk_peripheralUpdateResultNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateDailNotification:)
                                                     name:mk_dailResponseNotification
                                                   object:nil];
        _otaManager = [[OTAManager alloc] init];
    }
    return self;
}

+ (mk_fitpoloUpdateCenter *)sharedInstance{
    dispatch_once(&onceToken, ^{
        if (!updateCenter) {
            updateCenter = [[mk_fitpoloUpdateCenter alloc] init];
        }
    });
    return updateCenter;
}
                  
                  
+ (void)attempDealloc {
    onceToken = 0;
    updateCenter = nil;
}
///OTA升级开始
- (void)updateOtaFromPath:(NSString *)path{
    ///1.先把OTA的特征订阅了
    ///2.设置文件路径
    ///3.ota升级准备
    ///4.开始升级
    self.otaManager.delegate = self;
    [[mk_fitpoloCentralManager sharedInstance].connectedPeripheral openOtaNotify:YES];
    [self.otaManager setOTAFile:path];
    [self.otaManager prepare];
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        __strong typeof(self) self = weakSelf;
        NSLog(@"开始升级");
        [self.otaManager upgrade];
    });
    ///5.其他相应在回调函数中 delegate
}


/**
 升级结果通知，开始发送第一帧升级数据的时候开始注册监听结果，最后一帧数据发送的时候需要移除监听，改由开启升级结果任务的方式监听升级结果
 
 @param obj 升级过程中接收到的升级结果，基本上就是一些升级错误原因
 */
- (void)updateResultNotification:(NSNotification *)obj{
    NSDictionary * dataDic = [obj userInfo];
    NSData *data = dataDic[@"data"];
    NSLog(@"数据返回");
    [self.otaManager receiveData:data];
}

- (NSUInteger) getMtuForType:(CBCharacteristicWriteType) type {
  return [[mk_fitpoloCentralManager sharedInstance].connectedPeripheral maximumWriteValueLengthForType:type];
}

#pragma mark - ***********************OTAManager Delegate************************
- (void)sendData:(NSData *) data{
    NSUInteger mtu = [self getMtuForType:CBCharacteristicWriteWithoutResponse];
    for (NSUInteger index = 0; index < data.length; index += mtu) {
        NSUInteger len = (data.length - index) > mtu ? mtu : (data.length - index);
        NSData *value = [data subdataWithRange:NSMakeRange(index, len)];
        [[mk_fitpoloCentralManager sharedInstance] sendUpdateData:value];
        NSLog(@"writeValue1: %@", value);
    }
}
- (void)sendData:(NSData *)data index:(int) i{
    NSUInteger mtu = [self getMtuForType:CBCharacteristicWriteWithoutResponse];
    for (NSUInteger index = 0; index < data.length; index += mtu) {
        NSUInteger len = (data.length - index) > mtu ? mtu : (data.length - index);
        NSData *value = [data subdataWithRange:NSMakeRange(index, len)];
        if(i != 0 && i % 62 == 0) {
            NSData *value2 = [value subdataWithRange:NSMakeRange(0, 1)];
            NSData *value3 = [value subdataWithRange:NSMakeRange(1, value.length - 1)];
            CBCharacteristic *character = [mk_fitpoloCentralManager sharedInstance].connectedPeripheral.otaData;
            [[mk_fitpoloCentralManager sharedInstance].connectedPeripheral writeValue:value2
                               forCharacteristic:character
                                            type:CBCharacteristicWriteWithResponse];
            [[mk_fitpoloCentralManager sharedInstance] sendUpdateData:value3];
            NSLog(@"writeValue WithResponse: %@", value);
        } else {
            [[mk_fitpoloCentralManager sharedInstance] sendUpdateData:value];
            NSLog(@"writeValue WithoutResponse: %@", value);
        }
    }
}

- (void)receiveSpeed:(NSInteger) speed{
    NSString *progress = [NSString stringWithFormat:@"%d-%d",speed,self.otaManager.fileSize];
    NSLog(@"传输进度:%@",progress);
    CGFloat value = speed*1.00 /self.otaManager.fileSize;
    NSLog(@"传输进度:%lf",value);
    if(self.progressCallBack){
        self.progressCallBack(value);
    }
}
- (void)onStatus:(OTAStatus) state{

}
- (void)onError:(NSInteger) errCode{

}

#pragma mark - ***********************Dail update************************

/// 开启表盘多文件解析和上传
/// - Parameters:
///   - filePaths: 文件路径数组
///   - allFileSize: 所有文件大小
-(void)startDailFileSync:(NSArray<NSString *> *)filePaths size:(NSInteger)allFileSize{
    
    NSLog(@"开始发送文件");
    if(filePaths.count <= 0) return;
    ///记录文件路径
    self.filePathContents = filePaths;
    ///记录总大小
    self.allFileSize = allFileSize;
    ///记录文件数量
    self.currentFileSize = filePaths.count;
    ///记录当前文件index
    self.currentFileIndex = 0;
    ///读取第一个文件
    NSData *data = [self readFileContent:filePaths.firstObject];
    ///获取名称
    NSString *fileName = filePaths.firstObject;
    fileName = [fileName componentsSeparatedByString:@"/"].lastObject;
    ///开始发送第一个文件包
    NSLog(@"文件名称:%@",fileName);
    [self sendDailFileDetail:self.currentFileIndex fileName:fileName content:data];
}
//MARK: 读取文件信息
-(NSData *)readFileContent:(NSString *)filePath{
    if(filePath.length <= 0) return nil;
    ///读取文件内容
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    ///读取文件名称
    return fileData;
}

//MARK: 发送文件开始
-(void)sendDailFileDetail:(NSInteger)fileIndex fileName:(NSString *)fileName content:(NSData *)fileContent{
    NSLog(@"sendDailFileDetail");
    ///发送文件开始包 创建发送数据 [-91, -93, 2, 0, 10, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 19, -80]
    ///0xa5a3 0200 0a00 0200 0000 0000 0000 0006 7376
    NSMutableData *data = [DailTask DailTask:DIAL_FILE_START isFirst:NO isMulti:false fileCount:0 datas:[NSData data]];
    __weak __typeof(&*self)weakSelf = self;
    self.updataBlock = ^(NSData * _Nonnull obj, NSInteger state) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSLog(@"sendDailFileDetail数据返回");
        if(state == 1){
            NSArray<NSNumber *> *nameLength =  [mk_fitpoloAdopter convert:fileName.length byteType:mk_word];
            nameLength = [[nameLength reverseObjectEnumerator] allObjects];
            NSData *nameLengthData = [mk_fitpoloAdopter dataFromArray:nameLength];
            NSData *filenameData = [mk_fitpoloAdopter dataWithHexString:[mk_fitpoloAdopter hexStringFromString:fileName]];
            NSLog(@"sendDailFileDetail数据返回:%@--%@",nameLengthData,filenameData);
            [strongSelf sendFileInfo:nameLengthData nameData:filenameData fileData:fileContent];
        }
    };
    [self setTimeOut];
    [[mk_fitpoloCentralManager sharedInstance] sendDailData:data];

}

/// 发送文件信息
/// - Parameters:
///   - length: 文件名长度
///   - nameData: 文件名data
///   - fileData: 文件内容data
-(void)sendFileInfo:(NSData *)length nameData:(NSData *)nameData fileData:(NSData *)fileData{
    NSMutableData *sendData = [NSMutableData data];
    [sendData appendData:length];
    [sendData appendData:nameData];
    NSMutableData *data = [DailTask DailTask:DIAL_FILE_INFO isFirst:NO isMulti:NO fileCount:0 datas:sendData];
    NSLog(@"sendFileInfo数据:%@",[data subdataWithRange:NSMakeRange(0, 22)]);
    __weak __typeof(&*self)weakSelf = self;
    self.updataBlock = ^(NSData * _Nonnull obj, NSInteger state) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if(state == 1){
            NSLog(@"sendFileInfo数据返回");
            [strongSelf sendMutiInfo:fileData];
        }
    };
    [self reRunTimer];
    [[mk_fitpoloCentralManager sharedInstance] sendDailData:data];
}

/// 发送多包信息包
/// - Parameter fileData: 文件包
-(void)sendMutiInfo:(NSData *)fileData{
    NSMutableData *sendData = [NSMutableData data];
    ///发送多包信息
    NSInteger sendLength = [mk_fitpoloCentralManager sharedInstance].mtu  - 12;
    double p = floor(fileData.length / sendLength*1.0);
    NSInteger Packages = (NSInteger)p;
    if(fileData.length % sendLength > 0){
        Packages++;
    }
    NSLog(@"sendMutiInfo发送数据:%d-%.2f-%d-%d",Packages,p,fileData.length,sendLength);
    NSArray<NSNumber *> *packageLength = [mk_fitpoloAdopter convert:Packages byteType:mk_dword];
    packageLength = [[packageLength reverseObjectEnumerator] allObjects];
    NSData *packageLengthData = [mk_fitpoloAdopter dataFromArray:packageLength];
    [sendData appendData:packageLengthData];
    NSArray<NSNumber *> *fileDataLength = [mk_fitpoloAdopter convert:fileData.length+10 byteType:mk_dword];
    fileDataLength = [[fileDataLength reverseObjectEnumerator] allObjects];
    NSData *fileDataLengthData = [mk_fitpoloAdopter dataFromArray:fileDataLength];
    [sendData appendData:fileDataLengthData];
    NSMutableData *data = [DailTask DailTask:xon_frame_type_multi_info isMulti:YES onlyXOF:YES datas:sendData];
    NSLog(@"sendMutiInfo发送数据:%@",sendData);
        ///成功后
    __weak __typeof(&*self)weakSelf = self;
    self.updataBlock = ^(NSData * _Nonnull obj, NSInteger state) {
        NSLog(@"sendMutiInfo数据返回");
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if(state == 1){
            NSData *firstData = [fileData subdataWithRange:NSMakeRange(0, [mk_fitpoloCentralManager sharedInstance].mtu-22)];
            NSData *secondData =   [fileData subdataWithRange:NSMakeRange(firstData.length, fileData.length-firstData.length)];
            strongSelf.currentTrans = secondData;
            NSLog(@"sendMutiInfo数据返回%d-%d",firstData.length,fileData.length-firstData.length);
            NSLog(@"sendMutiInfo数据返回:%d",secondData.length);
            [strongSelf sendFileMutil:firstData fileData:fileData second:secondData];
        }
    };
    [self reRunTimer];
    [[mk_fitpoloCentralManager sharedInstance] sendDailData:data];
    
}


/// 发送前两包
/// - Parameters:
///   - first: 首包数据
///   - fileData: 整包数据
///   - second: 第二包数据
-(void)sendFileMutil:(NSData *)first fileData:(NSData *)fileData second:(NSData *)second{
    NSLog(@"sendFileMutil数据发送:%d",first.length);
    ///同时把第一包和第二包发过去
    ///第一包不用等返回，但是第一包需要裁掉10byte
    NSMutableData *data = [DailTask DailTask:DIAL_FILE_SEND isFirst:YES isMulti:YES fileCount:fileData.length datas:first];
    NSLog(@"sendFileMutil数据发送second:%@",[data subdataWithRange:NSMakeRange(0, 22)]);
    __weak __typeof(&*self)weakSelf = self;
    self.updataBlock = ^(NSData * _Nonnull obj, NSInteger state) {
        NSLog(@"sendFileMutil数据返回");
    };
    [[mk_fitpoloCentralManager sharedInstance] sendDailData:data];
    NSLog(@"第一包:%@",data);
    ///第二包需要等返回
    self.currentFileSize = self.currentFileSize + first.length;
    NSInteger sendLength = [mk_fitpoloCentralManager sharedInstance].mtu - 12;
    double p = floor(second.length / (sendLength*1.0));
    NSInteger Packages = (NSInteger)p;
    if(fileData.length % sendLength > 0){
        Packages++;
    }
    NSLog(@"sendFileMutil数据发送:%d-%d",second.length,Packages);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self sendMultiData:1 datas:second packages:Packages];
    });

}


/// 发送数据包
/// - Parameters:
///   - offset: 包的位置
///   - datas: 数据
///   - packages: 包的index
-(void)sendMultiData:(NSInteger)offset datas:(NSData *)fileData packages:(NSInteger)packages{
    self.totalPackages = packages;
    self.currentOffset = offset - 1;
    NSLog(@"sendMultiData数据发送:%d-%d",_currentOffset,_totalPackages);
    ///发送数据包
    ///当前数据包长度不大于总包长度继续下一个包
    ///否则进入文件结束CRC校验
    NSMutableData *totalData = [NSMutableData data];
    NSMutableData *sendData = [NSMutableData data];
    NSInteger mtu = [mk_fitpoloCentralManager sharedInstance].mtu-12;
    NSArray<NSNumber *> *offsetLength = [mk_fitpoloAdopter convert:offset byteType:mk_dword];
    offsetLength = [[offsetLength reverseObjectEnumerator] allObjects];
    NSData *offsetLengthData = [mk_fitpoloAdopter dataFromArray:offsetLength];
    ///判断是否是最后一包
    if((fileData.length - self.currentOffset*mtu) >= mtu){
        ///不是最后一包
        sendData = [fileData subdataWithRange:NSMakeRange(self.currentOffset*mtu, mtu)];
        NSLog(@"sendMultiData数据发送:%d",sendData.length);
    }else{
        sendData = [fileData subdataWithRange:NSMakeRange(self.currentOffset*mtu, (fileData.length - self.currentOffset*mtu))];
        NSLog(@"sendMultiData数据发送:%d",sendData.length);
    }
    [totalData appendData:offsetLengthData];
    [totalData appendData:sendData];
    self.currentFileSize = self.currentFileSize+sendData.length;
    NSMutableData *data = [DailTask DailTask:xon_frame_type_multi isMulti:YES onlyXOF:YES datas:totalData];
    NSLog(@"sendMultiData offset数据发送:%@",[data subdataWithRange:NSMakeRange(0, 10)]);
    __weak __typeof(&*self)weakSelf = self;
    self.updataBlock = ^(NSData * _Nonnull obj, NSInteger state) {
        NSLog(@"sendMultiData数据返回0");
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if((state == 1) && (obj.length > 1)){
            NSData *firstData = [obj subdataWithRange:NSMakeRange(0, 2)];
            int res = 0;
            [firstData getBytes:&res length:sizeof(res)];
            NSLog(@"sendMultiData数据返回1:%d",res);
            NSLog(@"sendMultiData数据返回1:%@",firstData);
            if(res == 1){  //成功
                NSLog(@"sendMultiData数据返回2");
                strongSelf.currentOffset = strongSelf.currentOffset + 2;
                CGFloat prcent = strongSelf.currentFileSize * 1.00 / strongSelf.allFileSize;
                NSLog(@"sendMultiData数据发送了:%.2f",prcent);
                if(strongSelf.progressCallBack){
                    strongSelf.progressCallBack(prcent);
                }
                if(strongSelf.currentOffset > strongSelf.totalPackages){
                    ///当前文件的最后一包
                    ///发送CRC
                    [strongSelf sendCrc];
                }else{
                    [strongSelf sendMultiData:strongSelf.currentOffset datas:strongSelf.currentTrans packages:strongSelf.totalPackages];
                }
            }
                    
        }
    };
    [self reRunTimer];
    [[mk_fitpoloCentralManager sharedInstance] sendDailData:data];
}
//MARK: 发送文件CRC
-(void)sendCrc{
    NSLog(@"开始发送整个文件的CRC");
    NSUInteger value = [mk_fitpoloAdopter crc16CcittFalse:self.currentTrans];
    NSArray<NSNumber *> *offsetLength = [mk_fitpoloAdopter convert:value byteType:mk_word];
    ///当前文件的CRC校验
    NSData *offsetLengthData = [mk_fitpoloAdopter dataFromArray:offsetLength];
    NSMutableData *data = [DailTask DailTask:xon_frame_type_multi_crc isMulti:YES onlyXOF:YES datas:offsetLengthData];
    __weak __typeof(&*self)weakSelf = self;
    self.updataBlock = ^(NSData * _Nonnull obj, NSInteger state) {
        ///返回成功后文件总数index++
        ///0x0400de1dde00
        NSLog(@"sendCrc数据返回");
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.currentFileIndex++;
        if(strongSelf.currentFileIndex < strongSelf.filePathContents.count){
            ///继续传下一个文件
            NSString *name = strongSelf.filePathContents[strongSelf.currentFileIndex];
            ///获取文件内容
            NSData *datas = [strongSelf readFileContent:name];
            ///4.开始发送文件握手包
            NSString *fileName = [name componentsSeparatedByString:@"/"].lastObject;
            NSArray<NSNumber *> *nameLength =  [mk_fitpoloAdopter convert:fileName.length byteType:mk_word];
            nameLength = [[nameLength reverseObjectEnumerator] allObjects];
            NSData *nameLengthData = [mk_fitpoloAdopter dataFromArray:nameLength];
            NSData *filenameData = [mk_fitpoloAdopter dataWithHexString:[mk_fitpoloAdopter hexStringFromString:fileName]];
            [strongSelf sendFileInfo:nameLengthData nameData:filenameData fileData:datas];
        }else{
            ///传输停止
            [strongSelf dailFileStop];
        }
    };
    [self reRunTimer];
    ///发送校验数据
    [[mk_fitpoloCentralManager sharedInstance] sendDailData:data];
}

/// 文件传输停止
-(void)dailFileStop{
    [self cancelTimer];
    self.updataBlock = nil;
    NSMutableData *sendData = [NSMutableData data];
    Byte *buffer = (Byte *)malloc(1);
    buffer[0] = (Byte) 0x04;
    NSData *header = [NSData dataWithBytes:buffer length:1];
    [sendData appendData:header];
    NSMutableData *data = [DailTask DailTask:DIAL_FILE_STOP isFirst:NO isMulti:NO fileCount:0 datas:sendData];
    [[mk_fitpoloCentralManager sharedInstance] sendDailData:data];
}

/// 定时器
-(void)setTimeOut{
    [self cancelTimer];
    self.timeOut = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,dispatch_get_main_queue());
    dispatch_source_set_timer(self.timeOut, dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC),  3 * NSEC_PER_SEC, 0);
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(self.timeOut, ^{
        NSLog(@"触发超时");
        if(weakSelf.failedBlock){
            weakSelf.failedBlock(nil);
        }
        dispatch_source_cancel(weakSelf.timeOut);
    });
    dispatch_resume(self.timeOut);
}

-(void)reRunTimer{
    [self pauseTimer];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self resumeTimer];
    });
}

-(void)pauseTimer{
    if(self.timeOut){
        dispatch_suspend(_timeOut);
    }
}
-(void)resumeTimer{
    if(self.timeOut){
        dispatch_source_set_timer(_timeOut, dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC),  3 * NSEC_PER_SEC, 0);
        dispatch_resume(_timeOut);
    }
}

-(void)cancelTimer{
    if (self.timeOut) {
        dispatch_source_cancel(_timeOut);
    }
}

/**
 数据相应方法
 */
-(void)updateDailNotification:(NSNotification *)obj{
    NSDictionary * dataDic = [obj userInfo];
    NSData *data = dataDic[@"data"];
    NSLog(@"表盘数据返回原始数据:%@",data);
    [DailTask parseValue:data callBack:^(NSData *datas, NSInteger state) {
        NSLog(@"表盘数据返回解析数据:%@,返回状态:%d",datas,state);
        if(self.updataBlock){
            self.updataBlock(datas,state);
        }
    }];
}

@end
