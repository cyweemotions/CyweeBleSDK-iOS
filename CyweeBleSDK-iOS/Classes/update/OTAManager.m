//
//  OTAManager.m
//  ActsBluetoothOTA
//
//  Created by inidhu on 2019/5/20.
//  Copyright © 2019 Actions. All rights reserved.
//

#import "OTAManager.h"
#import "mk_fitpoloAdopter.h"

@implementation OTAManager {
    NSMutableData *receiveBuffer;
    
    NSInteger waitTimeout;
    NSInteger restartTimeout;
    NSInteger otaUnit;
    NSInteger interval;
    NSInteger ackEnable;
    
    NSString *fwVersion;
    NSData *vRAM;
    NSInteger otaMode;
    NSInteger batteryThreshold;
    
    NSData *otaFileData;
    
    NSTimer *timeoutTimer;
    
    BOOL remoteCrcSupport;
    
    NSInteger mWriteBytes;
}

- (id)init {
    self = [super init];
    
    fwVersion = @"1.01";
    otaMode = 0;
    batteryThreshold = 30;
    remoteCrcSupport = NO;
    
    return self;
}

- (BOOL)setOTAFile:(NSString *) path {
    NSLog(@"文件大小:%@,size:%ld",otaFileData,self.fileSize);
    if (path.length <= 0)
        return NO;
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
    otaFileData = [handle readDataToEndOfFile];
    self.fileSize = otaFileData.length;
    NSLog(@"文件大小:%@,size:%ld",otaFileData,self.fileSize);
    return YES;
}

- (NSString *)getOTAVersion {
    NSData *data = [otaFileData subdataWithRange:NSMakeRange(0, 4)];
    NSString *magic = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([magic isEqualToString:@"AOTA"]) {
        data = [otaFileData subdataWithRange:NSMakeRange(64, 32)];
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } else {
        data = [otaFileData subdataWithRange:NSMakeRange(12, 4)];
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
}

- (void)scheduleTimeoutTimer {
    [self removeTimeoutTimer];
    
    timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(timeoutReport) userInfo:nil repeats:NO];
}

- (void)removeTimeoutTimer {
    if (timeoutTimer) {
        [timeoutTimer invalidate];
    }
}

- (void)timeoutReport {
    [self notifyStatus:STATE_UNKNOWN];
}

- (void)readOTAHeader {
    NSData *data = [otaFileData subdataWithRange:NSMakeRange(0, 4)];
    NSString *magic = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([magic isEqualToString:@"AOTA"]) {
        data = [otaFileData subdataWithRange:NSMakeRange(64, 32)];
        fwVersion = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        Byte placeholder[16] = {0x00};
        vRAM = [NSData dataWithBytes:placeholder length:16];
    } else {
        data = [otaFileData subdataWithRange:NSMakeRange(12, 4)];
        fwVersion = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        vRAM = [otaFileData subdataWithRange:NSMakeRange(56, 16)];
    }
}

- (void)checkRemoteStatus {
    NSMutableArray *tlvs = [[NSMutableArray alloc] init];
    
    // package version
    NSData *tlv = [self assembleType:0x01 length:fwVersion.length value:[fwVersion dataUsingEncoding:NSUTF8StringEncoding]];
    [tlvs addObject:tlv];
    
    // component size
    Byte valueSize[2] = {0x00, 0x00};
    tlv = [self assembleType:0x02 length:2 value:[NSData dataWithBytes:valueSize length:2]];
    [tlvs addObject:tlv];
    
    // VRAM
    tlv = [self assembleType:0x03 length:vRAM.length value:vRAM];
    [tlvs addObject:tlv];
    
    // ota work mode
    Byte valueMode[1] = {(Byte)otaMode};
    tlv = [self assembleType:0x04 length:1 value:[NSData dataWithBytes:valueMode length:1]];
    [tlvs addObject:tlv];
    
    // feature support: Support CRC32 Checksum
     Byte valueFeature[1] = {(Byte)0x1};
     tlv = [self assembleType:0x09 length:1 value:[NSData dataWithBytes:valueFeature length:1]];
     [tlvs addObject:tlv];
    
    NSData *command = [self assembleCommand:0x01 withTLVs:tlvs];
    [self sendData:command];
}

