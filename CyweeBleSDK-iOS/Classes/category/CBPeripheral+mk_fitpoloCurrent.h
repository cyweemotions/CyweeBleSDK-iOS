//
//  CBPeripheral+mk_fitpoloCurrent.h
//  mk_fitpoloCentralManager
//
//  Created by aa on 2018/12/10.
//  Copyright © 2018 mk_fitpolo. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

///service
static const NSString *xoframe = @"9527";
static const NSString *xoframeWrite = @"9528";
static const NSString *xoframeNotify = @"9529";
static const NSString *ota = @"E49A25F8-F69A-11E8-8EB2-F2801F1B9FD1";
static const NSString *otaWrite = @"E49A25E0-F69A-11E8-8EB2-F2801F1B9FD1";
static const NSString *otaIndicate = @"E49A28E1-F69A-11E8-8EB2-F2801F1B9FD1";
static const NSString *setting = @"E49A23C0-F69A-11E8-8EB2-F2801F1B9FD1";
static const NSString *setCharcter = @"e49a24c1-f69a-11e8-8eb2-f2801f1b9fd1";
static const NSString *datapush = @"E49A25C0-F69A-11E8-8EB2-F2801F1B9FD1";
static const NSString *datapushCharcter = @"e49a26c1-f69a-11e8-8eb2-f2801f1b9fd1";

NS_ASSUME_NONNULL_BEGIN

@interface CBPeripheral (mk_fitpoloCurrent)

@property (nonatomic, strong, readonly)CBCharacteristic *readData;

@property (nonatomic, strong, readonly)CBCharacteristic *otaData;

@property (nonatomic, strong, readonly)CBCharacteristic *otaNotify;

@property (nonatomic, strong, readonly)CBCharacteristic *xonFrameWrite;

@property (nonatomic, strong, readonly)CBCharacteristic *xonFrameNotify;

@property (nonatomic, strong, readonly)CBCharacteristic *updateNotify;

- (void)updateCurrentCharacteristicsForService:(CBService *)service;
- (void)updateCurrentNotifySuccess:(CBCharacteristic *)characteristic;
- (BOOL)fitpoloCurrentConnectSuccess;
- (void)setFitpoloCurrentCharacteNil;
- (void)openOtaNotify:(BOOL)state;

@end

NS_ASSUME_NONNULL_END
