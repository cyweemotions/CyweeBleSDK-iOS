//
//  MKConfigInterfaceController.m
//  CyweeBleSDK-iOS_Example
//
//  Created by aa on 2019/6/14.
//  Copyright © 2019 Chengang. All rights reserved.
//

#import "MKConfigInterfaceController.h"
#import "mk_fitpoloCentralGlobalHeader.h"

#import "MKReadDataTimeModel.h"
#import "MKAncsModel.h"
#import "MKConfigAlarmClockModel.h"
#import "MKConfigPeriodTimeModel.h"
#import "MKCustomScreenDisplayModel.h"
#import "MKUserInfoModel.h"
#import "MKMotionTargetModel.h"
#import "MKNotifyTypeModel.h"

#import "MKDeviceModulePhotoPicker.h"

#define RGB888_RED      0x00ff0000
#define RGB888_GREEN    0x0000ff00
#define RGB888_BLUE     0x000000ff

@interface MKConfigInterfaceController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong)UITableView *tableView;

@property (nonatomic, strong)NSMutableArray *dataList;

@property (nonatomic, strong)MKDeviceModulePhotoPicker *photoPicker;

@end

@implementation MKConfigInterfaceController

- (void)dealloc {
    NSLog(@"MKConfigInterfaceController销毁");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Config";
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(0);
        make.right.mas_equalTo(0);
        make.top.mas_equalTo([[UIApplication sharedApplication] statusBarFrame].size.height + 44);
        make.bottom.mas_equalTo(-39.f);
    }];
    [self loadTableDatas];
    // Do any additional setup after loading the view.
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self testInterface:indexPath.row];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MKConfigInterfaceControllerCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MKConfigInterfaceControllerCell"];
    }
    cell.textLabel.text = self.dataList[indexPath.row];
    return cell;
}

#pragma mark - interface