- (void)prepare {
    [self notifyStatus:STATE_PREPARING];
    [self readOTAHeader];
    [self checkRemoteStatus];
    [self scheduleTimeoutTimer];
}

- (void)upgrade {
/*    [self notifyStatus:STATE_PREPARING];
    
    [self readOTAHeader];
    [self checkRemoteStatus];
    [self scheduleTimeoutTimer];
 */
    
    [self requestRemoteParameters];
    [self scheduleTimeoutTimer];
    mWriteBytes = 0;
}

- (void)confirmUpdateAndReboot {
    NSLog(@"confirmUpdateAndReboot");
    NSData *buffer = [self assembleCommand:0x06 withTLVs:nil];
    [self sendData:buffer];
}

/* TLV结构组装 */
- (NSData *)assembleType:(NSInteger) type length:(NSInteger) length value:(NSData *) value {
    NSInteger len = 3;
    Byte *buffer = (Byte *)malloc(len);
    
    NSInteger index = 0;
    
    // Type
    buffer[index++] = (Byte) (type & 0xFF);
    
    // Length
    buffer[index++] = (Byte) (length & 0xFF);
    buffer[index++] = (Byte) ((length >> 8) & 0xFF);
    
    // Value
    NSMutableData *data = [NSMutableData dataWithBytes:buffer length:len];
    [data appendData:value];
    
    free(buffer);
    
    return data;
}

/* 命令组装 */
- (NSData *)assembleCommand:(NSInteger) cmdId withTLVs:(NSArray *) subTLVs {
    NSInteger subTLVsLen = 0;
    if (subTLVs && subTLVs.count > 0) {
        for (NSData *tlv in subTLVs)
            subTLVsLen += tlv.length;
    }
    
    // Header
    Byte *buffer = (Byte *)malloc(2);
    // Server ID
    buffer[0] = (Byte) 0x09;
    // Command ID
    buffer[1] = (Byte) (cmdId & 0xFF);
    NSData *header = [NSData dataWithBytes:buffer length:2];
    free(buffer);
    
    // Super TLV
    NSData *superTLV = [self assembleType:0x80 length:subTLVsLen value:nil];
    
    NSMutableData *cmdData = [NSMutableData dataWithData:header];
    [cmdData appendData:superTLV];
    for (NSData *tlv in subTLVs) {
        [cmdData appendData:tlv];
    }
    
    return cmdData;
}

- (void)notifyStatus:(OTAStatus) state {
    if (self.curState == state)
        return;
    
    self.curState = state;
    if(_delegate && [_delegate respondsToSelector:@selector(onStatus:)]) {
        [_delegate onStatus:self.curState];
    }
}

- (NSArray *)readOTADataFrom:(NSInteger) offset withLength:(NSInteger) length byBitmap:(NSData *) bitmap groupNum:(int) groupNum {
    NSArray *pkgIdx = [mk_fitpoloAdopter getZeroBitIndexMap:bitmap groupNum:groupNum];
    NSInteger pkgNum = pkgIdx.count;
    
    NSMutableArray *packages = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < pkgNum; i++) {
        NSInteger index = [pkgIdx[i] integerValue];
        NSInteger odd = length - index * otaUnit;
        if (odd <= 0)
            break;
        
        NSInteger o = offset + index * otaUnit;
        NSInteger len = odd > otaUnit ? otaUnit : odd;
        
        NSData *pkg = [otaFileData subdataWithRange:NSMakeRange(o, len)];
        NSLog(@"i: %ld o: %ld pkgIdx: %ld pkgNum: %ld count: %ld", i, o, index, pkgNum, pkg.length);
        if (pkg.length <= 0)
            break;
        
        [packages addObject:pkg];
    }

    return packages;
}

