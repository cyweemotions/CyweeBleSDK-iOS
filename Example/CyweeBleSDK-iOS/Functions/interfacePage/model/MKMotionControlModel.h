//
//  MKMotionControlModel.h
//  CyweeBleSDK-iOS_Example
//
//  Created by rohn on 2024/10/9.
//  Copyright © 2024 Chengang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKMotionControlModel : NSObject<MKMotionControlProtocol>

@property (nonatomic, assign)NSInteger type;

@property (nonatomic, assign)NSInteger action;

@end

NS_ASSUME_NONNULL_END
