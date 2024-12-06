//
//  RemoteStatus.m
//  ActsBluetoothOTA
//
//  Created by inidhu on 2019/9/12.
//  Copyright © 2019 Actions. All rights reserved.
//

#import "RemoteStatus.h"

@implementation RemoteStatus

- (id)init
{
    if (self = [super init]) {
        
        self.batteryThreshold = 30;
        self.versionName = nil;
        self.boardName = nil;
        self.hardwareRev = nil;
        self.versionCode = 0;
        self.featureSupport = 0x00;
    }
    
    return self;
}


@end
