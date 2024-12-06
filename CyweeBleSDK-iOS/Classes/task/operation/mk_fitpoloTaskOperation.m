//
//  mk_fitpoloTaskOperation.m
//  mk_fitpoloCentralManager
//
//  Created by aa on 2018/12/10.
//  Copyright © 2018 mk_fitpolo. All rights reserved.
//

#import "mk_fitpoloTaskOperation.h"
#import "mk_fitpolo701Parser.h"
#import "mk_fitpoloCurrentParser.h"

NSString *const mk_additionalInformation = @"mk_additionalInformation";
NSString *const mk_dataInformation = @"mk_dataInformation";
NSString *const mk_dataStatusLev = @"mk_dataStatusLev";

@interface mk_fitpoloTaskOperation ()

/**
 对于需要先接收到总的数据条数才能确定本次通信成功所需要的数据总条数的任务，先开启条数接受定时器，如果没有接收到总条数，则直接超时
 */
@property (nonatomic, strong)dispatch_source_t numTaskTimer;

/**
 超过2s没有接收到新的数据，超时
 */
@property (nonatomic, strong)dispatch_source_t receiveTimer;

/**
 总的数据条数
 */
@property (nonatomic, assign)NSInteger respondNumber;

/**
 线程结束时候的回调
 */
@property (nonatomic, copy)void (^completeBlock) (NSError *error, mk_taskOperationID operationID, id returnData);

@property (nonatomic, copy)void (^commandBlock)(void);

@property (nonatomic, strong)NSMutableArray *dataList;

/**
 超时标志
 */
@property (nonatomic, assign)BOOL timeout;

/**
 接受数据超时个数
 */
@property (nonatomic, assign)NSInteger receiveTimerCount;

/**
 是否需要改变目标数据条数
 */
@property (nonatomic, assign)BOOL needResetNum;

/**
 需要从外部设备获取条数信息等附加信息的时候，需要把这些附加信息也返回
 */
@property (nonatomic, strong)NSDictionary *additionalInformation;

/**
 对于需要拿个数的任务，如果已经接受了个数，则应该关闭接受新的个数
 */
@property (nonatomic, assign)BOOL hasReceive;

/**
 由于业务罗需要，对于计步、睡眠、心率数据，如果超时的时候接收到了部分数据，也认为是接受成功
 */
@property (nonatomic, assign)BOOL needPartOfData;

@property (nonatomic, assign)mk_fitpoloDeviceType deviceType;

@end

@implementation mk_fitpoloTaskOperation
@synthesize executing = _executing;
@synthesize finished = _finished;

#pragma mark - life circle

- (void)dealloc{
    NSLog(@"任务销毁");
}

/**
 初始化通信线程
 
 @param operationID 当前线程的任务ID
 @param resetNum 是否需要根据外设返回的数据总条数来修改任务需要接受的数据总条数，YES需要，NO不需要
 @param commandBlock 发送命令回调
 @param completeBlock 数据通信完成回调
 @return operation
 */
- (instancetype)initOperationWithID:(mk_taskOperationID)operationID
                         deviceType:(mk_fitpoloDeviceType)deviceType
                           resetNum:(BOOL)resetNum
                       commandBlock:(void (^)(void))commandBlock
                      completeBlock:(void (^)(NSError *error, mk_taskOperationID operationID, id returnData))completeBlock{
    if (self = [super init]) {
        _executing = NO;
        _finished = NO;
        _completeBlock = completeBlock;
        _commandBlock = commandBlock;
        _operationID = operationID;
        _respondNumber = 1;
        _needResetNum = resetNum;
        _deviceType = deviceType;
        _needPartOfTimeout = 0.f;
    }
    return self;
}

#pragma mark - super method

- (void)start{
    if (self.isFinished || self.isCancelled) {
        [self willChangeValueForKey:@"isFinished"];
        _finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    [self willChangeValueForKey:@"isExecuting"];
    _executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self startCommunication];
}

#pragma mark - CBPeripheralDelegate
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"read data from peripheral error:%@", [error localizedDescription]);
        return;
    }
    if (!characteristic || self.deviceType == mk_fitpoloUnknow) {
        return;
    }
    if (self.deviceType == mk_fitpolo701) {
        [self dataParserReceivedData:[mk_fitpolo701Parser parseReadData:characteristic]];
        return;
    }
    [self dataParserReceivedData:[mk_fitpoloCurrentParser parseReadDataFromCharacteristic:characteristic]];
}

#pragma mark - Private method
- (void)startCommunication{
    if (self.isCancelled) {
        return;
    }
    if (self.commandBlock) {
        self.commandBlock();
    }
//    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//    __weak __typeof(&*self)weakSelf = self;
//    //需要从外设拿当前通信的总条数
//    if (self.needResetNum) {
//        self.numTaskTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
//        dispatch_source_set_timer(self.numTaskTimer,dispatch_walltime(NULL, 0),1.f * NSEC_PER_SEC, 0); //每秒执行
//        __block NSUInteger interval = 5;
//        dispatch_source_set_event_handler(self.numTaskTimer, ^{
//            if (weakSelf.timeout || interval <= 0) {
//                [weakSelf communicationTimeout];
//                return ;
//            }
//            interval --;
//        });
//        //如果需要从外设拿总条数，则在拿到总条数之后，开启接受超时定时器
//        dispatch_resume(self.numTaskTimer);
//        return;
//    }
    //如果不需要重新获取条数，直接开启接受超时
    self.timeout = YES;
    [self startReceiveTimer];
}

/**
 如果需要从外设拿总条数，则在拿到总条数之后，开启接受超时定时器，开启定时器的时候已经设置了当前线程的生命周期，所以不需要重新beforeDate了。如果是直接开启的接收超时定时器，这个时候需要控制当前线程的生命周期
 
 */
