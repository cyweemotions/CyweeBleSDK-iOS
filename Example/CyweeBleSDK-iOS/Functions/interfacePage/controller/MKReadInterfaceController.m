//
//  MKReadInterfaceController.m
//  CyweeBleSDK-iOS_Example
//
//  Created by aa on 2019/6/13.
//  Copyright © 2019 Chengang. All rights reserved.
//

#import "MKReadInterfaceController.h"
#import "MKReadDataTimeModel.h"
#import "MKMotionControlModel.h"
#import "MKMessageModel.h"

@interface MKReadInterfaceController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong)UITableView *tableView;

@property (nonatomic, strong)NSMutableArray *dataList;

@end

@implementation MKReadInterfaceController

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:mk_sportDataNotification object:nil];
    NSLog(@"MKReadInterfaceController销毁");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Read";
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(0);
        make.right.mas_equalTo(0);
        make.top.mas_equalTo([[UIApplication sharedApplication] statusBarFrame].size.height + 44);
        make.bottom.mas_equalTo(-39.f);
    }];
    [self loadTableDatas];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
      selector:@selector(sportResultNotification:)
          name:mk_sportDataNotification
        object:nil];
    // Do any additional setup after loading the view.
}

/**
 获取运动中数据通知
 
 @param obj 运动中数据
 */
- (void)sportResultNotification:(NSNotification *)obj{
    NSDictionary * dataDic = [obj userInfo];
    NSArray *data = dataDic[@"sportData"];
    NSLog(@"监听运动中数据返回===%@", data);
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MKReadInterfaceControllerCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MKReadInterfaceControllerCell"];
    }
    cell.textLabel.text = self.dataList[indexPath.row];
    return cell;
}

#pragma mark - interface

