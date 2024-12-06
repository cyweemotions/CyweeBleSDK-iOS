//
//  MKUserInfoModel.h
//  CyweeBleSDK-iOS_Example
//
//  Created by rohn on 2024/10/14.
//  Copyright © 2024 Chengang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKUserInfoModel : NSObject<MKUserInfoProtocol>

@property (nonatomic, assign)NSString *name;
//性别 0-男 1-女
@property (nonatomic, assign)NSInteger male;
//出生年月日
@property (nonatomic, assign)NSInteger birth;
// 身高
@property (nonatomic, assign)NSInteger height;
// 体重
@property (nonatomic, assign)NSInteger weight;
// 佩戴， 0–左手， 1–右手
@property (nonatomic, assign)NSInteger hand;
// 最大心率（次/分）
@property (nonatomic, assign)NSInteger MHR;

@end

NS_ASSUME_NONNULL_END
