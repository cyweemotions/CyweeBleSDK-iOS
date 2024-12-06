//
//  mk_fitpoloAdopter.m
//  mk_fitpoloCentralManager
//
//  Created by aa on 2018/12/10.
//  Copyright © 2018 mk_fitpolo. All rights reserved.
//

#import "mk_fitpoloAdopter.h"
#import "mk_fitpoloDefines.h"
#import <Foundation/Foundation.h>
#define POLY 0x1021
static NSString * const mk_customErrorDomain = @"com.moko.fitpoloBluetoothSDK";

static NSString *const uuidPatternString = @"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$";

@implementation mk_fitpoloAdopter

#pragma mark - blocks
+ (NSError *)getErrorWithCode:(mk_customErrorCode)code message:(NSString *)message{
    NSError *error = [[NSError alloc] initWithDomain:mk_customErrorDomain
                                                code:code
                                            userInfo:@{@"errorInfo":message}];
    return error;
}

+ (void)operationCentralBlePowerOffBlock:(void (^)(NSError *error))block{
    mk_fitpolo_main_safe(^{
        if (block) {
            NSError *error = [self getErrorWithCode:mk_bluetoothDisable message:@"mobile phone bluetooth is currently unavailable"];
            block(error);
        }
    });
}

+ (void)operationConnectFailedBlock:(void (^)(NSError *error))block{
    mk_fitpolo_main_safe(^{
        if (block) {
            NSError *error = [self getErrorWithCode:mk_connectedFailed message:@"connect failed"];
            block(error);
        }
    });
}

+ (void)operationDisconnectedErrorBlock:(void (^)(NSError *error))block{
    mk_fitpolo_main_safe(^{
        if (block) {
            NSError *error = [self getErrorWithCode:mk_peripheralDisconnected message:@"the current connection device is in disconnect"];
            block(error);
        }
    });
}

+ (void)operationCharacteristicErrorBlock:(void (^)(NSError *error))block{
    mk_fitpolo_main_safe(^{
        if (block) {
            NSError *error = [self getErrorWithCode:mk_characteristicError message:@"characteristic error"];
            block(error);
        }
    });
}

+ (void)operationRequestDataErrorBlock:(void (^)(NSError *error))block{
    mk_fitpolo_main_safe(^{
        if (block) {
            NSError *error = [self getErrorWithCode:mk_requestPeripheralDataError message:@"request bracelet data error"];
            block(error);
        }
    });
}

+ (void)operationParamsErrorBlock:(void (^)(NSError *error))block{
    mk_fitpolo_main_safe(^{
        if (block) {
            NSError *error = [self getErrorWithCode:mk_paramsError message:@"input parameter error"];
            block(error);
        }
    });
}

+ (void)operationSetParamsErrorBlock:(void (^)(NSError *error))block{
    mk_fitpolo_main_safe(^{
        if (block) {
            NSError *error = [self getErrorWithCode:mk_setParamsError message:@"set parameter error"];
            block(error);
        }
    });
}

+ (void)operationDeviceTypeErrorBlock:(void (^)(NSError *error))block{
    mk_fitpolo_main_safe(^{
        if (block) {
            NSError *error = [self getErrorWithCode:mk_deviceTypeUnknowError message:@"device type unknow"];
            block(error);
        }
    });
}

+ (void)operationUnsupportCommandErrorBlock:(void (^)(NSError *error))block{
    mk_fitpolo_main_safe(^{
        if (block) {
            NSError *error = [self getErrorWithCode:mk_unsupportCommandError message:@"The current device does not support this command"];
            block(error);
        }
    });
}

+ (void)operationGetPackageDataErrorBlock:(void (^)(NSError *error))block{
    mk_fitpolo_main_safe(^{
        if (block) {
            NSError *error = [self getErrorWithCode:mk_getPackageError message:@"get package error"];
            block(error);
        }
    });
}

+ (void)operationUpdateErrorBlock:(void (^)(NSError *error))block{
    mk_fitpolo_main_safe(^{
        if (block) {
            NSError *error = [self getErrorWithCode:mk_updateError message:@"update failed"];
            block(error);
        }
    });
}

+ (void)operationConnectingErrorBlock:(void (^)(NSError *error))block {
    mk_fitpolo_main_safe(^{
        if (block) {
            NSError *error = [self getErrorWithCode:mk_deviceIsConnectingError message:@"The devices are connectting"];
            block(error);
        }
    });
}

