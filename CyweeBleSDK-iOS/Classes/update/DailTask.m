//
//  DailTask.m
//  CyweeBleSDK-iOS
//
//  Created by cywee on 2024/11/1.
//

#import "DailTask.h"
#import "mk_fitpoloAdopter.h"
#import "mk_fitpoloCentralManager.h"


@implementation DailTask

- (instancetype)init
{
    self = [super init];
    if (self) {

        
    }
    return self;
}


/// 创建发送数据
/// - Parameters:
///   - sendType: 发送类型
///   - isFirst: 是否为首包
///   - isMulti: 是否为多包
///   - fileCount: 文件总数
///   - datas: 数据
+(NSMutableData *)DailTask:(NSInteger)sendType isFirst:(BOOL)isFirst isMulti:(BOOL)isMulti fileCount:(NSInteger)fileCount datas:(NSData *)datas{
    NSMutableData *sendData = [NSMutableData data];
    NSData *subdata = [self dataByControlType:sendType isFirst:isFirst fileCount:fileCount datas:datas];
    ///头部
    Byte *buffer = (Byte *)malloc(2);
    buffer[0] = (Byte) 0xA5;
    buffer[1] = (Byte) 0xA3;
    NSData *header = [NSData dataWithBytes:buffer length:2];
    [sendData appendData:header];

    NSInteger value;
    if(isMulti){
        value = xon_frame_type_multi;
    }else{
        value = xon_frame_type_once;
    }
    NSArray<NSNumber *> *typeLength =  [mk_fitpoloAdopter convert:value byteType:mk_word];
    typeLength = [[typeLength reverseObjectEnumerator] allObjects];
    NSData *typeLengthData = [mk_fitpoloAdopter dataFromArray:typeLength];
    [sendData appendData:typeLengthData];
    
    NSArray<NSNumber *> *dataLength =  [mk_fitpoloAdopter convert:subdata.length byteType:mk_word];
    dataLength = [[dataLength reverseObjectEnumerator] allObjects];
    NSData *dataLengthData = [mk_fitpoloAdopter dataFromArray:dataLength];
    [sendData appendData:dataLengthData];
    
    [sendData appendData:subdata];
    ///CRC
    NSInteger crcvalue = [mk_fitpoloAdopter crc16CcittFalse:sendData];
    NSArray<NSNumber *> *crcdataArray =  [mk_fitpoloAdopter convert:crcvalue byteType:mk_word];
    NSData *crcData = [mk_fitpoloAdopter dataFromArray:crcdataArray];
    [sendData appendData:crcData];
    
    return  sendData;
}


/// 创建XonF 层数据
/// - Parameters:
///   - sendType: 发送类型
///   - isMulti: 是否为多包
///   - onlyXOF: 仅仅是XOF
///   - datas: 数据
+(NSMutableData *)DailTask:(NSInteger)sendType isMulti:(BOOL)isMulti onlyXOF:(BOOL)onlyXOF datas:(NSData *)datas{
    NSMutableData *sendData = [NSMutableData data];
    
    ///头部
    Byte *buffer = (Byte *)malloc(2);
    buffer[0] = (Byte) 0xA5;
    buffer[1] = (Byte) 0xA3;
    NSData *header = [NSData dataWithBytes:buffer length:2];
    [sendData appendData:header];
    
    ///类型长度
    NSArray<NSNumber *> *typeLength = [mk_fitpoloAdopter convert:sendType byteType:mk_word];
    typeLength = [[typeLength reverseObjectEnumerator] allObjects];
    NSData *typeLengthData = [mk_fitpoloAdopter dataFromArray:typeLength];
    [sendData appendData:typeLengthData];
    
    
    NSArray<NSNumber *> *dataLength =  [mk_fitpoloAdopter convert:datas.length byteType:mk_word];
    dataLength = [[dataLength reverseObjectEnumerator] allObjects];
    NSData *dataLengthData = [mk_fitpoloAdopter dataFromArray:dataLength];
    [sendData appendData:dataLengthData];
    
    [sendData appendData:datas];
    ///CRC
    NSInteger crcvalue = [mk_fitpoloAdopter crc16CcittFalse:sendData];
    NSArray<NSNumber *> *crcdataArray =  [mk_fitpoloAdopter convert:crcvalue byteType:mk_word];
    NSData *crcData = [mk_fitpoloAdopter dataFromArray:crcdataArray];
    [sendData appendData:crcData];
    
    return  sendData;
}