- (void)testInterface:(NSInteger)row {
    if (row == 0) {
        [self startOTA];
        return;
    }
    if (row == 1) {
        [self startDailUpdate];
        return;
    }
    if (row == 2) {
        //设置用户信息
        MKUserInfoModel *userInfoModel = [[MKUserInfoModel alloc] init];
        userInfoModel.name = @"小明";
        userInfoModel.male = 0;
        userInfoModel.birth = 19991109;
        userInfoModel.height = 170;
        userInfoModel.weight = 60;
        userInfoModel.hand = 0;
        userInfoModel.MHR = 200;
        [MKDeviceInterface setUserInfoWithsucBlock:userInfoModel
                                           sucBlock:^(id returnData) {
            if([returnData[@"result"] isEqualToString:@"0"]) {
                [self showAlertWithMsg:@"设置用户信息成功"];
            } else {
                [self showAlertWithMsg:@"设置用户信息失败"];
            }
        }
                                        failedBlock:^(NSError *error) {
            NSLog(@"设置用户信息失败failedBlock");
        }];
    }
    if (row == 3) {
        //获取用户信息
        [MKDeviceInterface getUserInfoWithsucBlock:^(id returnData) {
            NSDictionary *result = returnData[@"result"];
            // 将 NSDictionary 转换为字符串
            NSMutableString *resultString = [NSMutableString string];
            
            for (NSString *key in result) {
                NSString *value = result[key];
                [resultString appendFormat:@"%@: %@ \n", key, value];
            }
            [self showAlertWithMsg:resultString];
        }
                                        failedBlock:^(NSError *error) {
            NSLog(@"获取用户信息失败failedBlock");
        }];
    }
    if (row == 4) {
        //目标设置
        [MKDeviceInterface setTargetWithsucBlock:4
                                        distance:2
                                         calorie:4
                                            time:2
                                           sucBlock:^(id returnData) {
            if([returnData[@"result"] isEqualToString:@"0"]) {
                [self showAlertWithMsg:@"目标设置成功"];
            } else {
                [self showAlertWithMsg:@"目标设置失败"];
            }
        }
                                        failedBlock:^(NSError *error) {
            NSLog(@"目标设置失败failedBlock");
        }];
    }
    if (row == 5) {
        //目标获取
        [MKDeviceInterface getTargetWithsucBlock:^(id returnData) {
            NSArray *result = returnData[@"result"];
            NSInteger stepValue = [result[0] integerValue] * 1000;
            NSInteger distanceValue = [result[1] integerValue];
            NSInteger calorieValue = [result[2] integerValue] * 50;
            NSInteger sportValue = [result[3] integerValue] * 15;
            
            NSString * resultStr = [NSString stringWithFormat:@"步数目标：%ld步，\n距离目标：%ld 公里，\n卡路里目标：%ld千卡，\n运动时长目标：%ld分钟", stepValue, distanceValue,calorieValue,sportValue];
            [self showAlertWithMsg:resultStr];
        }
                                        failedBlock:^(NSError *error) {
            NSLog(@"目标设置失败failedBlock");
        }];
    }
    if (row == 6) {
        //运动目标设置
        MKMotionTargetModel *motionTargetModel = [[MKMotionTargetModel alloc] init];
        motionTargetModel.setType = 0;
        motionTargetModel.sportType = 1;
        motionTargetModel.distance = 1;
        motionTargetModel.sportTime = 2;
        motionTargetModel.calorie = 3;
        motionTargetModel.targetType = 1;
        [MKDeviceInterface setMotionTargetWithsucBlock:motionTargetModel
                                           sucBlock:^(id returnData) {
            if([returnData[@"result"] isEqualToString:@"0"]) {
                [self showAlertWithMsg:@"运动目标设置成功"];
            } else {
                [self showAlertWithMsg:@"运动目标设置失败"];
            }
        }
                                        failedBlock:^(NSError *error) {
            NSLog(@"运动目标设置失败failedBlock");
        }];
    }
    if (row == 7) {
        //运动目标获取
        int sportType = 1;
        [MKDeviceInterface getMotionTargetWithsucBlock: sportType
                                              sucBlock:^(id returnData) {
            NSArray *result = returnData[@"result"];
            NSInteger distanceTarget = [result[0] integerValue];
            NSInteger timeTarget = [result[1] integerValue];
            NSInteger calorieTarget = [result[2] integerValue];
            NSInteger targetType = [result[3] integerValue];
            NSString *target = @"";
            if(targetType == 1) {
                target = @"距离";
            } else if(targetType == 2) {
                target = @"时长";
            } else if(targetType == 3) {
                target = @"卡路里";
            } else {
                target = @"无目标";
            }
            
            NSLog(@"运动目标获取成功result%@", result);
            NSString * resultStr = [NSString stringWithFormat:@"距离目标：%ld ，\n时长目标：%ld，\n卡路里目标：%ld，\n目标类型：%ld", distanceTarget,timeTarget,calorieTarget,targetType];
            [self showAlertWithMsg:resultStr];
        }
                                           failedBlock:^(NSError *error) {
            NSLog(@"运动目标获取失败failedBlock");
        }];
    }
    if (row == 8) {
        //运动自动暂停设置
        MKMotionTargetModel *motionTargetModel = [[MKMotionTargetModel alloc] init];
        motionTargetModel.setType = 1;
        motionTargetModel.sportType = 1;
        motionTargetModel.autoPauseSwitch = 0;
        [MKDeviceInterface setMotionTargetWithsucBlock:motionTargetModel
                                              sucBlock:^(id returnData) {
            if([returnData[@"result"] isEqualToString:@"0"]) {
                [self showAlertWithMsg:@"运动自动暂停设置成功"];
            } else {
                [self showAlertWithMsg:@"运动自动暂停设置失败"];
            }
        }
                                           failedBlock:^(NSError *error) {
            NSLog(@"运动自动暂停设置失败failedBlock");
        }];
    }
    if (row == 9) {
        //运动自动暂停获取
        int sportType = 1;
        [MKDeviceInterface getMotionAutoPauseWithsucBlock:sportType
                                                 sucBlock:^(id returnData) {
            NSString *result = [returnData[@"result"]  isEqual: @"0"] ? @"开" : @"关";
            NSString * resultStr = [NSString stringWithFormat:@"自动暂停：%@", result];
            [self showAlertWithMsg:resultStr];
        }
                                              failedBlock:^(NSError *error) {
            NSLog(@"运动自动暂停获取失败failedBlock");
        }];
    }
    if (row == 10) {
        //语言设置
        NSInteger language = 0; //0-English 1-简体中文 2-繁体中文
        [MKDeviceInterface setLanguageWithsucBlock:language
                                          sucBlock:^(id returnData) {
            if([returnData[@"result"] isEqualToString:@"0"]) {
                [self showAlertWithMsg:@"语言设置成功"];
            } else {
                [self showAlertWithMsg:@"语言设置失败"];
            }
        }
                                        failedBlock:^(NSError *error) {
            NSLog(@"语言设置失败failedBlock");
        }];
    }
    
    if (row == 11) {
        //久坐提醒设置
        int toggle = 0;
        int interval = 60;
        int startTime = 8*60;
        int endTime = 21*60;
        [MKDeviceInterface setSitLongTimeAlertWithsucBlock:toggle
                                                  interval:interval
                                                 startTime:startTime
                                                   endTime:endTime
                                                  sucBlock:^(id returnData) {
            if([returnData[@"result"] isEqualToString:@"0"]) {
                [self showAlertWithMsg:@"久坐提醒设置成功"];
            } else {
                [self showAlertWithMsg:@"久坐提醒设置失败"];
            }
        }
                                               failedBlock:^(NSError *error) {
            NSLog(@"久坐提醒设置失败failedBlock");
        }];
    }
    
    if (row == 12) {
        //久坐提醒获取
        [MKDeviceInterface getSitLongTimeAlertWithsucBlock:^(id returnData) {
            NSArray *result = returnData[@"result"];
            NSInteger toggle = [result[0] integerValue];
            NSInteger interval = [result[1] integerValue];
            NSInteger startTime = [result[2] integerValue];
            NSInteger endTime = [result[3] integerValue];
            
            NSString * resultStr = [NSString stringWithFormat:@"开关：%ld，\n间隔时间：%ld ，\n开始时间：%ld，\n结束时间：%ld", toggle, interval,startTime,endTime];
            [self showAlertWithMsg:resultStr];
        }
                                        failedBlock:^(NSError *error) {
            NSLog(@"久坐提醒获取失败failedBlock");
        }];
    }
    if (row == 13) {
        //抬手亮屏设置
        int toggle = 0;
        [MKDeviceInterface setAutoLightenWithsucBlock:toggle
                                             sucBlock:^(id returnData) {
            if([returnData[@"result"] isEqualToString:@"0"]) {
                [self showAlertWithMsg:@"抬手亮屏设置成功"];
            } else {
                [self showAlertWithMsg:@"抬手亮屏设置失败"];
            }
        }
                                               failedBlock:^(NSError *error) {
            NSLog(@"抬手亮屏设置失败failedBlock");
        }];
    }
    if (row == 14) {
        //抬手亮屏获取
        [MKDeviceInterface getAutoLightenWithsucBlock:^(id returnData) {
            NSString *result = [returnData[@"result"]  isEqual: @"0"] ? @"开" : @"关";
            NSString * resultStr = [NSString stringWithFormat:@"抬手亮屏开关：%@", result];
            [self showAlertWithMsg:resultStr];
        }
                                          failedBlock:^(NSError *error) {
            NSLog(@"抬手亮屏获取失败failedBlock");
        }];
    }
    if (row == 15) {
        //心率监测设置
        [MKDeviceInterface setHeartRateMonitorWithsucBlock:1
                                                  interval:5
                                               alarmSwitch:0
                                                  minLimit:60
                                                  maxLimit:120
                                                  sucBlock:^(id returnData) {
            if([returnData[@"result"] isEqualToString:@"0"]) {
                [self showAlertWithMsg:@"心率监测设置成功"];
            } else {
                [self showAlertWithMsg:@"心率监测设置失败"];
            }
        }
                                               failedBlock:^(NSError *error) {
            NSLog(@"心率监测设置失败failedBlock");
        }];
    }
    if (row == 16) {
        //心率监测获取
        [MKDeviceInterface getHeartRateMonitorWithsucBlock:^(id returnData) {
            NSArray *result = returnData[@"result"];
            NSInteger monitorSwitch = [result[0] integerValue];
            NSInteger interval = [result[1] integerValue];
            NSInteger alarmSwitch = [result[2] integerValue];
            NSInteger minLimit = [result[3] integerValue];
            NSInteger maxLimit = [result[4] integerValue];
            
            NSString * resultStr = [NSString stringWithFormat:@"心率监控开关：%ld，\n心率监控间隔：%ld分钟，\n心率区间报警开关：%ld ，\n低心速率限制：%ld，\n高心速率限制：%ld。", monitorSwitch,interval,alarmSwitch,minLimit,maxLimit];
            [self showAlertWithMsg:resultStr];
        }
                                               failedBlock:^(NSError *error) {
            NSLog(@"心率监测获取失败failedBlock");
        }];
    }
    if (row == 17) {
        //来电提醒设置
        [MKDeviceInterface setCallReminderWithsucBlock:1
                                              sucBlock:^(id returnData) {
            if([returnData[@"result"] isEqualToString:@"0"]) {
                [self showAlertWithMsg:@"来电提醒设置成功"];
            } else {
                [self showAlertWithMsg:@"来电提醒设置失败"];
            }
        }
                                           failedBlock:^(NSError *error) {
            NSLog(@"来电提醒设置失败failedBlock");
        }];
    }
    if (row == 18) {
        //来电提醒获取
        [MKDeviceInterface getCallReminderWithsucBlock:^(id returnData) {
            NSString *result = [returnData[@"result"]  isEqual: @"0"] ? @"开" : @"关";
            NSString * resultStr = [NSString stringWithFormat:@"来电提醒开关：%@", result];
            [self showAlertWithMsg:resultStr];
        }
                                           failedBlock:^(NSError *error) {
            NSLog(@"来电提醒设置失败failedBlock");
        }];
    }
    if (row == 19) {
        //通知设置
        MKNotifyTypeModel *notifyTypeModel = [[MKNotifyTypeModel alloc] init];
        notifyTypeModel.toggle = 0;
        notifyTypeModel.common = 1;
        notifyTypeModel.facebook = 1;
        notifyTypeModel.instagram = 0;
        notifyTypeModel.kakaotalk = 1;
        notifyTypeModel.line = 1;
        notifyTypeModel.linkedin = 1;
        notifyTypeModel.SMS = 1;
        notifyTypeModel.QQ = 0;
        notifyTypeModel.twitter = 0;
        notifyTypeModel.viber = 1;
        notifyTypeModel.vkontaket = 1;
        notifyTypeModel.whatsapp = 0;
        notifyTypeModel.wechat = 1;
        notifyTypeModel.other1 = 1;
        notifyTypeModel.other2 = 1;
        notifyTypeModel.other3 = 1;
        [MKDeviceInterface setNotifyWithsucBlock:notifyTypeModel
                                        sucBlock:^(id returnData) {
            if([returnData[@"result"] isEqualToString:@"0"]) {
                [self showAlertWithMsg:@"通知设置成功"];
            } else {
                [self showAlertWithMsg:@"通知设置失败"];
            }
        }
                                     failedBlock:^(NSError *error) {
            NSLog(@"通知设置失败failedBlock");
        }];
    }
    if (row == 20) {
        //亮屏时长设置
        [MKDeviceInterface setOnScreenDurationWithsucBlock:3
                                                  sucBlock:^(id returnData) {
            if([returnData[@"result"] isEqualToString:@"0"]) {
                [self showAlertWithMsg:@"亮屏时长设置成功"];
            } else {
                [self showAlertWithMsg:@"亮屏时长设置失败"];
            }
        }
                                               failedBlock:^(NSError *error) {
            NSLog(@"亮屏时长设置失败failedBlock");
        }];
    }
    if (row == 21) {
        //亮屏时长获取
        [MKDeviceInterface getOnScreenDurationWithsucBlock:^(id returnData) {
            NSString *result = @"";
            if([returnData[@"result"] isEqual: @"0"]){
                result = @"5";
            } else if ([returnData[@"result"] isEqual: @"1"]){
                result = @"10";
            } else if ([returnData[@"result"] isEqual: @"2"]){
                result = @"15";
            } else if ([returnData[@"result"] isEqual: @"3"]){
                result = @"30";
            } else {
                result = @"60";
            }
            NSString * resultStr = [NSString stringWithFormat:@"亮屏时长：%@ S", result];
            [self showAlertWithMsg:resultStr];
        }
                                               failedBlock:^(NSError *error) {
            NSLog(@"亮屏时长设置失败failedBlock");
        }];
    }
    if (row == 22) {
        //勿扰设置
        [MKDeviceInterface setDoNotDisturbWithsucBlock:1
                                            partToggle:0
                                             startTime:21*60+10
                                               endTime:9*60+20
                                              sucBlock:^(id returnData) {
            if([returnData[@"result"] isEqualToString:@"0"]) {
                [self showAlertWithMsg:@"勿扰设置成功"];
            } else {
                [self showAlertWithMsg:@"勿扰设置失败"];
            }
        }
                                           failedBlock:^(NSError *error) {
            NSLog(@"勿扰设置失败failedBlock");
        }];
    }
    if (row == 23) {
//        [self showAlertWithMsg:@"暂无"];
//        return;
        //勿扰获取
        [MKDeviceInterface getDoNotDisturbWithsucBlock:^(id returnData) {
            NSArray *result = returnData[@"result"];
            NSInteger allToggle = [result[0] integerValue];
            NSString * allToggleStr = allToggle == 0 ? @"开": @"关";
            NSInteger partToggle = [result[1] integerValue];
            NSString * partToggleStr = partToggle == 0 ? @"开": @"关";
            
            NSInteger startTimeValue = [result[2] integerValue];
            NSString * startTimeValueStr = [NSString stringWithFormat:@"%d:%d", (int)((int)startTimeValue/60), (int)startTimeValue % 60];
            
            NSInteger endTimeValue = [result[3] integerValue];
            NSString * endTimeValueStr = [NSString stringWithFormat:@"%d:%d", (int)((int)endTimeValue/60), (int)endTimeValue % 60];
            
            NSString * resultStr = [NSString stringWithFormat:@"全天开启：%@，\n定时开启：%@ ，\n定时开启-开始时间：%@，\n定时开启-结束时间：%@", allToggleStr, partToggleStr, startTimeValueStr, endTimeValueStr];
            [self showAlertWithMsg:resultStr];
        }
                                           failedBlock:^(NSError *error) {
            NSLog(@"勿扰设置获取失败failedBlock");
        }];
    }
    if (row == 24) {
        //通讯录设置
        [MKDeviceInterface setAddressBookWithsucBlock:0
                                                 name:@"张三"
                                          phoneNumber:@"13677778888"
                                             sucBlock:^(id returnData) {
            if([returnData[@"result"] isEqualToString:@"0"]) {
                [self showAlertWithMsg:@"通讯录设置成功"];
            } else {
                [self showAlertWithMsg:@"通讯录设置失败"];
            }
        }
                                           failedBlock:^(NSError *error) {
            NSLog(@"通讯录设置获取失败failedBlock");
        }];
    }
    if (row == 25) {
        //通讯录获取
        [MKDeviceInterface getAddressBookWithsucBlock:^(id returnData) {
            NSArray<NSDictionary*> *result = returnData[@"result"];
            NSLog(@"通讯录数据%@",result);
            NSMutableString *allAddressBookStr = [[NSMutableString alloc] init];
            for (NSUInteger i=0; i<result.count; i++) {
                NSDictionary * addressBook = result[i];
                NSLog(@"通讯录数据addressBook%@",addressBook);
                
                NSString * addressBookStr = [NSString stringWithFormat:@"第%lu位联系人-姓名：%@， 电话：%@ \n", (unsigned long)(i+1), addressBook[@"name"], addressBook[@"phone"]];
                [allAddressBookStr appendString:addressBookStr];

            }
            [self showAlertWithMsg:allAddressBookStr];
        }
                                           failedBlock:^(NSError *error) {
            NSLog(@"通讯录获取失败failedBlock");
        }];
    }
    if (row == 26) {
        //睡眠监测设置
        int startTime = 23*60+30;
        int endTime = 8*60;
        //ff0b00040600058201e000ffff
        [MKDeviceInterface setSleepWithsucBlock:0
                                      startTime:startTime
                                        endTime:endTime
                                       sucBlock:^(id returnData) {
            if([returnData[@"result"] isEqualToString:@"0"]) {
                [self showAlertWithMsg:@"睡眠监测设置成功"];
            } else {
                [self showAlertWithMsg:@"睡眠监测设置失败"];
            }
        }
                                           failedBlock:^(NSError *error) {
            NSLog(@"睡眠监测设置获取失败failedBlock");
        }];
    }
    if (row == 27) {
        //睡眠监测获取
        [MKDeviceInterface getSleepWithsucBlock:^(id returnData) {
            NSArray *result = returnData[@"result"];
            NSInteger toggle = [result[0] integerValue];
            NSInteger startTime = [result[1] integerValue];
            NSInteger endTime = [result[2] integerValue];
            
            NSString * resultStr = [NSString stringWithFormat:@"开关：%ld ，\n开始时间：%ld，\n结束时间：%ld", toggle,startTime,endTime];
            [self showAlertWithMsg:resultStr];
        }
                                        failedBlock:^(NSError *error) {
            NSLog(@"睡眠获取失败failedBlock");
        }];
    }
    if (row == 28) {
        //时间格式设置
        int timeFormat = 1;
        int dateFormat = 2;
        int timeZone = 8;
        [MKDeviceInterface setDateTimeFormatWithsucBlock:timeFormat
                                              dateFormat:dateFormat
                                                timeZone:timeZone
                                                sucBlock:^(id returnData) {
            if([returnData[@"result"] isEqualToString:@"0"]) {
                [self showAlertWithMsg:@"时间格式设置成功"];
            } else {
                [self showAlertWithMsg:@"时间格式设置失败"];
            }
        }
                                             failedBlock:^(NSError *error) {
            NSLog(@"时间格式获取失败failedBlock");
        }];
    }
    if (row == 29) {
        //时间格式获取
        [MKDeviceInterface getDateTimeFormatWithsucBlock:^(id returnData) {
            NSArray *result = returnData[@"result"];
            NSInteger toggle = [result[0] integerValue];
            NSInteger startTime = [result[1] integerValue];
            NSInteger endTime = [result[2] integerValue];
            
            NSString * resultStr = [NSString stringWithFormat:@"时间格式：%ld ，\n日期格式：%ld，\n时区：%ld", toggle,startTime,endTime];
            [self showAlertWithMsg:resultStr];
        }
                                             failedBlock:^(NSError *error) {
            NSLog(@"时间格式获取失败failedBlock");
        }];
    }
    if (row == 30) {
        //达标提醒设置
        int toggle = 0;
        [MKDeviceInterface setStandardAlertWithsucBlock:toggle
                                               sucBlock:^(id returnData) {
            if([returnData[@"result"] isEqualToString:@"0"]) {
                [self showAlertWithMsg:@"达标提醒设置成功"];
            } else {
                [self showAlertWithMsg:@"达标提醒设置失败"];
            }
        }
                                            failedBlock:^(NSError *error) {
            NSLog(@"达标提醒获取失败failedBlock");
        }];
    }
    if (row == 31) {
        //达标提醒获取
        [MKDeviceInterface getStandardAlertWithsucBlock:^(id returnData) {
            NSString *result = [returnData[@"result"]  isEqual: @"0"] ? @"开" : @"关";
            NSString * resultStr = [NSString stringWithFormat:@"达标提醒开关：%@", result];
            [self showAlertWithMsg:resultStr];
        }
                                            failedBlock:^(NSError *error) {
            NSLog(@"达标提醒获取失败failedBlock");
        }];
    }
    if (row == 32) {
        //省电模式设置
        int toggle = 0;
        [MKDeviceInterface setPowerSaveWithsucBlock:toggle
                                           sucBlock:^(id returnData) {
            if([returnData[@"result"] isEqualToString:@"0"]) {
                [self showAlertWithMsg:@"省电模式设置成功"];
            } else {
                [self showAlertWithMsg:@"省电模式设置失败"];
            }
        }
                                        failedBlock:^(NSError *error) {
            NSLog(@"省电模式获取失败failedBlock");
        }];
    }
    if (row == 33) {
        //省电模式获取
        [MKDeviceInterface getPowerSaveWithsucBlock:^(id returnData) {
            NSString *result = [returnData[@"result"]  isEqual: @"0"] ? @"开" : @"关";
            NSString * resultStr = [NSString stringWithFormat:@"省电模式开关：%@", result];
            [self showAlertWithMsg:resultStr];
        }
                                        failedBlock:^(NSError *error) {
            NSLog(@"省电模式获取失败failedBlock");
        }];
    }
    if (row == 34) {
        //睡眠算法设置
        int accuracyToggle = 0;
        int breatheToggle = 1;
        [MKDeviceInterface setSleepMonitorWithsucBlock:accuracyToggle
                                         breatheToggle:breatheToggle
                                              sucBlock:^(id returnData) {
            if([returnData[@"result"] isEqualToString:@"0"]) {
                [self showAlertWithMsg:@"睡眠算法设置成功"];
            } else {
                [self showAlertWithMsg:@"睡眠算法设置失败"];
            }
        }
                                           failedBlock:^(NSError *error) {
            NSLog(@"睡眠算法获取失败failedBlock");
        }];
    }
    if (row == 35) {
        //睡眠算法获取
        [MKDeviceInterface getSleepMonitorWithsucBlock:^(id returnData) {
            NSArray *result = returnData[@"result"];
            NSInteger accuracyToggle = [result[0] integerValue];
            NSInteger breatheToggle = [result[1] integerValue];
            
            NSLog(@"睡眠算法获取成功result%@", result);
            NSString * resultStr = [NSString stringWithFormat:@"睡眠高精度监测：%ld ，\n睡眠呼吸质量监测：%ld", accuracyToggle,breatheToggle];
            [self showAlertWithMsg:resultStr];
        }
                                           failedBlock:^(NSError *error) {
            NSLog(@"睡眠算法获取失败failedBlock");
        }];
    }
}

