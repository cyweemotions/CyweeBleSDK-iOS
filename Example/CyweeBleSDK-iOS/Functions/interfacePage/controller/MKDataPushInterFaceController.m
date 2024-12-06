//
//  MKDataPushInterFaceController.m
//  CyweeBleSDK-iOS_Example
//
//  Created by rohn on 2024/9/29.
//  Copyright © 2024 Chengang. All rights reserved.
//

#import "MKDataPushInterfaceController.h"

#import "MKConfigUserDataModel.h"
#import "MKSportDataModel.h"
#import <math.h>

@interface MKDataPushInterfaceController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong)UITableView *tableView;

@property (nonatomic, strong)NSMutableArray *dataList;

@end


@implementation MKDataPushInterfaceController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"DataPush";
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MKDataPushInterfaceControllerCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MKDataPushInterfaceControllerCell"];
    }
    cell.textLabel.text = self.dataList[indexPath.row];
    return cell;
}

#pragma mark - interface

- (void)testInterface:(NSInteger)row {
    if ([mk_fitpoloCentralManager sharedInstance].deviceType == mk_fitpoloUnknow) {
        return;
    }
    if (row == 0) {
        //获取当前步数数据
        [self getStepsData: 0];
        return;
    } else if(row == 1) {
        //获取今日所有步数数据
        [self getStepsData: 1];
        return;
    } else if (row == 2) {
        //心率同步
        NSDate *currentDate = [NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:currentDate];
        NSInteger year = [components year]; //年
        NSInteger month = [components month]; //月
        NSInteger day = [components day]; //日
        [MKUserDataInterface syncHeartRateDataWithsucBlock:(int)year
                                                 month:(int)month
                                                   day:(int)day
                                              sucBlock:^(id returnData) {
            if([returnData[@"code"]  isEqual:@"2"]){
                [self showAlertWithMsg:@"无数据"];
            } else {
                NSString *resultString = [returnData[@"result"] componentsJoinedByString:@", "];
                [self showAlertWithMsg:resultString];
            }
        }
                                           failedBlock:^(NSError *error) {
            [self showAlertWithMsg:@"获取失败"];
        }];
        return;
    } else if (row == 3) {
        //血氧同步
        NSDate *currentDate = [NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:currentDate];
        NSInteger year = [components year]; //年
        NSInteger month = [components month]; //月
        NSInteger day = [components day]; //日
        [MKUserDataInterface syncBloodOxygenDataWithsucBlock:(int)year
                                                 month:(int)month
                                                   day:(int)day
                                              sucBlock:^(id returnData) {
            if([returnData[@"code"] isEqual:@"2"]){
                [self showAlertWithMsg:@"无数据"];
                return;
            }
            NSString *resultString = [returnData[@"result"] componentsJoinedByString:@", "];
            [self showAlertWithMsg:resultString];
        }
                                           failedBlock:^(NSError *error) {
            [self showAlertWithMsg:@"获取失败"];
        }];
        return;
    } else if (row == 4){
        //运动同步
        NSDate *currentDate = [NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:currentDate];
        NSInteger fileIndex = 0; //开始文件索引
        NSInteger year = [components year]; //年
        NSInteger month = [components month]; //月
        NSInteger day = [components day]; //日
        [MKUserDataInterface syncSportDataWithsucBlock:(int)fileIndex
                                                  year:(int)year
                                                 month:(int)month
                                                   day:(int)day
                                              sucBlock:^(id returnData) {
            if([returnData[@"code"] isEqual:@"2"]){
                [self showAlertWithMsg:@"无数据"];
                return;
            }
            NSMutableArray<MKSportDataModel *> *dataSource = returnData[@"result"];
            NSMutableString *resultString = [NSMutableString string];
            
            for (NSInteger i = 0; i < [dataSource count]; i++) {
                MKSportDataModel * model = dataSource[i];
                [resultString appendFormat:@"第 %d 项\n", (int)i];
                [resultString appendFormat:@"运动类型：%d \n", (int)model.sportType];
                [resultString appendFormat:@"运动时间(s)：%d \n", (int)model.second];
                [resultString appendFormat:@"开始时间：%ld \n", (long)model.start];
                [resultString appendFormat:@"结束时间：%ld \n", (long)model.date];
                [resultString appendFormat:@"步数：%d \n", (int)model.total_steps];
                [resultString appendFormat:@"距离（米）：%.2f \n", (float)model.total_distance];
                [resultString appendFormat:@"卡路里(千卡)：%.2f \n", (float)model.total_calories];
                [resultString appendFormat:@"平均步频(步/分)：%.2f \n", (float)model.avg_step_freq];
                [resultString appendFormat:@"最大步频(步/分)：%.2f \n", (float)model.max_step_freq];
                [resultString appendFormat:@"平均步长：%.2f \n", (float)model.avg_step_len];
                [resultString appendFormat:@"平均速度：：%d'%d\" \n", (int)((int)model.avg_pace/60), (int)model.avg_pace % 60];
                [resultString appendFormat:@"最大速度：：%d'%d\" \n", (int)((int)model.max_pace/60), (int)model.max_pace % 60];
                [resultString appendFormat:@"平均心率：%.2f \n", (float)model.avg_heart];
                [resultString appendFormat:@"最大心率：%d \n", (int)model.max_heart];
                [resultString appendFormat:@"最小心率：%d \n", (int)model.min_heart];
                [resultString appendFormat:@"心率区间-热身：%d \n", (int)model.hr_zone1];
                [resultString appendFormat:@"心率区间-燃脂：%d \n", (int)model.hr_zone2];
                [resultString appendFormat:@"心率区间-有氧运动：%d \n", (int)model.hr_zone3];
                [resultString appendFormat:@"心率区间-无氧运动：%d \n", (int)model.hr_zone4];
                [resultString appendFormat:@"心率区间-极限：%d \n", (int)model.hr_zone5];
                [resultString appendFormat:@"最大摄氧量：%.2f \n", (float)model.vo2max];
                [resultString appendFormat:@"训练时间：%d \n", (int)model.training_time];
                NSString *stepFreqsStr = [model.step_freqs componentsJoinedByString:@", "];
                [resultString appendFormat:@"步频数组：[%@] \n", stepFreqsStr];
                NSString *speedsStr = [model.speeds componentsJoinedByString:@", "];
                [resultString appendFormat:@"速度数组：[%@] \n", speedsStr];
                NSString *hrValuesStr = [model.hr_values componentsJoinedByString:@", "];
                [resultString appendFormat:@"心率数组：[%@] \n", hrValuesStr];
                NSString *jumpfreqsStr = [model.jumpfreqs componentsJoinedByString:@", "];
                [resultString appendFormat:@"跳频数组：[%@] \n", jumpfreqsStr];
                [resultString appendFormat:@"跳频：%d \n", (int)model.jumpfreq];
                [resultString appendFormat:@"跳次：%d \n", (int)model.jumpCount];
                [resultString appendFormat:@"游泳-划水次数：%d \n", (int)model.strokeCount];
                [resultString appendFormat:@"游泳-趟次：%d \n", (int)model.strokeLaps];
                [resultString appendFormat:@"游泳-划频：%d \n", (int)model.strokeFreq];
                [resultString appendFormat:@"游泳-平均划频：%d \n", (int)model.strokeAvgFreq];
                [resultString appendFormat:@"游泳-最佳Swolf：%d \n", (int)model.strokeBestSwolf];
                [resultString appendFormat:@"游泳-泳姿：%d \n", (int)model.strokeType];
                NSString *swimfreqsStr = [model.swimfreqs componentsJoinedByString:@", "];
                [resultString appendFormat:@"游泳频率：[%@] \n", swimfreqsStr];
                NSString *bikeSpeedStr = [model.bikeSpeed componentsJoinedByString:@", "];
                [resultString appendFormat:@"骑行速度：[%@] \n\n\n", bikeSpeedStr];
                
            }
            [self showAlertWithMsg:resultString];
            
        }
                                           failedBlock:^(NSError *error) {
            [self showAlertWithMsg:error.userInfo[@"errorInfo"]];
        }];
        return;
    } else if (row == 5) {
        //天气同步
        NSString * weatherData = @"4:深圳:20241022,30222,30571,802|20241023,30184,30468,500|20241024,30191,30503,500|20241025,30235,30537,500|";
        [MKUserDataInterface syncWeatherDataWithsucBlock:(NSString*)weatherData
                                                sucBlock:^(id returnData){
            if([returnData[@"code"] isEqual:@"2"]){
                [self showAlertWithMsg:@"无数据"];
                return;
            }
            if([returnData[@"result"] isEqualToString:@"0"]) {
                [self showAlertWithMsg:@"天气同步成功"];
            } else {
                [self showAlertWithMsg:@"天气同步失败"];
            }
        }
                                             failedBlock:^(NSError *error){
            
        }];
        return;
    } else if(row == 6) {
        //睡眠同步
        NSDate *currentDate = [NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:currentDate];
        NSInteger year = [components year]; //年
        NSInteger month = [components month]; //月
        NSInteger day = [components day]; //日
        [MKUserDataInterface syncSleepDataWithsucBlock:(int)year
                                                 month:(int)month
                                                   day:(int)day
                                              sucBlock:^(id returnData) {
            NSString *code = returnData[@"code"];
            if ([code  isEqual: @"2"]) {
                [self showAlertWithMsg:@"无数据"];
                return;
            }
            NSDictionary *sleepData = returnData[@"result"];
            NSMutableArray<NSDictionary *> *dataSource = sleepData[@"sleepData"];
            NSMutableString *resultString = [NSMutableString string];
            
            NSString* sleepRating = sleepData[@"sleepRating"];
            NSString* deepSleepContinuity = sleepData[@"deepSleepContinuity"];
            NSString* respiratoryQuality = sleepData[@"respiratoryQuality"];
            [resultString appendFormat:@"睡眠评分:%@ \n", sleepRating];
            [resultString appendFormat:@"深睡连续性:%@ \n", deepSleepContinuity];
            [resultString appendFormat:@"睡眠呼吸质量:%@ \n", respiratoryQuality];
            for (NSInteger i = 0; i < [dataSource count]; i++) {
                NSDictionary * model = dataSource[i];
                [resultString appendFormat:@"第 %d 项\n", (int)i+1];
                //睡眠类型：夜间睡眠、小睡
                NSString *sleepType = [NSString string];
                NSString *slice = [NSString string];
                if ([model[@"type"]  isEqual: @"0"]){
                    sleepType = @"夜间睡眠";
                    if (![model[@"slice"]  isEqual: @"0"]) {
                        slice = model[@"slice"];
                        [resultString appendFormat:@"第 %@ 段夜间睡眠， ", slice];
                    }
                } else {
                    sleepType = @"小睡";
                    slice = model[@"slice"];
                    [resultString appendFormat:@"第 %@ 段小睡， ", slice];
                }
                //状态
                NSString *state = [NSString string];
                if ([model[@"state"]  isEqual: @"0"]){
                    state = @"入睡";
                } else if ([model[@"state"]  isEqual: @"1"]) {
                    state = @"浅睡";
                } else if ([model[@"state"]  isEqual: @"2"]) {
                    state = @"深睡";
                } else if ([model[@"state"]  isEqual: @"3"]) {
                    state = @"清醒";
                } else if ([model[@"state"]  isEqual: @"12"]) {
                    state = @"REM";
                } else { // 4或14  4-夜间睡眠醒来  14-小睡醒来
                    state = @"醒来";
                }
                [resultString appendFormat:@"类型：%@， ", sleepType];
                [resultString appendFormat:@"状态：%@， ", state];
                [resultString appendFormat:@"时间：%@ \n", model[@"datetime"]];
                
            }
            [self showAlertWithMsg:resultString];
        }
                                           failedBlock:^(NSError *error) {
            [self showAlertWithMsg:@"获取失败"];
        }];
        return;
    } else if(row == 7) {
        //PAI同步
        NSDate *currentDate = [NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:currentDate];
        NSInteger year = [components year]; //年
        NSInteger month = [components month]; //月
        NSInteger day = [components day]; //日
        [MKUserDataInterface syncPaiDataWithsucBlock:(int)year
                                                 month:(int)month
                                                   day:(int)day
                                              sucBlock:^(id returnData) {
            NSString *code = returnData[@"code"];
            if ([code  isEqual: @"2"]) {
                [self showAlertWithMsg:@"无数据"];
                return;
            }
            NSMutableArray<NSDictionary *> *dataSource = returnData[@"result"];
            NSMutableString *resultString = [NSMutableString string];
            
            for (NSInteger i = 0; i < [dataSource count]; i++) {
                NSDictionary * model = dataSource[i];
                [resultString appendFormat:@"第 %d 项\n", (int)i+1];
                [resultString appendFormat:@"id：%@ \n", model[@"id"]];
                [resultString appendFormat:@"时间：%@-%@-%@ \n", model[@"year"], model[@"month"], model[@"day"]];
                [resultString appendFormat:@"pai值：%@ \n", model[@"pai"]];
                [resultString appendFormat:@"总数：%@ \n", model[@"totals"]];
                [resultString appendFormat:@"最低强度：%@ \n", model[@"low"]];
                [resultString appendFormat:@"最低强度持续时间（min）：%@ \n", model[@"lowMins"]];
                [resultString appendFormat:@"中强度：%@ \n", model[@"medium"]];
                [resultString appendFormat:@"中强度持续时间（min）：%@ \n", model[@"mediumMins"]];
                [resultString appendFormat:@"高强度：%@ \n", model[@"high"]];
                [resultString appendFormat:@"最高强度持续时间（min）：%@ \n", model[@"highMins"]];
                [resultString appendFormat:@"------------------------\n"];
                
            }
            [self showAlertWithMsg:resultString];
        }
                                           failedBlock:^(NSError *error) {
            [self showAlertWithMsg:@"获取失败"];
        }];
        return;
    } else if (row == 8) {
        //压力同步
        NSDate *currentDate = [NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:currentDate];
        NSInteger year = [components year]; //年
        NSInteger month = [components month]; //月
        NSInteger day = [components day]; //日
        [MKUserDataInterface syncPressureDataWithsucBlock:(int)year
                                                    month:(int)month
                                                      day:(int)day
                                                 sucBlock:^(id returnData) {
            NSString *code = returnData[@"code"];
            if ([code  isEqual: @"2"]) {
                [self showAlertWithMsg:@"无数据"];
                return;
            }
            NSMutableArray<NSDictionary *> *dataSource = returnData[@"result"];
            NSMutableString *resultString = [NSMutableString string];
            
            for (NSInteger i = 0; i < [dataSource count]; i++) {
                NSDictionary * model = dataSource[i];
                [resultString appendFormat:@"第 %d 项\n", (int)i+1];
                [resultString appendFormat:@"id：%@ \n", model[@"id"]];
                [resultString appendFormat:@"时间：%@-%@-%@ \n", model[@"year"], model[@"month"], model[@"day"]];
                [resultString appendFormat:@"放松：%@ \n", model[@"relax"]];
                [resultString appendFormat:@"正常：%@ \n", model[@"normal"]];
                [resultString appendFormat:@"紧张：%@ \n", model[@"strain"]];
                [resultString appendFormat:@"焦虑：%@ \n", model[@"anxiety"]];
                [resultString appendFormat:@"最高：%@ \n", model[@"highest"]];
                [resultString appendFormat:@"最低：%@ \n", model[@"minimum"]];
                [resultString appendFormat:@"最近：%@ \n", model[@"lately"]];
                [resultString appendFormat:@"------------------------\n"];
                
            }
            [self showAlertWithMsg:resultString];
        }
                                              failedBlock:^(NSError *error) {
            [self showAlertWithMsg:@"获取失败"];
        }];
        return;
    }
}

