//
//  MKNotifyTypeModel.h
//  CyweeBleSDK-iOS_Example
//
//  Created by rohn on 2024/10/21.
//  Copyright © 2024 Chengang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKNotifyTypeModel : NSObject<MKNotifyTypeProtocol>
@property (nonatomic, assign)NSInteger  toggle; // 开关 0-开 1-关
@property (nonatomic, assign)NSInteger  common; // F0 - common
@property (nonatomic, assign)NSInteger  facebook; // F1 - facebook
@property (nonatomic, assign)NSInteger  instagram; // F2 - instagram
@property (nonatomic, assign)NSInteger  kakaotalk; // F3 - kakaotalk
@property (nonatomic, assign)NSInteger  line; // F4 - line
@property (nonatomic, assign)NSInteger  linkedin; // F5 - linkedin
@property (nonatomic, assign)NSInteger  SMS; // F6 - SMS
@property (nonatomic, assign)NSInteger  QQ; // F7 - QQ
@property (nonatomic, assign)NSInteger  twitter; // F8 - twitter
@property (nonatomic, assign)NSInteger  viber; // F9 - viber
@property (nonatomic, assign)NSInteger  vkontaket; // F10 - vkontaket
@property (nonatomic, assign)NSInteger  whatsapp; // F11 - whatsapp
@property (nonatomic, assign)NSInteger  wechat; // F12 - wechat
@property (nonatomic, assign)NSInteger  other1; // F13 - other1
@property (nonatomic, assign)NSInteger  other2; // F14 - other2
@property (nonatomic, assign)NSInteger  other3; // F15 - other3
@end

NS_ASSUME_NONNULL_END