#pragma mark -

//- (void)configDate {
//    MKConfigDateModel *model = [[MKConfigDateModel alloc] init];
//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    [formatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
//    NSString *dateString = [formatter stringFromDate:[NSDate date]];
//    NSArray *dateList = [dateString componentsSeparatedByString:@"-"];
//    model.year = [dateList[0] integerValue];
//    model.month = [dateList[1] integerValue];
//    model.day = [dateList[2] integerValue];
//    model.hour = [dateList[3] integerValue];
//    model.minutes = [dateList[4] integerValue];
//    model.seconds = [dateList[5] integerValue];
//    [MKUserDataInterface configDate:model sucBlock:^(id returnData) {
//        [self showAlertWithMsg:@"Success"];
//        NSLog(@"%@",returnData);
//    } failedBlock:^(NSError *error) {
//        [self showAlertWithMsg:error.userInfo[@"errorInfo"]];
//    }];
//}

//- (void)configUserData {
//    MKConfigUserDataModel *dataModel = [[MKConfigUserDataModel alloc] init];
//    dataModel.weight = 75;
//    dataModel.height = 175;
//    dataModel.gender = mk_fitpoloGenderMale;
//    dataModel.userAge = 30;
//    [MKUserDataInterface configUserData:dataModel sucBlock:^(id returnData) {
//        [self showAlertWithMsg:@"Success"];
//        NSLog(@"%@",returnData);
//    } failedBlock:^(NSError *error) {
//        [self showAlertWithMsg:error.userInfo[@"errorInfo"]];
//    }];
//}


