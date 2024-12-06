//
//  mk_fitpoloUpdateCenter.h
//  MKFitpolo
//
//  Created by aa on 2019/1/16.
//  Copyright © 2019 MK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

typedef void(^mk_fitpoloUpdateProcessSuccessBlock)(void);
typedef void(^mk_fitpoloUpdateProcessFailedBlock)(NSError *error);
typedef void(^mk_fitpoloUpdateProgressBlock)(CGFloat progress);
typedef void(^mk_fitpoloUpdateBlock)(NSData *obj,NSInteger state);

@class OTAManager;
@interface mk_fitpoloUpdateCenter : NSObject
@property (nonatomic, assign, readonly)BOOL updating;
@property (nonatomic, strong) OTAManager *otaManager;
@property (nonatomic, copy) mk_fitpoloUpdateProgressBlock progressCallBack;
@property (nonatomic, copy) mk_fitpoloUpdateProcessFailedBlock failedBlock;
+ (mk_fitpoloUpdateCenter *)sharedInstance;

+ (void)attempDealloc;

- (void)updateOtaFromPath:(NSString *)path;

- (void)startDailFileSync:(NSArray<NSString *> *)filePaths size:(NSInteger)allFileSize;

@end

NS_ASSUME_NONNULL_END
