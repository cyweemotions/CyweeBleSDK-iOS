//
//  OTAManager.h
//  ActsBluetoothOTA
//
//  Created by inidhu on 2019/5/20.
//  Copyright © 2019 Actions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RemoteStatus.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum{
    STATE_UNKNOWN        = 0,
    STATE_IDLE          = 1,
    STATE_PREPARING     = 2,
    STATE_PREPARED      = 3,
    STATE_TRANSFERRING  = 4,
    STATE_TRANSFERRED   = 5,
} OTAStatus;


@protocol OTAManagerDelegate <NSObject>

@optional

- (void)sendData:(NSData *) data;
- (void)sendData:(NSData *)data index:(int) i;
- (void)audioDataReceive:(NSData *) data;
- (void)receiveAudioPSN:(NSInteger) psn data:(NSData *) data;
- (void)receiveSpeed:(NSInteger) speed;
- (void)receiveRemoteStatus:(RemoteStatus *) status;
- (void)onStatus:(OTAStatus) state;
- (void)onError:(NSInteger) errCode;

@end

@interface OTAManager : NSObject
@property (nonatomic,assign) NSInteger fileSize;
@property (weak, nonatomic) id<OTAManagerDelegate> delegate;
@property (nonatomic,assign) OTAStatus curState;
- (BOOL)setOTAFile:(NSString *) path;
- (NSString *)getOTAVersion;
- (void)prepare;
- (void)upgrade;
- (void)confirmUpdateAndReboot;

- (BOOL)receiveData:(NSData *) data;


@end

NS_ASSUME_NONNULL_END
