

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    SIAPPurchSuccess = 0,       // 购买成功
    SIAPPurchFailed = 1,        // 购买失败
    SIAPPurchCancle = 2,        // 取消购买
    SIAPPurchVerFailed = 3,     // 订单校验失败
    SIAPPurchVerSuccess = 4,    // 订单校验成功
    SIAPPurchNotArrow = 5,      // 不允许内购
}SIAPPurchType;

typedef void (^IAPCompletionHandle)(SIAPPurchType type,NSData *data);

typedef void (^IAPSubscribeHandle)(NSMutableArray *data);

@interface STRIAPManager : NSObject
+ (instancetype)shareSIAPManager;
//开始内购
- (void)startPurchWithID:(NSString *)purchID completeHandle:(IAPCompletionHandle)handle;

- (void)restoreCompletedTransactions;

- (NSData *)verifyPurchase;


- (void)verifySubscribe:(IAPSubscribeHandle)handle;


-(void)finishTransactionLast;

-(void)addTransactionObserver;

-(void)removeTransactionObserver;

@end

NS_ASSUME_NONNULL_END
