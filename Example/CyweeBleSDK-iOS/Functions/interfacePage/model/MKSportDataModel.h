//
//  MKSportDataModel.h
//  CyweeBleSDK-iOS_Example
//
//  Created by rohn on 2024/10/17.
//  Copyright © 2024 Chengang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKSportDataModel : NSObject<MKSportDataProtocol>

@property (nonatomic, assign)long date;//运动结束时间
@property (nonatomic, assign)long start;//运动开始时间
@property (nonatomic, assign)NSInteger total_steps;//步数
@property (nonatomic, assign)NSInteger total_distance;//距离（米）
@property (nonatomic, assign)float total_calories;//卡路里
@property (nonatomic, assign)float avg_step_freq;//平均步频
@property (nonatomic, assign)float avg_step_len;//平均步长
@property (nonatomic, assign)float avg_pace; //平均速度
@property (nonatomic, assign)float max_step_freq; //最大步频
@property (nonatomic, assign)float max_pace; //最大速度
@property (nonatomic, assign)float avg_heart;//平均心率
@property (nonatomic, assign)NSInteger hr_zone1;//心率区间-热身
@property (nonatomic, assign)NSInteger hr_zone2;//心率区间-燃脂
@property (nonatomic, assign)NSInteger hr_zone3;//心率区间-有氧运动
@property (nonatomic, assign)NSInteger hr_zone4;//心率区间-无氧运动
@property (nonatomic, assign)NSInteger hr_zone5;//心率区间-极限
@property (nonatomic, assign)NSInteger max_heart;//最大心率
@property (nonatomic, assign)NSInteger min_heart;//最小心率
@property (nonatomic, assign)float vo2max; //最大摄氧量
@property (nonatomic, assign)NSInteger training_time; //训练时间
@property (nonatomic, assign)NSInteger sportType; //运动类型
@property (nonatomic, assign)NSInteger second;//运动时间(s)
@property (nonatomic, strong)NSMutableArray *step_freqs;//步频数组
@property (nonatomic, strong)NSMutableArray *speeds ; //速度数组
@property (nonatomic, strong)NSMutableArray *hr_values;//心率数组
@property (nonatomic, strong)NSMutableArray<NSString*> *gpsData;//GPS
@property (nonatomic, strong)NSMutableArray *jumpfreqs;//跳频数组
@property (nonatomic, assign)NSInteger jumpfreq;//跳频
@property (nonatomic, assign)NSInteger jumpCount;//跳次
@property (nonatomic, assign)NSInteger strokeCount; //游泳-划水次数
@property (nonatomic, assign)NSInteger strokeLaps; //游泳-趟次
@property (nonatomic, assign)NSInteger strokeFreq; //游泳-划频
@property (nonatomic, assign)NSInteger strokeAvgFreq;//游泳-平均划频
@property (nonatomic, assign)NSInteger strokeAvgSwolf;//游泳-平均Swolf
@property (nonatomic, assign)NSInteger strokeMaxFreq;//游泳-最大划频
@property (nonatomic, assign)NSInteger strokeBestSwolf;//游泳-最佳Swolf
@property (nonatomic, assign)NSInteger strokeType;//游泳-泳姿
@property (nonatomic, strong)NSMutableArray *swimfreqs; //游泳频率
@property (nonatomic, strong)NSMutableArray *bikeSpeed; //骑行速度
@property (nonatomic, assign)NSString *RawData; //原始数据
@property (nonatomic, assign)NSString *extentsion; //扩展字段
@end

NS_ASSUME_NONNULL_END
