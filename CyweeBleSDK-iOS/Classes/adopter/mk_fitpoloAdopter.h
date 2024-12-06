//
//  mk_fitpoloAdopter.h
//  mk_fitpoloCentralManager
//
//  Created by aa on 2018/12/10.
//  Copyright © 2018 mk_fitpolo. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 Custom error code
 */
typedef NS_ENUM(NSInteger, mk_customErrorCode){
    mk_bluetoothDisable = -10000,                                //Current phone Bluetooth is not available.
    mk_connectedFailed = -10001,                                 //Connection peripheral failed.
    mk_peripheralDisconnected = -10002,                          //The currently externally connected device is disconnected.
    mk_characteristicError = -10003,                             //Feature is empty.
    mk_requestPeripheralDataError = -10004,                      //Requesting bracelet data error.
    mk_paramsError = -10005,                                     //The input parameters are incorrect.
    mk_setParamsError = -10006,                                  //Setting parameter error.
    mk_getPackageError = -10007,                                 //When upgrading the firmware, the firmware data passed in is wrong.
    mk_updateError = -10008,                                     //upgrade fail.
    mk_deviceTypeUnknowError = -10009,                           //Device type error.
    mk_unsupportCommandError = -10010,                           //Device do not support the command.
    mk_deviceIsConnectingError = -10011,                         //The device is connecting and does not allow duplicate connections.
};


/**
 commandType
 */
typedef NS_ENUM(NSInteger, mk_commandType) {
    mk_setting = 0x00,
    mk_getSetting = 0x01,
    mk_function = 0x02,
    mk_dataNotify = 0x03,
    mk_deviceAuth = 0x04,
    mk_dailPush = 0x05,
};

/**
 convert
 */
typedef NS_ENUM(NSInteger, mk_byteType) {
    mk_byte = 1,//byte 1
    mk_word = 2,//word 2
    mk_dword = 4,//dword 4
};


/**
 xon_frame_type
 */
typedef NS_ENUM(NSInteger, xon_frame_type) {
    xon_frame_type_ack = 0x00,
    xon_frame_type_mtu = 0x01,
    xon_frame_type_once = 0x02,
    xon_frame_type_multi_info = 0x03,
    xon_frame_type_multi_crc = 0x04,
    xon_frame_type_multi_ack = 0x05,
    xon_frame_type_multi = 0x06,
};

typedef NS_ENUM(NSInteger, xon_frame_ack_type) {
    xon_frame_ack_type_void = 0x00,
    xon_frame_ack_type_ok = 0x01,
    xon_frame_ack_type_len_err = 0x02,
    xon_frame_ack_type_head_err = 0x03,
    xon_frame_ack_type_crc_err = 0x04,
    xon_frame_ack_type_multi_index_err = 0x05,
    xon_frame_ack_type_multi_busy = 0x06,
    xon_frame_ack_type_multi_size_err = 0x07,
    xon_frame_ack_type_multi_pack_num_err = 0x08,
};


typedef NS_ENUM(NSInteger, DIAL_FILE_STATE) {
    DIAL_FILE_START = 0x00,
    DIAL_FILE_INFO = 0x01,
    DIAL_FILE_SEND = 0x02,
    DIAL_FILE_STOP = 0x03,
    DIAL_REC_RESULT = 0x04,
    DIAL_FORCE_STOP = 0x05,
};

NS_ASSUME_NONNULL_BEGIN

@interface mk_fitpoloAdopter : NSObject

#pragma mark - blocks
+ (NSError *)getErrorWithCode:(mk_customErrorCode)code message:(NSString *)message;
+ (void)operationCentralBlePowerOffBlock:(void (^)(NSError *error))block;
+ (void)operationConnectFailedBlock:(void (^)(NSError *error))block;
+ (void)operationDisconnectedErrorBlock:(void (^)(NSError *error))block;
+ (void)operationCharacteristicErrorBlock:(void (^)(NSError *error))block;
+ (void)operationRequestDataErrorBlock:(void (^)(NSError *error))block;
+ (void)operationParamsErrorBlock:(void (^)(NSError *error))block;
+ (void)operationSetParamsErrorBlock:(void (^)(NSError *error))block;
+ (void)operationDeviceTypeErrorBlock:(void (^)(NSError *error))block;
+ (void)operationUnsupportCommandErrorBlock:(void (^)(NSError *error))block;
+ (void)operationGetPackageDataErrorBlock:(void (^)(NSError *error))block;
+ (void)operationUpdateErrorBlock:(void (^)(NSError *error))block;
+ (void)operationConnectingErrorBlock:(void (^)(NSError *error))block;
+ (void)operationSetParamsResult:(id)returnData
                        sucBlock:(void (^)(id returnData))sucBlock
                     failedBlock:(void (^)(NSError *error))failedBlock;

#pragma mark - parser
+ (NSInteger)getDecimalWithHex:(NSString *)content range:(NSRange)range;
+ (NSString *)getDecimalStringWithHex:(NSString *)content range:(NSRange)range;
+ (NSArray *)interceptionOfArray:(NSArray *)originalArray subRange:(NSRange)range;
+ (NSData *)getCrc16VerifyCode:(NSData *)data;
+ (NSString *)hexStringFromData:(NSData *)sourceData;
+ (NSString *)getTimeStringWithDate:(NSDate *)date;
+ (NSData *)stringToData:(NSString *)dataString;
+ (BOOL)isMacAddress:(NSString *)macAddress;
+ (BOOL)isMacAddressLowFour:(NSString *)lowFour;
+ (BOOL)isUUIDString:(NSString *)uuid;
+ (BOOL)checkIdenty:(NSString *)identy;
+ (NSData *)dataWithHexString:(NSString *)hexString;


+ (UInt32)bytes2UInt32:(Byte*) bytes index:(NSInteger) index;
+ (UInt16)bytes2Short:(Byte*) bytes index:(NSInteger) index;
+ (NSArray *)getZeroBitIndexMap:(NSData *) bitmap groupNum:(int) group;
+ (int32_t)crc32:(NSData *)data;
+(void)setDefault:(NSString *)content key:(NSString *)key;
+(NSString *)getValue:(NSString *)key;
/// 普通字符串转换十六进制。
+ (NSString *)hexStringFromString:(NSString *)string;
/// 十六进制转换为普通字符串的。
+ (NSString *)stringFromHexString:(NSString *)hexString;
/// NSData转换为十六进制。
+ (NSString *)nsArrayFromHexString:(NSMutableArray *)data;
///将NSString转化为NSData
+ (NSData *)toNSData:(NSString *)data;
///将NSData转化为NSString
+ (NSString *)transformData:(NSData *)data;
/// 将NSData转化为字典或者数组
+ (id)turnArrDic:(NSMutableArray *)data;

//十六进制字符转数字数组
+ (NSArray<NSNumber *> *)arrayFromHexString:(NSString *)data;
//十六进制字符转数字数组（取范围）
+ (NSArray<NSNumber *> *)limitArrayFromHexString:(NSString *)data
                                           limit:(int)limit;
//删除数组结尾的所有0
+ (NSArray<NSNumber *> *)removeArrayZero:(NSArray<NSNumber *> *)data;
+ (NSInteger)turnList:(NSArray<NSNumber *> *)data;
+ (NSArray<NSNumber *> *)convert:(NSInteger)value byteType:(mk_byteType)type;
+ (NSUInteger)crc16CcittFalse:(NSData *)data;
+(NSData *)dataFromArray:(NSArray<NSNumber *> *)array;
@end

NS_ASSUME_NONNULL_END