+ (void)operationSetParamsResult:(id)returnData
                        sucBlock:(void (^)(id returnData))sucBlock
                     failedBlock:(void (^)(NSError *error))failedBlock{
    //    if (!mk_validDict(returnData)) {
    //        [self operationSetParamsErrorBlock:failedBlock];
    //        return;
    //    }
    //    BOOL resultStatus = [returnData[@"result"][@"result"] boolValue];
    //    if (!resultStatus) {
    //        [self operationSetParamsErrorBlock:failedBlock];
    //        return ;
    //    }
    NSDictionary *resultDic = @{@"msg":@"success",
                                @"code":@"1",
                                @"result":@{},
    };
    mk_fitpolo_main_safe(^{
        if (sucBlock) {
            sucBlock(resultDic);
        }
    });
}

#pragma mark - parser
+ (NSInteger)getDecimalWithHex:(NSString *)content range:(NSRange)range{
    if (!mk_validStr(content)) {
        return 0;
    }
    if (range.location > content.length - 1 || range.length > content.length || (range.location + range.length > content.length)) {
        return 0;
    }
    return strtoul([[content substringWithRange:range] UTF8String],0,16);
}
+ (NSString *)getDecimalStringWithHex:(NSString *)content range:(NSRange)range{
    if (!mk_validStr(content)) {
        return @"";
    }
    if (range.location > content.length - 1 || range.length > content.length || (range.location + range.length > content.length)) {
        return @"";
    }
    NSInteger decimalValue = strtoul([[content substringWithRange:range] UTF8String],0,16);
    return [NSString stringWithFormat:@"%ld",(long)decimalValue];
}

/**
 把originalArray数组按照range进行截取，生成一个新的数组并返回该数组
 
 @param originalArray 原数组
 @param range 截取范围
 @return 截取后生成的数组
 */
+ (NSArray *)interceptionOfArray:(NSArray *)originalArray
                        subRange:(NSRange)range{
    if (!mk_validArray(originalArray)) {
        return nil;
    }
    if (range.location > originalArray.count - 1 || range.length > originalArray.count || (range.location + range.length > originalArray.count)) {
        return nil;
    }
    NSMutableArray *desArray = [NSMutableArray array];
    for (NSInteger i = 0; i < range.length; i ++) {
        [desArray addObject:originalArray[range.location + i]];
    }
    return desArray;
}

/**
 对NSData进行CRC16的校验
 
 @param data 目标data
 @return CRC16校验码
 */
+ (NSData *)getCrc16VerifyCode:(NSData *)data{
    if (!mk_validData(data)) {
        return nil;
    }
    NSInteger crcWord = 0xffff;
    Byte *dataArray = (Byte *)[data bytes];
    for (NSInteger i = 0; i < data.length; i ++) {
        Byte byte = dataArray[i];
        crcWord ^= (NSInteger)byte & 0x00ff;
        for (NSInteger j = 0; j < 8; j ++) {
            if ((crcWord & 0x0001) == 1) {
                crcWord = crcWord >> 1;
                crcWord = crcWord ^ 0xA001;
            }else{
                crcWord = (crcWord >> 1);
            }
        }
    }
    
    Byte crcL = (Byte)0xff & (crcWord >> 8);
    Byte crcH = (Byte)0xff & (crcWord);
    Byte arrayCrc[] = {crcH, crcL};
    NSData *dataCrc = [NSData dataWithBytes:arrayCrc length:sizeof(arrayCrc)];
    return dataCrc;
}

+ (NSString *)hexStringFromData:(NSData *)sourceData{
    if (!mk_validData(sourceData)) {
        return nil;
    }
    Byte *bytes = (Byte *)[sourceData bytes];
    //下面是Byte 转换为16进制。
    NSString *hexStr=@"";
    for(int i=0;i<[sourceData length];i++){
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数
        if([newHexStr length]==1)
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        else
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
    }
    return hexStr;
}