/// 数据组装
/// - Parameters:
///   - sendType: 发送类型
///   - isFirst: 是否为首包
///   - fileCount: 文件大小
///   - datas: 数据内容
+(NSMutableData *)dataByControlType:(NSInteger)sendType isFirst:(BOOL)isFirst fileCount:(NSInteger)fileCount datas:(NSData *)datas{
    NSMutableData *sendData = [NSMutableData data];
    if(isFirst){
        ///首包头部
        Byte *buffer = (Byte *)malloc(4);
        buffer[0] = (Byte) 0x00;
        buffer[1] = (Byte) 0x00;
        buffer[2] = (Byte) 0x00;
        buffer[3] = (Byte) 0x00;
        NSData *header = [NSData dataWithBytes:buffer length:4];
        [sendData appendData:header];
    }
    ///头部
    Byte *buffer = (Byte *)malloc(2);
    buffer[0] = (Byte) 0x02;
    buffer[1] = (Byte) 0x00;
    NSData *header = [NSData dataWithBytes:buffer length:2];
    [sendData appendData:header];
    ///类型长度
    NSArray<NSNumber *> *typeLength = [mk_fitpoloAdopter convert:sendType byteType:mk_word];
    typeLength = [[typeLength reverseObjectEnumerator] allObjects];
    NSData *typeLengthData = [mk_fitpoloAdopter dataFromArray:typeLength];
    [sendData appendData:typeLengthData];
//    0xa5a3 0600 ec00 0000 0000 0200 0200 0000 0000 0dab
    Byte *version = (Byte *)malloc(2);
    version[0] = (Byte) 0x00;
    version[1] = (Byte) 0x00;
    NSData *versionData = [NSData dataWithBytes:version length:2];
    [sendData appendData:versionData];
    
    NSArray<NSNumber *> *dataLength = [NSArray array];
    if(isFirst){
        dataLength = [mk_fitpoloAdopter convert:fileCount byteType:mk_dword];
    }else{
        dataLength = [mk_fitpoloAdopter convert:datas.length byteType:mk_dword];
    }
    dataLength = [[dataLength reverseObjectEnumerator] allObjects];
    NSData *dataLengthData = [mk_fitpoloAdopter dataFromArray:dataLength];
    [sendData appendData:dataLengthData];
    
    [sendData appendData:datas];
    NSLog(@"sendData长度:%lu",(unsigned long)sendData.length);
    return  sendData;
}


/**
 发送文件控制
 */
+(void)dailSendContrl:(NSInteger)type subType:(NSInteger)subType request:(NSData *)req{
    
    NSMutableData *sendData = [NSMutableData data];
    Byte *buffer = (Byte *)malloc(2);
    buffer[0] = (Byte) 0x02;
    buffer[1] = (Byte) 0x00;
    NSData *header = [NSData dataWithBytes:buffer length:2];
    
    Byte *buffers = (Byte *)malloc(2);
    buffers[0] = (Byte) (subType & 0xFF);
    buffers[1] = (Byte) ((subType << 8) & 0xFF);
    NSData *subTypes = [NSData dataWithBytes:buffers length:2];
    
    Byte *version = (Byte *)malloc(2);
    buffer[0] = (Byte) 0x00;
    buffer[1] = (Byte) 0x00;
    NSData *versionData = [NSData dataWithBytes:version length:2];
    
    NSInteger dataLength = req.length;
    Byte lengths[4];
    lengths[0] = (Byte)(dataLength<<24);
    lengths[1] = (Byte)(dataLength<<16);
    lengths[2] = (Byte)(dataLength<<8);
    lengths[3] = (Byte)(dataLength);
    NSData *packLenData = [NSData dataWithBytes:lengths length:4];
    
    [sendData appendData:header];
    [sendData appendData:subTypes];
    [sendData appendData:versionData];
    [sendData appendData:packLenData];
    [sendData appendData:req];
    NSLog(@"发送的数据:%@",sendData);
//    [[mk_fitpoloCentralManager sharedInstance] sendDailData:sendData];
}

/// 解析数据
/// - Parameter data: 数据
+(void)parseValue:(NSData *)data callBack:(DialCallBack)block{
    if(data.length >= 6){
        ///1.判断crc问题
        NSInteger crc = [mk_fitpoloAdopter crc16CcittFalse:data];
        if(crc == 0){
            NSLog(@"CRC校验正确");
            //类型
            NSData *typeData = [data subdataWithRange:NSMakeRange(2, 2)];
            int type = 0;
            [typeData getBytes:&type length:sizeof(type)];
            //长度
            NSData *lengthData = [data subdataWithRange:NSMakeRange(4, 2)];
            int length = 0;
            [lengthData getBytes:&length length:sizeof(length)];
            NSData *source = [data subdataWithRange:NSMakeRange(6, length)];
            NSLog(@"类型是:%d,长度:%d,数据内容:%@",type,length,source);
            switch (type) {
                case xon_frame_type_ack:
                {
                    int res = 0;
                    [source getBytes:&res length:sizeof(res)];
                    block(source,res);
                }
                    break;
                case xon_frame_type_mtu:
                {
                    NSLog(@"类型是xon_frame_type_mtu");
                }
                    break;
                case xon_frame_type_once:
                {
                    
                }
                    break;
                case xon_frame_type_multi_info:
                {
                    
                }
                    break;
                case xon_frame_type_multi_crc:
                {
                    
                }
                    break;
                case xon_frame_type_multi_ack:
                {
                    NSLog(@"类型是xon_frame_type_multi_ack");
                    block(source,1);
                }
                    break;
                case xon_frame_type_multi:
                {
                    
                }
                    break;
                default:
                    break;
            }
            
            
            
        }else{
            NSLog(@"CRC校验失败");
        }
    }else{
        NSLog(@"表盘返回数据格式错误");
    }
    
}

/// 在刚订阅会返回mtu
/// - Parameter data: 数据
+(void)calcuMtu:(NSData *)data{
    if(data.length >= 8){
        //类型
        NSData *typeData = [data subdataWithRange:NSMakeRange(2, 2)];
        int type = 0;
        [typeData getBytes:&type length:sizeof(type)];
        if(type == xon_frame_type_mtu){
            //长度
            NSData *lengthData = [data subdataWithRange:NSMakeRange(4, 2)];
            int length = 0;
            [lengthData getBytes:&length length:sizeof(length)];
            //数据
            NSData *source = [data subdataWithRange:NSMakeRange(6, length)];
            int mtu = 0;
            [source getBytes:&mtu length:sizeof(mtu)];
            [mk_fitpoloCentralManager sharedInstance].mtu = mtu;
            NSLog(@"设备的MTU是:%d",mtu);
        }
    }
}


@end
