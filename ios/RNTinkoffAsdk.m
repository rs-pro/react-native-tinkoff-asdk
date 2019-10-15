
#import "RNTinkoffAsdk.h"

#import <ASDKCore/ASDKCore.h>
#import <ASDKUI/ASDKUI.h>
#import "ASDKCardIOScanner.h"

@implementation RNTinkoffAsdk

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

ASDKAcquiringSdk *acquiringSdk

RCT_EXPORT_METHOD(init:(NSDictionary *)options resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
{
  if (![options objectForKey:@"terminalKey"]) {
      reject(@"Не передан terminalKey");
  }
  if (![options objectForKey:@"password"]) {
      reject(@"Не передан password");
  }
  if (![options objectForKey:@"publicKey"]) {
      reject(@"Не передан publicKey");
  }

  NSString *terminalKey = [RCTConvert NSString:options[@"terminalKey"]];
  NSString *password = [RCTConvert NSString:options[@"password"]];
  NSString *publicKey = [RCTConvert NSString:options[@"publicKey"]];

	ASDKStringKeyCreator *stringKeyCreator = [[ASDKStringKeyCreator alloc] initWithPublicKeyString:[ASDKTestSettings publicKey]];

	*acquiringSdk = [ASDKAcquiringSdk acquiringSdkWithTerminalKey:terminalKey
																		  password:[ASDKTestSettings password]
															   publicKeyDataSource:stringKeyCreator];

  if (![options objectForKey:@"testMode"]) {
    isTestMode = [RCTConvert BOOL:options[@"testMode"]];
  }
  if (isTestMode) {
    [acquiringSdk setDebug:YES];
    [acquiringSdk setTestDomain:YES];
  }
	[acquiringSdk setLogger:nil];
}

RCT_EXPORT_METHOD(isPayWithAppleAvailable:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject) {
    if ([ASDKPaymentFormStarter isPayWithAppleAvailable]) {
        resolve(@TRUE);
    } else {
        resolve(@FALSE);
    }
}

RCT_EXPORT_METHOD(Pay:(NSDictionary*) options
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  if (acquiringSdk == nil) {
      reject("Не выполнен init");
      return
  }

    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;


    ASDKPaymentFormStarter * form = [ASDKPaymentFormStarter paymentFormStarterWithAcquiringSdk:acquiringSdk];

    form.cardScanner = [ASDKCardIOScanner scanner];

    [form presentPaymentFormFromViewController:rootViewController
      orderId: [options objectForKey:@"OrderID"]
      amount: [options objectForKey:@"Amount"]
      title: [options objectForKey:@"PaymentName"]
      description: [options objectForKey:@"PaymentDesc"]
      cardId: [options objectForKey:@"CardID"]
      email: [options objectForKey:@"email"]
      customerKey: [options objectForKey:@"customerKey"]
      additionalPaymentData: [options objectForKey:@"extraData"]
      receiptData: [options objectForKey:@"Items"]
      success: ^(ASDKPaymentInfo *paymentInfo) { resolve(paymentInfo); }
      cancelled: ^{ reject(NULL); }
      error: ^(ASDKAcquringSdkError *error) { reject([NSString stringWithFormat:@"%ld", [error code]], [error errorMessage], error); }
    ];
}

RCT_EXPORT_METHOD(ApplePay:(NSDictionary*) options
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  if (acquiringSdk == nil) {
      reject("Не выполнен init");
      return
  }

    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;


    ASDKPaymentFormStarter * form = [ASDKPaymentFormStarter paymentFormStarterWithAcquiringSdk:acquiringSdk];

    form.cardScanner = [ASDKCardIOScanner scanner];

    [form presentPaymentFormFromViewController:rootViewController
      orderId: [options objectForKey:@"OrderID"]
      amount: [options objectForKey:@"Amount"]
      title: [options objectForKey:@"PaymentName"]
      description: [options objectForKey:@"PaymentDesc"]
      cardId: [options objectForKey:@"CardID"]
      email: [options objectForKey:@"email"]
      appleMerchantId: [options objectForKey:@"appleMerchantId"]
      customerKey: [options objectForKey:@"customerKey"]
      additionalPaymentData: [options objectForKey:@"extraData"]
      receiptData: [options objectForKey:@"Items"]
      success: ^(ASDKPaymentInfo *paymentInfo) { resolve(paymentInfo); }
      cancelled: ^{ reject(NULL); }
      error: ^(ASDKAcquringSdkError *error) { reject([NSString stringWithFormat:@"%ld", [error code]], [error errorMessage], error); }
    ];
}

@end
