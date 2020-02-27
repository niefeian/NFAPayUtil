/*注意事项：
 1.沙盒环境测试appStore内购流程的时候，请使用没越狱的设备。
 2.请务必使用真机来测试，一切以真机为准。
 3.项目的Bundle identifier需要与您申请AppID时填写的bundleID一致，不然会无法请求到商品信息。
 4.如果是你自己的设备上已经绑定了自己的AppleID账号请先注销掉,否则你哭爹喊娘都不知道是怎么回事。
 5.订单校验 苹果审核app时，仍然在沙盒环境下测试，所以需要先进行正式环境验证，如果发现是沙盒环境则转到沙盒验证。
 识别沙盒环境订单方法：
 1.根据字段 environment = sandbox。
 2.根据验证接口返回的状态码,如果status=21007，则表示当前为沙盒环境。
 苹果反馈的状态码：
 21000 App Store无法读取你提供的JSON数据
 21002 订单数据不符合格式
 21003 订单无法被验证
 21004 你提供的共享密钥和账户的共享密钥不一致
 21005 订单服务器当前不可用
 21006 订单是有效的，但订阅服务已经过期。当收到这个信息时，解码后的收据信息也包含在返回内容中
 21007 订单信息是测试用（sandbox），但却被发送到产品环境中验证
 21008 订单信息是产品环境中使用，但却被发送到测试环境中验证
 */

#import "STRIAPManager.h"
#import <StoreKit/StoreKit.h>
#import "NSString+YYAdd.h"
#import "NSData+YYAdd.h"

@interface STRIAPManager()<SKPaymentTransactionObserver,SKProductsRequestDelegate>{
    NSString           *_purchID;
    IAPCompletionHandle _handle;
    
    IAPSubscribeHandle _subhandle;
}
@end
@implementation STRIAPManager

#pragma mark - ♻️life cycle

+ (instancetype)shareSIAPManager{
    static STRIAPManager *IAPManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        IAPManager = [[STRIAPManager alloc] init];
    });
    return IAPManager;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        // 购买监听写在程序入口,程序挂起时移除监听,这样如果有未完成的订单将会自动执行并回调 paymentQueue:updatedTransactions:方法
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (void)dealloc{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}



- (void)verifySubscribe:(IAPSubscribeHandle)handle{
    _subhandle = handle;
}

-(void)restoreCompletedTransactions{
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue{
     NSMutableArray *purchasedItemIDs = [[NSMutableArray alloc] init];
        for (SKPaymentTransaction *transaction in queue.transactions){
            NSString *productID = transaction.payment.productIdentifier;
            [purchasedItemIDs addObject:productID];
        }
        
    if(_subhandle){
                  _subhandle(purchasedItemIDs);
              }

}

#pragma mark - 🚪public
- (void)startPurchWithID:(NSString *)purchID completeHandle:(IAPCompletionHandle)handle{
    if (purchID) {
        if ([SKPaymentQueue canMakePayments]) {
            // 开始购买服务
            _purchID = purchID;
            _handle = handle;
            NSSet *nsset = [NSSet setWithArray:@[purchID]];
            SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:nsset];
            request.delegate = self;
            [request start];
        }else{
            [self handleActionWithType:SIAPPurchNotArrow data:nil];
        }
    }
}
#pragma mark - 🔒private
- (void)handleActionWithType:(SIAPPurchType)type data:(NSData *)data{
    switch (type) {
        case SIAPPurchSuccess:
            NSLog(@"购买成功");
             [[NSNotificationCenter defaultCenter] postNotificationName:@"showLondTip" object:@"购买成功"];
            break;
        case SIAPPurchFailed:
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"showLondTip" object:@"购买失败"];
            NSLog(@"购买失败");
            break;
        case SIAPPurchCancle:
             [[NSNotificationCenter defaultCenter] postNotificationName:@"showLondTip" object:@"用户取消购买"];
            NSLog(@"用户取消购买");
            break;
        case SIAPPurchVerFailed:
             [[NSNotificationCenter defaultCenter] postNotificationName:@"showLondTip" object:@"订单校验失败"];
            NSLog(@"订单校验失败");
            break;
        case SIAPPurchVerSuccess:
             [[NSNotificationCenter defaultCenter] postNotificationName:@"showLondTip" object:@"订单校验成功"];
            NSLog(@"订单校验成功");
            break;
        case SIAPPurchNotArrow:
             [[NSNotificationCenter defaultCenter] postNotificationName:@"showLondTip" object:@"不允许程序内付费"];
            NSLog(@"不允许程序内付费");
            break;
        default:
            break;
    }
    if(_handle){
        _handle(type,data);
    }
}
#pragma mark - 🍐delegate
// 交易结束
- (void)completeTransaction:(SKPaymentTransaction *)transaction{
    // Your application should implement these two methods.
    NSString * productIdentifier = transaction.payment.productIdentifier;
    NSString * receipt = [transaction.transactionReceipt base64EncodedString];
    if ([productIdentifier length] > 0) {
        // 向自己的服务器验证购买凭证
    }
    
    if(transaction.originalTransaction){
        printf("如果是自动续费的订单originalTransaction会有内容");
        //如果是自动续费的订单originalTransaction会有内容
    }else{
        //普通购买，以及 第一次购买 自动订阅
        printf("如果是自动续费的订单originalTransaction会有内容");
    }
    
    [self verifyPurchaseWithPaymentTransaction:transaction isTestServer:NO];
}

