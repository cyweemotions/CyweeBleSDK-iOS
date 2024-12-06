//
//  MKSportDataModel.m
//  CyweeBleSDK-iOS
//
//  Created by rohn on 2024/10/16.
//

#import "MKSportDataModel.h"

@implementation MKSportDataModel

- (instancetype)init {
    self = [super init];
    if (self) {
        // 设置默认值
        _date = 0;
        _start = 0;
        _total_steps = 0;
        _total_distance = 0;
        _total_calories = 0;
        _avg_step_freq = 0;
        _avg_step_len = 0;
        _avg_pace = 0;
        _max_step_freq = 0;
        _max_pace = 0;
        _avg_heart = 0;
        _hr_zone1 = 0;
        _hr_zone2 = 0;
        _hr_zone3 = 0;
        _hr_zone4 = 0;
        _hr_zone5 = 0;
        _max_heart = 0;
        _min_heart = 0;
        _vo2max = 0;
        _training_time = 0;
        _sportType = 0;
        _second = 0;
        _jumpfreq = 0;
        _jumpCount = 0;
        _strokeCount = 0;
        _strokeLaps = 0;
        _strokeFreq = 0;
        _strokeAvgFreq = 0;
        _strokeAvgSwolf = 0;
        _strokeMaxFreq = 0;
        _strokeBestSwolf = 0;
        _strokeType = 0;
        _step_freqs = [[NSMutableArray alloc] init];
        _speeds = [[NSMutableArray alloc] init];
        _hr_values = [[NSMutableArray alloc] init];
        _gpsData = [[NSMutableArray alloc] init];
        _jumpfreqs = [[NSMutableArray alloc] init];
        _swimfreqs = [[NSMutableArray alloc] init];
        _bikeSpeed = [[NSMutableArray alloc] init];
        _RawData = @"";
        _extentsion = @"";
    }
    return self;
}


+ (MKSportDataModel *)StringTurnModel:(NSString*)content
                                 type:(NSInteger)type
                         sportContent:(NSArray*)sportContent
                              rawData:(NSString*)rawData{
    MKSportDataModel* model = [[MKSportDataModel alloc] init];
    NSNumber *mType = [NSNumber numberWithInteger:type];
    NSArray<NSNumber *> *skipType = @[@(9), @(12), @(13)];
    
    NSRange range = [content rangeOfString:@","];
    if (range.location != NSNotFound) {
        NSArray *dataArray = [content componentsSeparatedByString:@","];
        model.start = [dataArray[0] longLongValue];
        model.date = [dataArray[1] longLongValue];
        model.sportType = [dataArray[2] integerValue];
        model.total_steps = [dataArray[3] integerValue];
        model.total_distance = [dataArray[4] integerValue];
        model.total_calories = [dataArray[5] floatValue];
        model.avg_step_freq = [dataArray[7] floatValue];
        model.max_step_freq = [dataArray[8] floatValue];
        model.avg_step_len = [dataArray[10] floatValue];
        model.avg_pace = [dataArray[12] floatValue];
        model.max_pace = [dataArray[13] floatValue];
        model.hr_zone1 = [dataArray[15] integerValue];
        model.hr_zone2 = [dataArray[16] integerValue];
        model.hr_zone3 = [dataArray[17] integerValue];
        model.hr_zone4 = [dataArray[18] integerValue];
        model.hr_zone5 = [dataArray[19] integerValue];
        model.avg_heart = [dataArray[20] floatValue];
        model.max_heart = [dataArray[21] integerValue];
        model.min_heart = [dataArray[22] integerValue];
        model.vo2max = [dataArray[23] floatValue];
        model.training_time = [dataArray[24] integerValue];
        model.second = model.training_time*60;
        if ([skipType containsObject:mType]) {
            model.jumpCount = [dataArray[38] integerValue];
            model.jumpfreq = [dataArray[39] integerValue];
        } else if ([mType isEqualToNumber:@(6)]) {
            model.strokeCount = [dataArray[25] integerValue];
            model.strokeLaps = [dataArray[26] integerValue];
            model.strokeFreq = [dataArray[27] integerValue];
            model.strokeAvgFreq = [dataArray[28] integerValue];
            model.strokeAvgSwolf = [dataArray[29] integerValue];
            model.strokeMaxFreq = [dataArray[30] integerValue];
            model.strokeBestSwolf = [dataArray[31] integerValue];
            model.strokeType = [dataArray[32] integerValue];
        }
    }
    if ([sportContent count] != 0) {
        for (NSInteger i = 0; i < [sportContent count]; i++) {
            NSString *sportContentItemStr = sportContent[i];
            NSArray<NSString *>  *values = [sportContentItemStr componentsSeparatedByString:@","];
//            NSLog(@"sportContentItemStr== %@", values[1].length == 0 ? @"yes" : @"no");
            if(values[1].length == 0) {
                [model.step_freqs addObject:@(0)];
            } else {
                [model.step_freqs addObject: values[1]];
            }
            if(values[2].length == 0) {
                [model.speeds addObject:@(0)];
            } else {
                [model.speeds addObject: values[2]];
            }
            if(values[3].length == 0) {
                [model.hr_values addObject:@(0)];
            } else {
                [model.hr_values addObject: values[3]];
            }
            if ([skipType containsObject:mType]) {
                if(values[6].length == 0) {
                    [model.jumpfreqs addObject:@(0)];
                } else {
                    [model.jumpfreqs addObject: values[6]];
                }
            } else if ([mType isEqualToNumber:@(6)]) {
                if(values[4].length == 0) {
                    [model.swimfreqs addObject:@(0)];
                } else {
                    [model.swimfreqs addObject: values[4]];
                }
            } else if ([mType isEqualToNumber:@(5)]) {
                if(values[5].length != 0) {
                    [model.bikeSpeed addObject: values[5]];
                }
            }
        }
        if(model.sportType == 5){
            NSLog(@"运动内容不是空");
        }
    }
    model.RawData = rawData;
    return model;
}

@end
