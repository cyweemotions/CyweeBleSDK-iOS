//
//  RemoteStatus.h
//  ActsBluetoothOTA
//
//  Created by inidhu on 2019/9/12.
//  Copyright © 2019 Actions. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RemoteStatus : NSObject

@property (nonatomic, strong, nullable) NSString *versionName;
@property (nonatomic, strong, nullable) NSString *boardName;
@property (nonatomic, strong, nullable) NSString *hardwareRev;
@property (nonatomic, readwrite) NSInteger batteryThreshold;
@property (nonatomic, readwrite) NSInteger versionCode;
@property (nonatomic, readwrite) NSInteger featureSupport;

@end

NS_ASSUME_NONNULL_END