- (void)configDialUI {
    __weak __typeof(&*self)weakSelf = self;
    [self.photoPicker showPhotoPickerBlock:^(UIImage * _Nonnull bigImage, UIImage * _Nonnull smallImage) {
        [weakSelf processSmallImage:smallImage];
    } imageSize:CGSizeMake(240, 240)];
}


- (void)processSmallImage:(UIImage *)image {
    if (!image || ![image isKindOfClass:UIImage.class]) {
        return;
    }
    [[MKHudManager share] showHUDWithTitle:@"Waiting..." inView:self.view isPenetration:NO];
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(image.CGImage);
    CGColorSpaceRef colorRef = CGColorSpaceCreateDeviceRGB();

    float width = image.size.width;
    float height = image.size.height;

    // Get source image data
    UInt32 *imageData = (UInt32 *) malloc(width * height * 4);

    CGContextRef imageContext = CGBitmapContextCreate(imageData,
            width, height,
            8, (width * 4),
            colorRef, alphaInfo);

    CGContextDrawImage(imageContext, CGRectMake(0, 0, width, height), image.CGImage);
    CGContextRelease(imageContext);
    CGColorSpaceRelease(colorRef);

    UInt32 * currentPixel = imageData;
    NSMutableData *binData = [NSMutableData data];
    for (NSUInteger j = 0; j < height; j++) {
        for (NSUInteger i = 0; i < width; i++) {
            UInt32 color = [self colorHexValue:(*currentPixel)];
            UInt32 rgb565 = [self RGB888ToRGB565:color];
            NSString *temp = [NSString stringWithFormat:@"%1x",(unsigned int)rgb565];
            if (temp.length == 1) {
                temp = [@"000" stringByAppendingString:temp];
            }else if (temp.length == 2) {
                temp = [@"00" stringByAppendingString:temp];
            }else if (temp.length == 3) {
                temp = [@"0" stringByAppendingString:temp];
            }
            NSData *tempData = [mk_fitpoloAdopter stringToData:temp];
            [binData appendData:tempData];
            currentPixel++;
        }
    }
    [MKDeviceInterface configH709DialStyleCustomUI:MKH709CustomUIIndex0 sucBlock:^(id returnData) {
        [self startUpdateUI:binData];
    } failedBlock:^(NSError *error) {
        [[MKHudManager share] hide];
        [self showAlertWithMsg:error.userInfo[@"errorInfo"]];
    }];
}

