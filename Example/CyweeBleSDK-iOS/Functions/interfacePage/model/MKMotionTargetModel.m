//
//  MKMotionTargetModel.m
//  CyweeBleSDK-iOS_Example
//
//  Created by rohn on 2024/10/15.
//  Copyright © 2024 Chengang. All rights reserved.
//

#import "MKMotionTargetModel.h"

@implementation MKMotionTargetModel
- (instancetype)init {
    self = [super init];
    if (self) {
        // 设置默认值
        _setType = 0;
        _sportType = 0;
        _distance = 0;
        _sportTime = 0;
        _calorie = 0;
        _targetType = 0;
        _autoPauseSwitch = 0;
    }
    return self;
}

@end
