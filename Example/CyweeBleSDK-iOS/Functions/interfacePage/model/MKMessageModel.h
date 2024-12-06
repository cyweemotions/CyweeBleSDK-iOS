//
//  MKMessageModel.h
//  CyweeBleSDK-iOS_Example
//
//  Created by rohn on 2024/10/21.
//  Copyright © 2024 Chengang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKMessageModel : NSObject<MKMessageNotifyProtocol>

@property (nonatomic, assign)NSInteger appType;// 通知app类型
@property (nonatomic, assign)NSString* title;// 标题
@property (nonatomic, assign)NSString* content;// 消息内容
@property (nonatomic, assign)NSInteger year;//年 2024 => 24
@property (nonatomic, assign)NSInteger month;//月
@property (nonatomic, assign)NSInteger day;//日
@property (nonatomic, assign)NSInteger hour;//时
@property (nonatomic, assign)NSInteger minute;//分
@property (nonatomic, assign)NSInteger second;//秒
@end

NS_ASSUME_NONNULL_END