#pragma mark - method

//步数同步
- (void)getStepsData:(NSInteger) mType{
        NSDate *currentDate = [NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:currentDate];
        NSInteger year = [components year]; //年
        NSInteger month = [components month]; //月
        NSInteger day = [components day]; //日
        NSInteger type = mType; //类型 record—— 1  current—— 0
        //步数同步
        [MKUserDataInterface syncStepsDataWithsucBlock:(int)year
                                                 month:(int)month
                                                   day:(int)day
                                                  type:(int)type
                                              sucBlock:^(id returnData) {
            if (mType == 0) {
                NSString *resultString = [returnData[@"result"] description];
                [self showAlertWithMsg:resultString];
            } else {
                if([returnData[@"code"]  isEqual:@"2"]){
                    [self showAlertWithMsg:@"无数据"];
                } else {
                    NSString *resultString = [returnData[@"result"] componentsJoinedByString:@", "];
                    [self showAlertWithMsg:resultString];
                }
            }
        }
                                           failedBlock:^(NSError *error) {
            [self showAlertWithMsg:@"获取失败"];
        }];
}
- (void)configUserData {
    MKConfigUserDataModel *dataModel = [[MKConfigUserDataModel alloc] init];
    dataModel.weight = 75;
    dataModel.height = 175;
    dataModel.gender = mk_fitpoloGenderMale;
    dataModel.userAge = 30;
    [MKUserDataInterface configUserData:dataModel sucBlock:^(id returnData) {
        [self showAlertWithMsg:@"Success"];
        NSLog(@"%@",returnData);
    } failedBlock:^(NSError *error) {
        [self showAlertWithMsg:error.userInfo[@"errorInfo"]];
    }];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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
    [self.dataList addObject:@"步数同步-当前"];
    [self.dataList addObject:@"步数同步-记录"];
    [self.dataList addObject:@"心率同步"];
    [self.dataList addObject:@"血氧同步"];
    [self.dataList addObject:@"运动同步"];
    [self.dataList addObject:@"天气同步"];
    [self.dataList addObject:@"睡眠同步"];
    [self.dataList addObject:@"PAI同步"];
    [self.dataList addObject:@"压力同步"];
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
