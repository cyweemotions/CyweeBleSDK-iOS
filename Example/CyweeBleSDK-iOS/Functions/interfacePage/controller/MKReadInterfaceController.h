//
//  MKReadInterfaceController.h
//  CyweeBleSDK-iOS_Example
//
//  Created by aa on 2019/6/13.
//  Copyright © 2019 Chengang. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^testBlock)(NSString *str);

@interface MKReadInterfaceController : UIViewController

@property (nonatomic,weak) testBlock callBack;

@end

NS_ASSUME_NONNULL_END