- (void)startReceiveTimer{
    if (self.isCancelled) {
        return;
    }
    __weak __typeof(&*self)weakSelf = self;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.receiveTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    //当2s内没有接收到新的数据的时候，也认为是接受超时
    NSInteger timeout = MAX(self.needPartOfTimeout, 5);
    dispatch_source_set_timer(self.receiveTimer, dispatch_time(DISPATCH_TIME_NOW, timeout * NSEC_PER_SEC),  timeout * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(self.receiveTimer, ^{
        if (weakSelf.timeout) {
            //接受数据超时
            NSLog(@"startReceiveTimer");
            [weakSelf communicationTimeout];
            return ;
        }
    });
    //如果需要从外设拿总条数，则在拿到总条数之后，开启接受超时定时器
    dispatch_resume(self.receiveTimer);
}

- (void)cancelReceiverTimer{
    if (self.receiveTimer) {
        dispatch_cancel(self.receiveTimer);
    }
    [self finishOperation];
}

- (void)finishOperation{
    [self willChangeValueForKey:@"isExecuting"];
    _executing = NO;
    [self didChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    _finished = YES;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)communicationTimeout{
    self.timeout = YES;
    if (self.numTaskTimer) {
        dispatch_cancel(self.numTaskTimer);
    }
    if (self.receiveTimer) {
        dispatch_cancel(self.receiveTimer);
    }
    [self finishOperation];
    if (self.completeBlock) {
        NSLog(@"communicationTimeout");
            //由于业务罗需要，对于计步、睡眠、心率数据，如果超时的时候接收到了部分数据，也认为是接受成功
            NSDictionary *resultDic = @{
                                        mk_additionalInformation:(self.additionalInformation ?: @{}),
                                        mk_dataInformation:self.dataList,
                                        //对于有附加信息的，lev为2，对于普通不包含附加信息的，lev为1.
                                        mk_dataStatusLev:(self.additionalInformation ? @"2" : @"1"),
                                        };
            if (self.completeBlock) {
                self.completeBlock(nil, self.operationID, resultDic);
            }
            return;
    }
}
//单包
- (void)communicationSuccess{
    self.timeout = NO;
    if (self.numTaskTimer) {
        dispatch_cancel(self.numTaskTimer);
    }
    if (self.receiveTimer) {
        dispatch_cancel(self.receiveTimer);
    }
    [self finishOperation];
    //接受数据成功
    NSDictionary *resultDic = @{
                                mk_additionalInformation:(self.additionalInformation ?: @{}),
                                mk_dataInformation:self.dataList,
                                //对于有附加信息的，lev为2，对于普通不包含附加信息的，lev为1.
                                mk_dataStatusLev:@"2",
                                };
    if (self.completeBlock) {
        NSLog(@"communicationSuccess");
        self.completeBlock(nil, self.operationID, resultDic);
    }
}

//多包
- (void)communicationCallBack{
    //接受数据成功
    NSDictionary *resultDic = @{
                                mk_additionalInformation:(self.additionalInformation ?: @{}),
                                mk_dataInformation:self.dataList,
                                //对于有附加信息的，lev为2，对于普通不包含附加信息的，lev为1.
                                mk_dataStatusLev:@"1",
                                };
    if (self.completeBlock) {
        NSLog(@"communicationCallBack");
        self.completeBlock(nil, self.operationID, resultDic);
    }
}

- (void)setRespondCount:(NSString *)respondNumber{
    if (!mk_validStr(respondNumber)) {
        return;
    }
    _respondNumber = [respondNumber integerValue];
}

- (void)needPartOfData:(NSNumber *)need{
    _needPartOfData = [need boolValue];
}

- (void)dataParserReceivedData:(NSDictionary *)dataDic{
    NSLog(@"dataParserReceivedData");
    NSDictionary *returnData = dataDic[@"returnData"];
    NSString *numString = returnData[mk_communicationDataNum];
    //本条数据是总数信息
    //如果需要拿总条数，则总条数必须在正式的数据到来之前到达，否则认为出错
    //认为接受数据总条数成功
    self.additionalInformation = returnData;
    self.hasReceive = YES;
    //已经接受了个数信息，再有新的个数信息到来，直接过滤
    ///2.如果设置了接收时长超过needPartOfTimeout 那么执行超时
    if(self.needPartOfTimeout > 0){
        ///3.说明存在多包
        if (self.numTaskTimer) {
            //关闭总数接受定时器
            dispatch_cancel(self.numTaskTimer);
        }
        //先关闭定时器
//        if (self.receiveTimer) {
//            //关闭总数接受定时器
//            dispatch_suspend(self.receiveTimer);
//        }
        //开启接受超时定时器
        [self startReceiveTimer];
//        [self.dataList addObject:returnData];
        ///4.设置的needPartOfTimeout时间后执行数据成功
        [self communicationCallBack];
    }else{
        ///4.单包返回
        [self communicationSuccess];
        return;
    }


//    if (self.needResetNum && !self.hasReceive) {
//        //需要从外设拿数据总条数的情况下，如果数据先于数据到来，不接收
//        return;
//    }
//    self.receiveTimerCount = 0;
//    if (self.timeout) {
//        return;
//    }
//    [self.dataList addObject:returnData];
//    if (self.dataList.count == self.respondNumber) {
//        NSLog(@"如果有数据====");
//        [self communicationSuccess];
//    }

}

#pragma mark - setter & getter
- (BOOL)isConcurrent{
    return YES;
}

- (BOOL)isFinished{
    return _finished;
}

- (BOOL)isExecuting{
    return _executing;
}

- (NSMutableArray *)dataList{
    if (!_dataList) {
        _dataList = [NSMutableArray array];
    }
    return _dataList;
}

@end