- (void)startUpdateUI:(NSData *)uiData {
    

}
///开启OTA升级
- (void)startOTA{
    ///获取路径
    NSString *filePath =  [[NSBundle mainBundle] pathForResource:@"ota_full-2.0.0.AiRunning.bin" ofType:nil];
    NSLog(@"文件路径%@",filePath);
    [mk_fitpoloUpdateCenter sharedInstance].progressCallBack = ^(CGFloat progress) {
        NSInteger value = (progress * 100);
        dispatch_sync_on_main_queue(^{
            [[MKHudManager share] showHUDWithTitle:[NSString stringWithFormat:@"OTA 进度:%ld%%",value] inView:self.view isPenetration:NO];
            if(value >= 99){
                [[MKHudManager share] hideAfterDelay:1];
            }
        });
    };
    [[mk_fitpoloUpdateCenter sharedInstance] updateOtaFromPath:filePath];
    
}

////开启表盘升级
- (void)startDailUpdate{
    ///获取路径
    NSString *json =  [[NSBundle mainBundle] pathForResource:@"dial.json" ofType:nil];
    NSString *res =  [[NSBundle mainBundle] pathForResource:@"dial.res" ofType:nil];
    NSString *sty =  [[NSBundle mainBundle] pathForResource:@"dial.sty" ofType:nil];
    NSDictionary *jsonAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:json error:nil];
    NSDictionary *resAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:res error:nil];
    NSDictionary *styAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:sty error:nil];
    NSInteger filetotalSize = jsonAttributes.fileSize + resAttributes.fileSize + styAttributes.fileSize;
    
    ///文件内容
    NSLog(@"文件路径%@-大小%d",json,jsonAttributes.fileSize);
    NSLog(@"文件路径%@-大小%d",res,resAttributes.fileSize);
    NSLog(@"文件路径%@-大小%d",sty,styAttributes.fileSize);
    [mk_fitpoloUpdateCenter sharedInstance].progressCallBack = ^(CGFloat progress) {
        dispatch_sync_on_main_queue(^{
            NSInteger value = progress*100;
            NSLog(@"进度值:%.2f",progress);
            [[MKHudManager share] showHUDWithTitle:[NSString stringWithFormat:@"表盘同步进度:%ld%%",value] inView:self.view isPenetration:NO];
            if(value >= 98){
                [[MKHudManager share] hideAfterDelay:1];
            }
        });
    };
    [mk_fitpoloUpdateCenter sharedInstance].failedBlock = ^(NSError * _Nonnull error) {
        [[MKHudManager share] showHUDWithTitle:@"表盘传输失败" inView:self.view isPenetration:NO];
        [[MKHudManager share] hideAfterDelay:3];
    };
    [[mk_fitpoloUpdateCenter sharedInstance] startDailFileSync:@[json,res,sty] size:filetotalSize];

}