- (void)sendData:(NSData *) data {
    if(_delegate && [_delegate respondsToSelector:@selector(sendData:)]) {
        [_delegate sendData:data];
    }
}

- (void)sendData:(NSData *) data index:(int) i{
    if(_delegate && [_delegate respondsToSelector:@selector(sendData:index:)]) {
        [_delegate sendData:data index:i];
    }
}

- (void)requestRemoteParameters {
    NSData *data = [self assembleCommand:0x02 withTLVs:nil];
    [self sendData:data];
}

- (void)notifyRemoteAppReady:(NSInteger) state {
    // ota status
    Byte bytes[1] = {(Byte)(state & 0xFF)};
    NSData *value = [NSData dataWithBytes:bytes length:1];
    NSData *tlv = [self assembleType:0x01 length:0x01 value:value];
    
    NSArray *tlvs = [NSArray arrayWithObject:tlv];
    
    NSData *data = [self assembleCommand:0x09 withTLVs:tlvs];
    [self sendData:data];
}

/* 去除开始位置无效数据 */
- (NSData *)abandonInvalidHeaderData:(NSData *) data {
    Byte *bytes = (Byte *)[data bytes];
    NSInteger length = data.length;
    
    NSInteger index = 0;
    for (index = 0; index < length; index++) {
        if (bytes[index] == 0x09)
            break;
    }
    
    return [data subdataWithRange:NSMakeRange(index, length - index)];
}

