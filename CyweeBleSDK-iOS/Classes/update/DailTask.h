//
//  DailTask.h
//  CyweeBleSDK-iOS
//
//  Created by cywee on 2024/11/1.
//

#import <Foundation/Foundation.h>

typedef void(^DialCallBack)(NSData *data,NSInteger state);

@interface DailTask : NSObject

// 创建发送数据
/// - Parameters:
///   - sendType: 发送类型
///   - isFirst: 是否为首包
///   - isMulti: 是否为多包
///   - fileCount: 文件总数
///   - datas: 数据
+(NSMutableData *)DailTask:(NSInteger)sendType isFirst:(BOOL)isFirst isMulti:(BOOL)isMulti fileCount:(NSInteger)fileCount datas:(NSData *)datas;

/// 创建XonF 层数据
/// - Parameters:
///   - sendType: 发送类型
///   - isMulti: 是否为多包
///   - onlyXOF: 仅仅是XOF
///   - datas: 数据
+(NSMutableData *)DailTask:(NSInteger)sendType isMulti:(BOOL)isMulti onlyXOF:(BOOL)onlyXOF datas:(NSData *)datas;

/// 解析数据
/// - Parameter data: 数据
+(void)parseValue:(NSData *)data callBack:(DialCallBack)block;

/// 在刚订阅会返回mtu
/// - Parameter data: 数据
+(void)calcuMtu:(NSData *)data;

@end


