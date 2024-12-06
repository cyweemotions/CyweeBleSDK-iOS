//
//  MKMotionTargetModel.h
//  CyweeBleSDK-iOS_Example
//
//  Created by rohn on 2024/10/15.
//  Copyright © 2024 Chengang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKMotionTargetModel : NSObject<MKMotionTargetProtocol>
//类型：0- 目标设置 1-自动暂停设置
@property (nonatomic, assign)NSInteger setType;
//0-户外步行 1-户外跑步 2-户外骑行 3-室内步行
@property (nonatomic, assign)NSInteger sportType;
//距离 单位公里 区间0-99
@property (nonatomic, assign)NSInteger distance;
//时间 单位分 区间0-23 实际值*10+5
@property (nonatomic, assign)NSInteger sportTime;
//卡路里 单位千卡 区间0-9 实际值*100
@property (nonatomic, assign)NSInteger calorie;
//目标设置类型 0-none 1-distance 2-sportTime 3-calorie
@property (nonatomic, assign)NSInteger targetType;
//自动暂停开关 当setType为1的情况下设置
@property (nonatomic, assign)NSInteger autoPauseSwitch;

- (instancetype)init;

@end

NS_ASSUME_NONNULL_END