- (BOOL)receiveData:(NSData *) data {
    if (!receiveBuffer) {
        receiveBuffer = [[NSMutableData alloc] init];
    }
    
    [receiveBuffer appendData:data];
    
    data = [self abandonInvalidHeaderData:receiveBuffer];
    receiveBuffer = [NSMutableData dataWithData:data];
    
    /* 数据长度不足，等待下一次数据包 */
    if (data.length <= 5) {
        return NO;
    }
    
    Byte *bytes = (Byte *)[data bytes];
    NSInteger length = data.length;
    NSInteger index = 0;
    
    Byte serviceId = bytes[index++];
    Byte commandId = bytes[index++];
    
    Byte superTLV[3] = {0};
    superTLV[0] = bytes[index++];
    superTLV[1] = bytes[index++];
    superTLV[2] = bytes[index++];
    NSInteger subTLVsLen = superTLV[1] + (superTLV[2] << 8);
    
    /* 数据长度不足，等待下一次数据包 */
    if (length - index < subTLVsLen) {
        return NO;
    }
    
    NSData *tmp = [data subdataWithRange:NSMakeRange(index + subTLVsLen, length - index - subTLVsLen)];
    receiveBuffer = [NSMutableData dataWithData:tmp];
    
    NSData *tlvs = [data subdataWithRange:NSMakeRange(index, subTLVsLen)];
    bytes = (Byte *)[tlvs bytes];
    length = tlvs.length;
    index = 0;
    NSLog(@"receive commond:%d",commandId);
    switch (commandId) {
        case 0x01:{
            if (bytes[index] != 0x7F) {
                return NO;
            }
            
            index += 3;
        //    index++;
        //    int length = bytes[index];
        //    index++;
        //    length += (((int)bytes[index]) << 8);
        //    index++;
            NSLog(@"length: %ld", length);
            NSInteger errCode = [mk_fitpoloAdopter bytes2UInt32:bytes index:index];
            index += 4;
            
            NSLog(@"error code: %ld", errCode);
            [self removeTimeoutTimer];
            
            NSData *data;
            RemoteStatus *status = [[RemoteStatus alloc] init];
            
            for ( ; index < length; ) {
                int type = bytes[index++];
                int len = bytes[index++];
                len += (((int)bytes[index]) << 8);
                index++;
                NSLog(@"index: %ld, type: %d, len: %d", index, type, len);
                switch (type) {
                    case 0x04: // battery threshold
                        status.batteryThreshold = bytes[index++];
                        break;
                    case 0x05: // version name
                        data = [NSData dataWithBytes:&bytes[index] length:len];
                        index += len;
                        status.versionName = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        break;
                    case 0x06: // board name
                        data = [NSData dataWithBytes:&bytes[index] length:len];
                        index += len;
                        status.boardName = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        break;
                    case 0x07: // hardware rev
                        data = [NSData dataWithBytes:&bytes[index] length:len];
                        index += len;
                        status.hardwareRev = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        break;
                    case 0x08: // version code
                        status.versionCode = [mk_fitpoloAdopter bytes2UInt32:bytes index:index];
                        index += 4;
                        break;
                    case 0x09: // feature support
                        status.featureSupport = bytes[index++];
                        remoteCrcSupport = status.featureSupport & 0x01;
                        break;
                    default:
                        index += len;
                        break;
                }
            }
            
            if (errCode == 100000) {
     //           [self requestRemoteParameters];
     //           [self scheduleTimeoutTimer];
                if(_delegate && [_delegate respondsToSelector:@selector(receiveRemoteStatus:)]) {
                    [_delegate receiveRemoteStatus:status];
                }
                
                [self notifyStatus:STATE_PREPARED];
            } else {
                self.curState = STATE_UNKNOWN;
                if(_delegate && [_delegate respondsToSelector:@selector(onError:)]) {
                    [_delegate onError:errCode];
                }
            }
            break;
        }
        case 0x02:{
            // app wait timeout
            index += 3;
            waitTimeout = [mk_fitpoloAdopter bytes2Short:bytes index:index];
            index += 2;
            
            // device restart timeout
            index += 3;
            restartTimeout = [mk_fitpoloAdopter bytes2Short:bytes index:index];
            index += 2;
            
            // ota unit size
            index += 3;
            otaUnit = [mk_fitpoloAdopter bytes2Short:bytes index:index];
            index += 2;
            
            // interval
            index += 3;
            interval = [mk_fitpoloAdopter bytes2Short:bytes index:index];
            index += 2;
            
            // ack enable
            index += 3;
            ackEnable = bytes[index] & 0xFF;
            index++;
            
            [self removeTimeoutTimer];
            [self notifyRemoteAppReady:1];
            
            [self notifyStatus:STATE_PREPARED];
            break;
        }
        case 0x03:{
            [self notifyStatus:STATE_TRANSFERRING];
            if(otaUnit == 0){
                ///从上次传输的位置开始
            }
            if (ackEnable == 1) {
                NSArray *array = [NSArray arrayWithObject:tlvs];
                NSData *buf = [self assembleCommand:0x03 withTLVs:array];
                NSLog(@"ackEnable:%lu", (unsigned long)buf.length);
                [self sendData:buf];
            }
            // file offset
            int index = 3;
            int offset = [mk_fitpoloAdopter bytes2UInt32:bytes index:index];
            index += 4;
            
            // file length
            index += 3;
            int length = [mk_fitpoloAdopter bytes2UInt32:bytes index:index];
            index += 4;
            
            // file apply bitmap
            if (tlvs.length > 17) {
                index ++;
                int len = [mk_fitpoloAdopter bytes2Short:bytes index:index];
                index += 2;
                if (tlvs.length >= 17 + len) {
                    Byte *bitmap = (Byte *)malloc(len);
                    for (int i = 0; i < len; i++) {
                        bitmap[i] = bytes[index++];
                        NSLog(@"bitmap[%d]: %x", i, bitmap[i]);
                    }
                    
                    NSData *bitmapData = [NSData dataWithBytes:bitmap length:len];
                    free(bitmap);
                    
                    // 计算组数 1026560 1018848  
                    int groupNum = length / otaUnit + 1;
                    NSArray *frames = [self readOTADataFrom:offset withLength:length byBitmap:bitmapData groupNum:groupNum];
                    NSLog(@"otaUnit:%ld", (long)offset);
                    for (int i = 0; i < frames.count; i++) {
                        Byte b[1] = {(Byte)(i % 256)};
                        NSMutableData *pkg = [NSMutableData dataWithBytes:b length:1];
                        NSInteger command = 0x04;
                        if (remoteCrcSupport) {
                            command = 0x0B;
                            int32_t checksum = [mk_fitpoloAdopter crc32:frames[i]];
                            [pkg appendData: [NSData dataWithBytes: &checksum length: 4]];
                        }
                        [pkg appendData:frames[i]];
                        NSArray *array = [NSArray arrayWithObject:pkg];
                        NSData *data = [self assembleCommand:command withTLVs:array];
                        NSLog(@"remoteCrcSupport:%@", (unsigned long)data);
    
                        [self sendData:data index:i];
                        NSLog(@"send_nick_data_number:%d", i);
                        NSData *realData = frames[i];
                        mWriteBytes = offset+realData.length;
                        [self.delegate receiveSpeed:mWriteBytes];
                        NSLog(@"mWriteBytes:%ld", mWriteBytes);
                  
                    }
                }else{
                    NSLog(@"tlvs.length 长度问题");
                }
            }else{
                NSLog(@"tlvs.length 长度问题2");
            }
            break;
        }
        case 0x05:{
            // package valid size
            index += 3;
            int pkgValidSize = [mk_fitpoloAdopter bytes2UInt32:bytes index:index];
            index += 4;
            
            // received file size
            index += 3;
            int receivedSize = [mk_fitpoloAdopter bytes2UInt32:bytes index:index];
            index += 4;
            
            NSLog(@"receive 0x0905 pkgValidSize: %d, receivedSize: %d", pkgValidSize, receivedSize);
            break;
        }
        case 0x06:{
            index += 3;
            int valid = bytes[index] & 0xFF;
            index++;
        
            NSLog(@"receive 0x0906 valid: %d", valid);
            
            if (_delegate && [_delegate respondsToSelector:@selector(onStatus:)]) {
                if (valid == 1) {
                    [_delegate onStatus:STATE_TRANSFERRED];
                } else {
                    [_delegate onStatus:STATE_UNKNOWN];
                }
            }
            
            break;
        }
        case 0x07:{
            if (bytes[index++] == 0x7F) {
                index += 2;
                int errCode = [mk_fitpoloAdopter bytes2UInt32:bytes index:index];
                index += 4;
                if (errCode != 100000
                    && _delegate
                    && [_delegate respondsToSelector:@selector(onError:)]) {
                    NSLog(@"0x0907 Error: %d", errCode);
                    
                    [_delegate onError:errCode];
                }
            }
            
            break;
        }
        case 0x7D:{
            int type = bytes[index] & 0xFF;
            index++;
            int len = [mk_fitpoloAdopter bytes2Short:bytes index:index];
            index += 2;
            int psn = bytes[index] & 0xFF;
            index++;
            NSLog(@"0x097D, psn: %d, len: %d", psn, len);
            
            type = bytes[index] & 0xFF;
            index++;
            len = [mk_fitpoloAdopter bytes2Short:bytes index:index];
            index += 2;
            
            NSData *buffer = [tlvs subdataWithRange:NSMakeRange(index, len)];
            NSLog(@"Receive 0x097D, data size: %d, %@", len, buffer);
            
            if (_delegate && [_delegate respondsToSelector:@selector(receiveAudioPSN:data:)]) {
                [_delegate receiveAudioPSN:psn data:buffer];
            }
            
            break;
        }
        default:
            break;
    }
    
    // 如果还有剩余数据，则继续处理
    if (receiveBuffer.length > 0) {
        [self receiveData:nil];
    }
    
    return YES;
}

@end