- (UInt32)colorHexValue:(UInt32)origColor {
    NSString *tempRGB888 = [NSString stringWithFormat:@"%1x",(unsigned int)origColor];
    NSInteger len = tempRGB888.length;
    NSString *rgb888 = @"";
    for (NSInteger i = 0; i < (8 - len); i ++) {
        rgb888 = [@"0" stringByAppendingString:rgb888];
    }
    NSString *rgb = [rgb888 stringByAppendingString:tempRGB888];
    NSInteger bigData = [self bigData:rgb];
    return ((UInt32)bigData);
}

- (NSInteger)bigData:(NSString *)content {
    NSMutableArray *list = [NSMutableArray array];
    for (NSInteger i = 0; i < content.length / 2; i ++) {
        NSString *string = [content substringWithRange:NSMakeRange(2 * i, 2)];
        [list addObject:string];
    }
    NSString *tempString = @"";
    for (NSInteger i = content.length / 2 - 1; i >= 0; i--) {
        tempString = [tempString stringByAppendingString:list[i]];
    }
    return [mk_fitpoloAdopter getDecimalWithHex:tempString range:NSMakeRange(0, tempString.length)];
}

- (UInt32)RGB888ToRGB565:(UInt32)n888Color {
    UInt32 n565Color = 0;
    // 获取RGB单色，并截取高位
    UInt32 cRed   = (n888Color & RGB888_RED)   >> 19;
    UInt32 cGreen = (n888Color & RGB888_GREEN) >> 10;
    UInt32 cBlue  = (n888Color & RGB888_BLUE)  >> 3;
    
    // 连接
    n565Color = (cRed << 11) + (cGreen << 5) + (cBlue << 0);
    return n565Color;
}