+ (NSString *)getTimeStringWithDate:(NSDate *)date{
    if (!date) {
        return nil;
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd-HH-mm"];
    NSString *timeStamp = [formatter stringFromDate:date];
    if (!mk_validStr(timeStamp)) {
        return nil;
    }
    NSArray *timeList = [timeStamp componentsSeparatedByString:@"-"];
    if (!mk_validArray(timeList) || timeList.count != 5) {
        return nil;
    }
    if ([timeList[0] integerValue] < 2000 || [timeList[0] integerValue] > 2099) {
        return nil;
    }
    unsigned long yearValue = [timeList[0] integerValue] - 2000;
    NSString *hexTimeString = [NSString stringWithFormat:@"%1lx",yearValue];
    if (hexTimeString.length == 1) {
        hexTimeString = [@"0" stringByAppendingString:hexTimeString];
    }
    for (NSInteger i = 1; i < timeList.count; i ++) {
        unsigned long tempValue = [timeList[i] integerValue];
        NSString *hexTempStr = [NSString stringWithFormat:@"%1lx",tempValue];
        if (hexTempStr.length == 1) {
            hexTempStr = [@"0" stringByAppendingString:hexTempStr];
        }
        hexTimeString = [hexTimeString stringByAppendingString:hexTempStr];
    }
    return hexTimeString;
}

+ (BOOL)isMacAddress:(NSString *)macAddress{
    if (!mk_validStr(macAddress)) {
        return NO;
    }
    NSString *regex = @"([A-Fa-f0-9]{2}-){5}[A-Fa-f0-9]{2}";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
    return [pred evaluateWithObject:macAddress];
}
+ (BOOL)isMacAddressLowFour:(NSString *)lowFour{
    if (!mk_validStr(lowFour)) {
        return NO;
    }
    NSString *regex = @"([A-Fa-f0-9]{2}-){1}[A-Fa-f0-9]{2}";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
    return [pred evaluateWithObject:lowFour];
}
+ (BOOL)isUUIDString:(NSString *)uuid{
    if (!mk_validStr(uuid)) {
        return NO;
    }
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:uuidPatternString
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    NSInteger numberOfMatches = [regex numberOfMatchesInString:uuid
                                                       options:kNilOptions
                                                         range:NSMakeRange(0, uuid.length)];
    return (numberOfMatches > 0);
}

+ (BOOL)checkIdenty:(NSString *)identy{
    if ([self isMacAddressLowFour:identy]) {
        return YES;
    }
    if ([self isUUIDString:identy]) {
        return YES;
    }
    if ([self isMacAddress:identy]) {
        return YES;
    }
    return NO;
}

+ (NSData *)stringToData:(NSString *)dataString{
    if (!mk_validStr(dataString)) {
        return nil;
    }
    if (!(dataString.length % 2 == 0)) {
        //必须是偶数个字符才是合法的
        return nil;
    }
    Byte bytes[255] = {0};
    NSInteger count = 0;
    for (int i =0; i < dataString.length; i+=2) {
        NSString *strByte = [dataString substringWithRange:NSMakeRange(i,2)];
        unsigned long red = strtoul([strByte UTF8String],0,16);
        Byte b =  (Byte) ((0xff & red) );//( Byte) 0xff&iByte;
        bytes[i/2+0] = b;
        count ++;
    }
    NSData * data = [NSData dataWithBytes:bytes length:count];
    return data;
}

+ (NSData *)dataWithHexString:(NSString *)hexString {
    NSMutableData *data = [NSMutableData data];
    
    for (int i = 0; i < hexString.length; i += 2) {
        NSString *sub = [hexString substringWithRange:NSMakeRange(i, 2)];
        NSScanner *scanner = [NSScanner scannerWithString:sub];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
    
    return data;
}



+ (UInt32)bytes2UInt32:(Byte*)bytes index:(NSInteger)index {
    return (((bytes[index + 3] & 0xFF) << 24) + ((bytes[index + 2] & 0xFF) << 16)) + ((bytes[index + 1] & 0xFF) << 8) + (bytes[index] & 0xFF);
}

+ (UInt16)bytes2Short:(Byte*)bytes index:(NSInteger)index {
    return ((bytes[index + 1] & 0xFF) << 8) + (bytes[index] & 0xFF);
}

/* 计算0比特位的个数 */
+ (NSInteger)countZeroBit:(NSData *) bitmap {
    NSInteger count = 0;
    
    Byte *bytes = (Byte *)[bitmap bytes];
    NSInteger length = bitmap.length;
    
    for (int i = 0; i < length; i++ ) {
        Byte x = bytes[i];
        while ((x + 1) != 0) {
            x |= (x + 1);
            count++;
        }
    }
    
    return count;
}

/* 从bitmap获取相应0bit位的索引 */
+ (NSArray *)getZeroBitIndexMap:(NSData *) bitmap groupNum:(int) groupNum{
    NSMutableArray *indexMap = [[NSMutableArray alloc] init];
    
    NSInteger count = 0;
    NSInteger index = 0;
    Byte *bytes = (Byte *)[bitmap bytes];
    for (NSInteger i = 0; i < bitmap.length; i++) {
        Byte b = bytes[i];
        for (NSInteger j = 0; j < groupNum; j++) {
            int offset = (index % groupNum);
            
            if ((b & (0x1 << offset)) == 0x0) {
                [indexMap addObject:[NSNumber numberWithInteger:index]];
                count++;
            }
            
            index++;
        }
    }
    
    return indexMap;
}

+ (int32_t)crc32:(NSData *)data {
    uint32_t *table = malloc(sizeof(uint32_t) * 256);
    uint32_t crc = 0xffffffff;
    uint8_t *bytes = (uint8_t *)[data bytes];
    
    for (uint32_t i=0; i<256; i++) {
        table[i] = i;
        for (int j=0; j<8; j++) {
            if (table[i] & 1) {
                table[i] = (table[i] >>= 1) ^ 0xedb88320;
            } else {
                table[i] >>= 1;
            }
        }
    }
    
    for (int i=0; i<data.length; i++) {
        crc = (crc >> 8) ^ table[crc & 0xff ^ bytes[i]];
    }
    crc ^= 0xffffffff;
    
    free(table);
    return crc;
}

+(void)setDefault:(NSString *)content key:(NSString *)key{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:content forKey:key];
    [userDefault synchronize];
}

+(NSString *)getValue:(NSString *)key{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSString *content = [userDefault objectForKey:key];
    return content;
}

/// 普通字符串转换十六进制。
+ (NSString *)hexStringFromString:(NSString *)string
{
    NSData *myD = [string dataUsingEncoding:NSUTF8StringEncoding];
    Byte *bytes = (Byte *)[myD bytes];
    
    //下面是Byte 转换为16进制。
    NSMutableString* resultStr = [[NSMutableString alloc]init];
    
    for(int i=0;i<[myD length];i++)
        
    {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数
        
        if([newHexStr length]==1)
        {
            newHexStr = [NSString stringWithFormat:@"0%@",newHexStr];
        }
        
        [resultStr appendString:newHexStr];
    }
    
    return resultStr;
}

/// 十六进制转换为普通字符串的。
+ (NSString *)stringFromHexString:(NSString *)hexString
{
    if(hexString.length % 2 != 0)
    {
        return nil;
    }
    char *myBuffer = (char *)malloc((int)[hexString length] / 2 + 1);
    bzero(myBuffer, [hexString length] / 2 + 1);
    for (int i = 0; i < [hexString length] - 1; i += 2)
    {
        unsigned int anInt;
        NSString * hexCharStr = [hexString substringWithRange:NSMakeRange(i, 2)];
        NSScanner * scanner = [[NSScanner alloc] initWithString:hexCharStr];
        [scanner scanHexInt:&anInt];
        myBuffer[i / 2] = (char)anInt;
    }
    NSString *unicodeString = [NSString stringWithCString:myBuffer encoding:NSUTF8StringEncoding];
    return unicodeString;
}
/// NSData转换为十六进制。
+ (NSString *)nsArrayFromHexString:(NSMutableArray *)data
{
    // 创建一个 NSMutableString 用于保存十六进制字符串
    NSMutableString *hexString = [[NSMutableString alloc] init];
    // 遍历 dataList，将每个 byte 转换为十六进制
    for (NSNumber *byte in data) {
        [hexString appendFormat:@"%02X", [byte unsignedCharValue]]; // 使用 %02X 格式化为两位十六进制
    }
    return hexString;
}

+ (NSArray<NSNumber *> *)convert:(NSInteger)value byteType:(mk_byteType)type {
    // 实现相应的转换逻辑
    NSMutableArray<NSNumber *> *byteArray = [NSMutableArray array];
    // 假设 ByteType.WORD 代表两个字节，具体实现根据需要调整
    for (NSInteger i = type-1; i >= 0; i--) {
        [byteArray addObject:@((value >> (8 * i)) & 0xFF)];
    }
    return byteArray;
}
//将NSString转化为NSData
+(NSData *)toNSData:(NSString *)str{
    NSError *error = nil;
    NSData *aData = [str dataUsingEncoding:NSUTF8StringEncoding];
    if (aData.length && error ==nil) {
        return aData;
    }else{
        return nil;
    }
}
//将NSData转化为NSString
+(NSString *)transformData:(NSData *)data{
    NSError *error = nil;
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (string.length && error == nil) {
        return string;
    }else{
        return nil;
    }
}
// 将NSData转化为字典或者数组
+ (id)turnArrDic:(NSData *)data{
    
    NSError *error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
    if (object != nil && error == nil){
        return object;
    }else{
        // 解析错误
        return nil;
    }
    
}
//十六进制字符转数字数组
+ (NSArray<NSNumber *> *)arrayFromHexString:(NSString *)hexString {
    // 去掉空格
    hexString = [hexString stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    // 去掉 "0x" 前缀
    if ([hexString hasPrefix:@"0x"]) {
        hexString = [hexString substringFromIndex:2];
    }
    
    // 如果长度是奇数，则前面补零
    if (hexString.length % 2 != 0) {
        hexString = [@"0" stringByAppendingString:hexString];
    }
    
    NSMutableArray<NSNumber *> *numberArray = [NSMutableArray array];
    
    for (NSUInteger i = 0; i < hexString.length; i += 2) {
        NSString *hexByte = [hexString substringWithRange:NSMakeRange(i, 2)];
        unsigned int byteValue;
        [[NSScanner scannerWithString:hexByte] scanHexInt:&byteValue];
        [numberArray addObject:@(byteValue)];
    }
    
    return [numberArray copy]; // 返回不可变数组
}
//十六进制字符转数字数组（取范围）
+ (NSArray<NSNumber *> *)limitArrayFromHexString:(NSString *)hexString
                                           limit:(int)limit{
    // 去掉空格
    hexString = [hexString stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    // 去掉 "0x" 前缀
    if ([hexString hasPrefix:@"0x"]) {
        hexString = [hexString substringFromIndex:2];
    }
    
    NSMutableArray<NSNumber *> *numberArray = [NSMutableArray array];
    
    for (NSUInteger i = 0; i < hexString.length; i += 2) {
        NSString *hexByte = [hexString substringWithRange:NSMakeRange(i, 2)];
        unsigned int byteValue;
        [[NSScanner scannerWithString:hexByte] scanHexInt:&byteValue];
        [numberArray addObject:@(byteValue)];
    }
    NSLog(@"numberArray===%@", numberArray);
    NSLog(@"numberArray count===%d", numberArray.count);
    
    NSMutableArray<NSNumber *> *resultArray = [NSMutableArray array];
    for (NSUInteger j = 0; j < limit; j++){
        if(j < numberArray.count) {
            [resultArray addObject:numberArray[j]];
        } else {
            [resultArray addObject:@(0)];
        }
    }
    
    return [resultArray copy]; // 返回不可变数组
}
//删除字符串结尾的所有0
+ (NSArray<NSNumber *>*)removeArrayZero:(NSArray<NSNumber *>*)data{// 反向遍历数组，找到最后一个非零元素的索引
    NSUInteger count = [data count];
    NSUInteger lastNonZeroIndex = count;
    
    // 从数组尾部开始，找到第一个非零元素的位置
    for (NSInteger i = count - 1; i >= 0; i--) {
        if ([data[i] isEqualToNumber:@0]) {
            lastNonZeroIndex--;
        } else {
            break; // 找到第一个非零元素，停止循环
        }
    }
    
    // 根据找到的索引创建新的数组
    NSArray<NSNumber *> *trimmedArray;
    if (lastNonZeroIndex < count) {
        trimmedArray = [data subarrayWithRange:NSMakeRange(0, lastNonZeroIndex)];
    } else {
        trimmedArray = data; // 如果没有零，保持原数组
    }
    return trimmedArray;
}

+ (NSInteger) turnList:(NSArray<NSNumber *> *)source {
    NSLog(@"PAI同步数据turnList====source=====%@", source);
    // 转换为十六进制字符串
    NSString *hexString = [self nsArrayFromHexString:source];
    NSLog(@"PAI同步数据turnList====hexString=====%@", hexString);
    // 将十六进制字符串转换为整数
    unsigned long long value = strtoull([hexString UTF8String], NULL, 16);
    
    return (int)value;
}

+(NSData *)dataFromArray:(NSArray<NSNumber *> *)array{
    // 转换为字节数组
    NSMutableData *dataBytes = [NSMutableData dataWithCapacity:array.count];
    for (NSNumber *num in array) {
        Byte byteValue = [num unsignedCharValue];
        [dataBytes appendBytes:&byteValue length:sizeof(Byte)];
    }
    return dataBytes;
}


// 计算CRC16 - CCITT（False）校验值
+ (NSUInteger)crc16CcittFalse:(NSData *)data {
    NSUInteger crc = 0xFFFF;
    const uint8_t *bytes = (const uint8_t *)data.bytes;
    for (NSUInteger i = 0; i < data.length; i++) {
        crc ^= (bytes[i] << 8);
        for (int j = 0; j < 8; j++) {
            if (crc & 0x8000) {
                crc = (crc << 1) ^ POLY;
            } else {
                crc <<= 1;
            }
        }
    }
    return crc & 0xFFFF;
}

@end

