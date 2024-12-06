//
//  CBPeripheral+mk_fitpoloCurrent.m
//  mk_fitpoloCentralManager
//
//  Created by aa on 2018/12/10.
//  Copyright © 2018 mk_fitpolo. All rights reserved.
//

#import "CBPeripheral+mk_fitpoloCurrent.h"
#import <objc/runtime.h>

#pragma mark -
static const char *readDataCharacteristic = "readDataCharacteristic";
static const char *otaCharacteristic = "otaCharacteristic";
static const char *otaNotifyCharacteristic = "otaNotifyCharacteristic";
static const char *xoFrameNotifyCharacteristic = "xoFrameNotifyCharacteristic";
static const char *xoFrameWriteCharacteristic = "xoFrameWriteCharacteristic";
static const char *updateNotifyCharacteristic = "updateNotifyCharacteristic";

static const char *notifySettingDataSuccess = "notifySettingDataSuccess";
static const char *notifyDatapushDataSuccess = "notifyDatapushDataSuccess";
static const char *notifyOtaNotifyDataSuccess = "notifyOtaNotifyDataSuccess";
static const char *notifyXoFrameDataSuccess = "notifyXoFrameDataSuccess";


///charcter
///


@implementation CBPeripheral (mk_fitpoloCurrent)

- (void)updateCurrentCharacteristicsForService:(CBService *)service{
    NSLog(@"service:%@",service.UUID);
    
    if ([service.UUID isEqual:[CBUUID UUIDWithString:setting]]){
        NSArray *charactList = [service.characteristics mutableCopy];
        for (CBCharacteristic *characteristic in charactList) {
                [self setNotifyValue:YES forCharacteristic:characteristic];
                objc_setAssociatedObject(self, &readDataCharacteristic, characteristic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [self updateCurrentNotifySuccess:characteristic];
        }
    }else if([service.UUID isEqual:[CBUUID UUIDWithString:datapush]]){
        NSArray *charactList = [service.characteristics mutableCopy];
        for (CBCharacteristic *characteristic in charactList) {
                [self setNotifyValue:YES forCharacteristic:characteristic];
                objc_setAssociatedObject(self, &updateNotifyCharacteristic, characteristic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [self updateCurrentNotifySuccess:characteristic];
        }
    }else if([service.UUID isEqual:[CBUUID UUIDWithString:ota]]){
        NSArray *charactList = [service.characteristics mutableCopy];
        for (CBCharacteristic *characteristic in charactList) {
            if ([characteristic.UUID.UUIDString isEqualToString:otaWrite]){
                objc_setAssociatedObject(self, &otaCharacteristic, characteristic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }else{
                objc_setAssociatedObject(self, &otaNotifyCharacteristic, characteristic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
    }else if ([service.UUID isEqual:[CBUUID UUIDWithString:xoframe]]){
        NSArray *charactList = [service.characteristics mutableCopy];
        for (CBCharacteristic *characteristic in charactList) {
            if ([characteristic.UUID.UUIDString isEqualToString:xoframeNotify]){
                [self setNotifyValue:YES forCharacteristic:characteristic];
                objc_setAssociatedObject(self, &xoFrameNotifyCharacteristic, characteristic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }else{
                objc_setAssociatedObject(self, &xoFrameWriteCharacteristic, characteristic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            [self updateCurrentNotifySuccess:characteristic];
        }
        
    }
    NSLog(@"xoFrameNotifyCharacteristic:%@",self.xonFrameWrite);
    NSLog(@"xoFrameWriteCharacteristic:%@",self.xonFrameNotify);
}

- (void)updateCurrentNotifySuccess:(CBCharacteristic *)characteristic{
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:setting]]) {
        objc_setAssociatedObject(self, &notifySettingDataSuccess, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:datapush]]){
        objc_setAssociatedObject(self, &notifyDatapushDataSuccess, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:xoframeNotify]]){
        objc_setAssociatedObject(self, &notifyXoFrameDataSuccess, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

-(void)openOtaNotify:(BOOL)state{
    [self setNotifyValue:state forCharacteristic:self.otaNotify];
}

- (BOOL)fitpoloCurrentConnectSuccess{
    if (!self.readData) {
        return NO;
    }
    if (!self.otaData) {
        return NO;
    }
    if (!self.otaNotify) {
        return NO;
    }
    if (!self.xonFrameWrite) {
        return NO;
    }
    if (!self.xonFrameNotify) {
        return NO;
    }
    if (!self.updateNotify) {
        return NO;
    }
    
    if (!self.readData.isNotifying) {
        return NO;
    }
    if (!self.xonFrameNotify.isNotifying) {
        return NO;
    }
    if (!self.updateNotify.isNotifying) {
        return NO;
    }
    NSLog(@"notifyReadData===%d", self.readData.isNotifying);
    NSLog(@"notifySetData===%d", self.xonFrameNotify.isNotifying);
    NSLog(@"notifyHeartData===%d", self.updateNotify.isNotifying);
    return YES;
}

- (void)setFitpoloCurrentCharacteNil{
    objc_setAssociatedObject(self, &readDataCharacteristic, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, &otaCharacteristic, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, &otaNotifyCharacteristic, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, &xoFrameWriteCharacteristic, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, &xoFrameNotifyCharacteristic, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, &updateNotifyCharacteristic, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    objc_setAssociatedObject(self, &notifySettingDataSuccess, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, &notifyDatapushDataSuccess, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, &notifyOtaNotifyDataSuccess, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, &notifyXoFrameDataSuccess, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
//
- (CBCharacteristic *)readData{
    return objc_getAssociatedObject(self, &readDataCharacteristic);
}

//
- (CBCharacteristic *)otaData{
    return objc_getAssociatedObject(self, &otaCharacteristic);
}
//
-(CBCharacteristic *)otaNotify{
    return objc_getAssociatedObject(self, &otaNotifyCharacteristic);
}
//
- (CBCharacteristic *)xonFrameWrite{
    return objc_getAssociatedObject(self, &xoFrameWriteCharacteristic);
}
//
-(CBCharacteristic *)xonFrameNotify{
    return objc_getAssociatedObject(self, &xoFrameNotifyCharacteristic);
}

//
- (CBCharacteristic *)updateNotify{
    return objc_getAssociatedObject(self, &updateNotifyCharacteristic);
}

@end