#pragma mark - private method
- (void)showAlertWithMsg:(NSString *)msg{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示"
                                                                             message:msg
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *moreAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alertController addAction:moreAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)loadTableDatas {
    [self.dataList addObject:@"OTA Update"];
    [self.dataList addObject:@"Dail Update"];
    [self.dataList addObject:@"设置用户信息"];
    [self.dataList addObject:@"获取用户信息"];
    [self.dataList addObject:@"每日目标设置"];
    [self.dataList addObject:@"每日目标获取"];
    [self.dataList addObject:@"运动目标设置"];
    [self.dataList addObject:@"运动目标获取"];
    [self.dataList addObject:@"运动自动暂停设置"];
    [self.dataList addObject:@"运动自动暂停获取"];
    [self.dataList addObject:@"语言设置"];
    [self.dataList addObject:@"久坐提醒设置"];
    [self.dataList addObject:@"久坐提醒获取"];
    [self.dataList addObject:@"抬手亮屏设置"];
    [self.dataList addObject:@"抬手亮屏获取"];
    [self.dataList addObject:@"心率监测设置"];
    [self.dataList addObject:@"心率监测获取"];
    [self.dataList addObject:@"来电提醒设置"];
    [self.dataList addObject:@"来电提醒获取"];
    [self.dataList addObject:@"通知设置"];
    [self.dataList addObject:@"亮屏时长设置"];
    [self.dataList addObject:@"亮屏时长获取"];
    [self.dataList addObject:@"勿扰设置"];
    [self.dataList addObject:@"勿扰获取"];
    [self.dataList addObject:@"通讯录设置"];
    [self.dataList addObject:@"通讯录获取"];
    [self.dataList addObject:@"睡眠监测设置"];
    [self.dataList addObject:@"睡眠监测获取"];
    [self.dataList addObject:@"时间格式设置"];
    [self.dataList addObject:@"时间格式获取"];
    [self.dataList addObject:@"达标提醒设置"];
    [self.dataList addObject:@"达标提醒获取"];
    [self.dataList addObject:@"省电模式设置"];
    [self.dataList addObject:@"省电模式获取"];
    [self.dataList addObject:@"睡眠算法设置"];
    [self.dataList addObject:@"睡眠算法获取"];
    [self.tableView reloadData];
}

#pragma mark - setter & getter
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor whiteColor];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}

- (NSMutableArray *)dataList {
    if (!_dataList) {
        _dataList = [NSMutableArray array];
    }
    return _dataList;
}

- (MKDeviceModulePhotoPicker *)photoPicker {
    if (!_photoPicker) {
        _photoPicker = [[MKDeviceModulePhotoPicker alloc] init];
    }
    return _photoPicker;
}

@end