- (void)testInterface:(NSInteger)row {
    if ([mk_fitpoloCentralManager sharedInstance].deviceType == mk_fitpoloUnknow) {
        return;
    }
//    if (row == 0) {
//        //读取间隔计步数据
//        MKReadDataTimeModel *timeModel = [[MKReadDataTimeModel alloc] init];
//        timeModel.year = 2000;
//        timeModel.month = 1;
//        timeModel.day = 1;
//        timeModel.hour = 1;
//        timeModel.minutes = 1;
//        [MKUserDataInterface readStepIntervalDataWithTimeStamp:timeModel sucBlock:^(id returnData) {
//            [self showAlertWithMsg:@"Success"];
//            NSLog(@"%@",returnData);
//        } failedBlock:^(NSError *error) {
//            [self showAlertWithMsg:error.userInfo[@"errorInfo"]];
//        }];
//        return;
//    }
    
    if(row == 0){
        //查询鉴权状态
        [MKDeviceInterface queryAuthStateWithsucBlock:^(id returnData) {
            NSLog(@"queryAuthState success");
            NSLog(@"查询鉴权状态success %@", returnData);
            if([returnData[@"result"] isEqualToString:@"01"]) {
                [self showAlertWithMsg:@"设备已绑定"];
            } else {
                [self showAlertWithMsg:@"设备未绑定"];
            }
        } failedBlock:^(NSError *error) {
            NSLog(@"queryAuthState failedBlock");
        }];
    }
    if(row == 1){
        //设备绑定——鉴权
        [MKDeviceInterface deviceBindWithsucBlock:^(id returnData) {
            if ([returnData[@"result"] isEqual: @"2"]){
                [self showAlertWithMsg:@"设备已绑定"];
            } else if ([returnData[@"result"] isEqual: @"3"]){
                [self showAlertWithMsg:@"设备绑定成功"];
            } else if ([returnData[@"result"] isEqual: @"4"]){
                [self showAlertWithMsg:@"设备绑定失败"];
            }
        } failedBlock:^(NSError *error) {
            NSLog(@"设备绑定 failedBlock");
        }];
    }
    
    if(row == 2){
        //查找设备
        [MKDeviceInterface searchDeviceWithsucBlock:@"01"
                                           sucBlock:^(id returnData) {
            if([returnData[@"result"] isEqualToString:@"00"]) {
                [self showAlertWithMsg:@"查找设备成功"];
            } else {
                [self showAlertWithMsg:@"查找设备失败"];
            }
        } 
                                        failedBlock:^(NSError *error) {
            NSLog(@"findDevice failedBlock");
        }];
    }
    if(row == 3){
        //解绑设备
        [MKDeviceInterface unbindDeviceWithsucBlock:^(id returnData) {
            if([returnData[@"result"] isEqualToString:@"00"]) {
                [self showAlertWithMsg:@"解绑设备成功"];
            } else {
                [self showAlertWithMsg:@"解绑设备成功"];
            }
        } failedBlock:^(NSError *error) {
            NSLog(@"unbindDevice failedBlock");
        }];
    }
    if(row == 4){
        //获取电量
        [MKDeviceInterface getBatteryWithsucBlock:^(id returnData) {
            NSLog(@"获取电量 success");
            NSLog(@"获取电量 success%@", returnData);
            NSString *resultString = [NSString stringWithFormat:@"%@", returnData[@"result"]];
            [self showAlertWithMsg:[NSString stringWithFormat:@"%@ %@", @"电量：", resultString]];
        } failedBlock:^(NSError *error) {
            NSLog(@"获取电量 failedBlock");
        }];

    }
    if(row == 5){
        //运动控制
        MKMotionControlModel *motionModel = [[MKMotionControlModel alloc] init];
        motionModel.type = 0; //  0,1,2,5;
        motionModel.action = 1; // 1，3，4，5
        [MKDeviceInterface motionControlWithsucBlock:motionModel
                                           sucBlock:^(id returnData) {
            if([returnData[@"result"] isEqualToString:@"00"]) {
                [self showAlertWithMsg:@"开始运动成功"];
            } else {
                [self showAlertWithMsg:@"开始运动失败"];
            }
        }
                                        failedBlock:^(NSError *error) {
            NSLog(@"运动控制失败failedBlock");
        }];
    }
    if(row == 6){
        //暂停运动
        MKMotionControlModel *motionModel = [[MKMotionControlModel alloc] init];
        motionModel.type = 0; //  0,1,2,5;
        motionModel.action = 3; // 1，3，4，5
        [MKDeviceInterface motionControlWithsucBlock:motionModel
                                           sucBlock:^(id returnData) {
            if([returnData[@"result"] isEqualToString:@"00"]) {
                [self showAlertWithMsg:@"暂停运动成功"];
            } else {
                [self showAlertWithMsg:@"暂停运动失败"];
            }
        }
                                        failedBlock:^(NSError *error) {
            NSLog(@"运动控制失败failedBlock");
        }];
    }
    if(row == 7){
        //继续运动
        MKMotionControlModel *motionModel = [[MKMotionControlModel alloc] init];
        motionModel.type = 0; //  0,1,2,5;
        motionModel.action = 4; // 1，3，4，5
        [MKDeviceInterface motionControlWithsucBlock:motionModel
                                           sucBlock:^(id returnData) {
            if([returnData[@"result"] isEqualToString:@"00"]) {
                [self showAlertWithMsg:@"继续运动成功"];
            } else {
                [self showAlertWithMsg:@"继续运动失败"];
            }
        }
                                        failedBlock:^(NSError *error) {
            NSLog(@"运动控制失败failedBlock");
        }];
    }
    if(row == 8){
        //结束运动
        MKMotionControlModel *motionModel = [[MKMotionControlModel alloc] init];
        motionModel.type = 0; //  0,1,2,5;
        motionModel.action = 5; // 1，3，4，5
        [MKDeviceInterface motionControlWithsucBlock:motionModel
                                           sucBlock:^(id returnData) {
            if([returnData[@"result"] isEqualToString:@"00"]) {
                [self showAlertWithMsg:@"结束运动成功"];
            } else {
                [self showAlertWithMsg:@"结束运动失败"];
            }
        }
                                        failedBlock:^(NSError *error) {
            NSLog(@"运动控制失败failedBlock");
        }];
    }
    if(row == 9){
        //语言支持
        [MKDeviceInterface getLanguageSupportWithsucBlock:^(id returnData) {
            NSArray *result = returnData[@"result"];
            NSString *english = [result[0] integerValue] == 1 ? @"支持" : @"不支持";
            NSString *simpChinese = [result[1] integerValue] == 1 ? @"支持" : @"不支持";
            NSString *tradChinese = [result[2] integerValue] == 1 ? @"支持" : @"不支持";
            
            NSString * resultStr = [NSString stringWithFormat:@"英语：%@，\n简体中文：%@，\n繁体中文：%@", english, simpChinese, tradChinese];
            [self showAlertWithMsg:resultStr];
        }
                                        failedBlock:^(NSError *error) {
            NSLog(@"语言支持失败failedBlock");
        }];
    }
    if(row == 10){
        //获取设备信息
        [MKDeviceInterface getDeviceInfoWithsucBlock:^(id returnData) {
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
            NSLog(@"获取设备信息失败failedBlock");
        }];
    }
    if(row == 11){
        //时间校准
        [MKDeviceInterface timeAlignWithsucBlock:^(id returnData) {
            if([returnData[@"result"] isEqualToString:@"0"]) {
                [self showAlertWithMsg:@"时间校准成功"];
            } else {
                [self showAlertWithMsg:@"时间校准失败"];
            }
        }
                                     failedBlock:^(NSError *error) {
            NSLog(@"时间校准失败failedBlock");
        }];
    }
    if(row == 12){
        //消息通知
        NSDate *currentDate = [NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitWeekday) fromDate:currentDate];
        NSInteger year = components.year % 2000;
        NSInteger month = components.month;
        NSInteger day = components.day;
        NSInteger hour = components.hour;
        NSInteger minute = components.minute;
        NSInteger second = components.second;
        NSLog(@"当前日期和时间: %ld年%ld月%ld日 %ld时%ld分%ld秒", (long)year, (long)month, (long)day, (long)hour, (long)minute, (long)second);
        MKMessageModel *messageModel = [[MKMessageModel alloc] init];
        messageModel.appType = 3;
        messageModel.year = components.year % 2000;
        messageModel.month = components.month;
        messageModel.day = components.day;
        messageModel.hour = components.hour;
        messageModel.minute = components.minute;
        messageModel.second = components.second;
        messageModel.title = @"张三";
        messageModel.content = @"你好，我是张三";
        [MKDeviceInterface messageNotifyWithsucBlock:messageModel
                                            sucBlock:^(id returnData) {
            if([returnData[@"result"] isEqualToString:@"0"]) {
                [self showAlertWithMsg:@"消息通知成功"];
            } else {
                [self showAlertWithMsg:@"消息通知失败"];
            }
        }
                                         failedBlock:^(NSError *error) {
            NSLog(@"消息通知失败failedBlock");
        }];
    }
    if(row == 13){
        //查询绑定信息
        [MKDeviceInterface queryInfoWithsucBlock:^(id returnData) {
            NSArray *result = returnData[@"result"];
            NSString *bindType = [result[0] integerValue] == 0 ? @"Android" : @"iOS";
            NSString *bindStatus = [result[1] integerValue] == 0 ? @"未绑定" : @"已绑定";
            
            NSString * resultStr = [NSString stringWithFormat:@"平台：%@\n绑定状态：%@", bindType, bindStatus];
            [self showAlertWithMsg:resultStr];
        }
                                     failedBlock:^(NSError *error) {
            NSLog(@"查询绑定信息失败failedBlock");
        }];
    }
}


#pragma mark - method


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
    [self.dataList addObject:@"查询鉴权状态"];
    [self.dataList addObject:@"鉴权"];
    [self.dataList addObject:@"查找设备"];
    [self.dataList addObject:@"解绑手表"];
    [self.dataList addObject:@"获取电量"];
    [self.dataList addObject:@"开始运动"];
    [self.dataList addObject:@"暂停运动"];
    [self.dataList addObject:@"继续运动"];
    [self.dataList addObject:@"结束运动"];
    [self.dataList addObject:@"语言支持"];
    [self.dataList addObject:@"设备信息"];
    [self.dataList addObject:@"时间校准"];
    [self.dataList addObject:@"消息通知"];
    [self.dataList addObject:@"查询绑定信息"];
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

@end