// 交易失败
- (void)failedTransaction:(SKPaymentTransaction *)transaction{
    if (transaction.error.code != SKErrorPaymentCancelled) {
        [self handleActionWithType:SIAPPurchFailed data:nil];
    }else{
        [self handleActionWithType:SIAPPurchCancle data:nil];
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (NSData *)verifyPurchase{
    //交易验证
    NSURL *recepitURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receipt = [NSData dataWithContentsOfURL:recepitURL];
    if  (receipt == nil){
        return [NSData new];
    }
    return receipt;
}


- (void)verifyPurchaseWithPaymentTransaction:(SKPaymentTransaction *)transaction isTestServer:(BOOL)flag{
    //交易验证
    NSURL *recepitURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receipt = [NSData dataWithContentsOfURL:recepitURL];
    
    if(!receipt){
        // 交易凭证为空验证失败
        [self handleActionWithType:SIAPPurchVerFailed data:nil];
        return;
    }
    // 购买成功将交易凭证发送给服务端进行再次校验
    [self handleActionWithType:SIAPPurchSuccess data:receipt];
   
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

#pragma mark - SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    NSArray *product = response.products;
    if([product count] <= 0){
#if DEBUG
        NSLog(@"--------------没有商品------------------");
#endif
        return;
    }
    
    SKProduct *p = nil;
    for(SKProduct *pro in product){
        if([pro.productIdentifier isEqualToString:_purchID]){
            p = pro;
            break;
        }
    }
    
#if DEBUG
    NSLog(@"productID:%@", response.invalidProductIdentifiers);
    NSLog(@"产品付费数量:%lu",(unsigned long)[product count]);
    NSLog(@"%@",[p description]);
    NSLog(@"%@",[p localizedTitle]);
    NSLog(@"%@",[p localizedDescription]);
    NSLog(@"%@",[p price]);
    NSLog(@"%@",[p productIdentifier]);
    NSLog(@"发送购买请求");
#endif
    
    SKPayment *payment = [SKPayment paymentWithProduct:p];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error{
      [[NSNotificationCenter defaultCenter] postNotificationName:@"showLondTip" object:@"用户取消操作"];
}
//请求失败
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{
#if DEBUG
    NSLog(@"------------------错误-----------------:%@", error);
#endif
}

- (void)requestDidFinish:(SKRequest *)request{
#if DEBUG
    NSLog(@"------------反馈信息结束-----------------");
#endif
}

#pragma mark - SKPaymentTransactionObserver
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions{
    for (SKPaymentTransaction *tran in transactions) {
        switch (tran.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:tran];
                break;
            case SKPaymentTransactionStatePurchasing:
#if DEBUG
                NSLog(@"商品添加进列表");
#endif
                break;
            case SKPaymentTransactionStateRestored:
#if DEBUG
                NSLog(@"已经购买过商品");
#endif
                // 消耗型不支持恢复购买
                [[SKPaymentQueue defaultQueue] finishTransaction:tran];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:tran];
                break;
            default:
                break;
        }
    }
}
@end
