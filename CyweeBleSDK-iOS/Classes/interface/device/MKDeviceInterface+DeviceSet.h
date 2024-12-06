//
//  MKDeviceInterface+DeviceSet.h
//  CyweeBleSDK-iOS
//
//  Created by cywee on 2024/10/9.
//

#import "MKDeviceInterface.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKDeviceInterface (DeviceSet)

#pragma mark - 设置/设置获取类型
//设置用户信息
+ (void)setUserInfoWithsucBlock:(id <MKUserInfoProtocol>)protocol
                       sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                    failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//获取用户信息
+ (void)getUserInfoWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                    failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//目标设置
+ (void)setTargetWithsucBlock:(int)step
                       distance:(int)distance
                        calorie:(int)calorie
                           time:(int)time
                       sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                    failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//目标获取
+ (void)getTargetWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                  failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//运动目标设置
+ (void)setMotionTargetWithsucBlock:(id <MKMotionTargetProtocol>)protocol
                           sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                        failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//运动目标获取
+ (void)getMotionTargetWithsucBlock:(int)sportType
                           sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                        failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//运动自动暂停获取
+ (void)getMotionAutoPauseWithsucBlock:(int)sportType
                              sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                           failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//语言设置
+ (void)setLanguageWithsucBlock:(NSInteger) language
                           sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                        failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//久坐提醒设置
+ (void)setSitLongTimeAlertWithsucBlock:(int) toggle
                               interval:(int) interval
                              startTime:(int) startTime
                                endTime:(int) endTime
                               sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                            failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//久坐提醒获取
+ (void)getSitLongTimeAlertWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                            failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//抬手亮屏设置
+ (void)setAutoLightenWithsucBlock:(int) toggle
                          sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                       failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//抬手亮屏获取
+ (void)getAutoLightenWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                       failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//心率监测设置
+ (void)setHeartRateMonitorWithsucBlock:(int)monitorSwitch
                               interval:(int)interval
                            alarmSwitch:(int)alarmSwitch
                               minLimit:(int)minLimit
                               maxLimit:(int)maxLimit
                               sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                            failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//心率监测获取
+ (void)getHeartRateMonitorWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                            failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//来电提醒设置
+ (void)setCallReminderWithsucBlock:(int)toggle
                           sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                        failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//来电提醒获取
+ (void)getCallReminderWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                        failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//通知设置
+ (void)setNotifyWithsucBlock:(id <MKNotifyTypeProtocol>)protocol
                     sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                  failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//亮屏时长设置
+ (void)setOnScreenDurationWithsucBlock:(int)toggle
                               sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                            failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//亮屏时长获取
+ (void)getOnScreenDurationWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                            failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//勿扰设置
+ (void)setDoNotDisturbWithsucBlock:(int)allToggle// 全天勿扰开关 0–开 1–关
                         partToggle:(int)partToggle// 时段勿扰开关 0-开 1-关
                          startTime:(int)startTime// 勿扰模式时间段起始，单位分钟 23*60
                            endTime:(int)endTime// 勿扰模式时间段结束，单位分钟 8*60
                           sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                        failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//勿扰获取
+ (void)getDoNotDisturbWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                        failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//通讯录设置
+ (void)setAddressBookWithsucBlock:(int)action// 0-添加 1-删除
                              name:(NSString*)name //名字
                       phoneNumber:(NSString*)phoneNumber //电话
                          sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                        failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//通讯录获取
+ (void)getAddressBookWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                        failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//睡眠设置
+ (void)setSleepWithsucBlock:(int) toggle
                   startTime:(int) startTime
                     endTime:(int) endTime
                    sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                 failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//睡眠设置获取
+ (void)getSleepWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                 failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//时间格式设置
+ (void)setDateTimeFormatWithsucBlock:(int)timeFormat
                           dateFormat:(int)dateFormat
                             timeZone:(int)timeZone
                             sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                          failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//时间格式获取
+ (void)getDateTimeFormatWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                          failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//达标提醒设置
+ (void)setStandardAlertWithsucBlock:(int)toggle
                            sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                         failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//达标提醒获取
+ (void)getStandardAlertWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                         failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//省电模式设置
+ (void)setPowerSaveWithsucBlock:(int)toggle
                            sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                         failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//省电模式获取
+ (void)getPowerSaveWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                         failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//睡眠算法设置
+ (void)setSleepMonitorWithsucBlock:(int)accuracyToggle
                      breatheToggle:(int)breatheToggle
                           sucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                        failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;
//睡眠算法获取
+ (void)getSleepMonitorWithsucBlock:(mk_deviceInterfaceSucBlock)sucBlock
                        failedBlock:(mk_deviceInterfaceFailedBlock)failedBlock;

#pragma mark - other mothed

+ (NSMutableArray<NSNumber *>*)notifyData2List:(id <MKUserInfoProtocol>)protocol;
+ (NSString *)binaryStringForByte:(uint8_t)byte;
@end

NS_ASSUME_NONNULL_END
