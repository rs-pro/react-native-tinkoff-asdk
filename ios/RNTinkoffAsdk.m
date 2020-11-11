
#import "RNTinkoffAsdk.h"

#import <ASDKCore/ASDKCore.h>
#import <ASDKUI/ASDKUI.h>
#import "ASDKCardIOScanner.h"

#if __has_include("RCTConvert.h")
#import "RCTConvert.h"
#else
#import <React/RCTConvert.h>
#endif

#import <objc/runtime.h>

@implementation RNTinkoffAsdk

- (NSMutableArray*)arrayToDictionary:array
{
    NSMutableArray *dict = [[NSMutableArray alloc] init];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [dict addObject:[self objectToDictionary:obj]];
    }];

    return dict;
}

- (NSDictionary *)objectToDictionary:object {

    unsigned int count = 0;

    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    objc_property_t *properties = class_copyPropertyList([object class], &count);

    for (int i = 0; i < count; i++) {

        NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
        id value = [object valueForKey:key];

        if (value == nil) {
            // nothing todo
        }
        else if ([value isKindOfClass:[NSNumber class]]
            || [value isKindOfClass:[NSString class]]
            || [value isKindOfClass:[NSDictionary class]]) {
        // TODO: extend to other types
            [dictionary setObject:value forKey:key];
        }
        else if ([value isKindOfClass:[NSObject class]]) {
            [dictionary setObject:[self objectToDictionary:object] forKey:key];
        }
        else {
            NSLog(@"Invalid type for %@ (%@)", NSStringFromClass([object class]), key);
        }
    }

    free(properties);

    return dictionary;
}
- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

ASDKAcquiringSdk *acquiringSdk;

RCT_EXPORT_METHOD(init:(NSDictionary *)options resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
{
  NSError* error = nil;

  if (![options objectForKey:@"terminalKey"]) {
      reject(@"init_error", @"Не передан terminalKey", error);
  }
  if (![options objectForKey:@"password"]) {
      reject(@"init_error", @"Не передан password", error);
  }
  if (![options objectForKey:@"publicKey"]) {
      reject(@"init_error", @"Не передан publicKey", error);
  }

  NSString *terminalKey = [RCTConvert NSString:options[@"terminalKey"]];
  NSString *password = [RCTConvert NSString:options[@"password"]];
  NSString *publicKey = [RCTConvert NSString:options[@"publicKey"]];

	ASDKStringKeyCreator *stringKeyCreator = [[ASDKStringKeyCreator alloc] initWithPublicKeyString:publicKey];

	acquiringSdk = [ASDKAcquiringSdk acquiringSdkWithTerminalKey:terminalKey
                                 payType:nil
																 password:password
															   publicKeyDataSource:stringKeyCreator];

  bool isTestMode = false;
  bool isDebugLog = false;

  if ([options objectForKey:@"testMode"]) {
    isTestMode = [RCTConvert BOOL:options[@"testMode"]];
  }
  if ([options objectForKey:@"debugLog"]) {
    isDebugLog = [RCTConvert BOOL:options[@"debugLog"]];
  }

  if (isTestMode) {
    NSLog(@"init tinkoff test mode");
    [acquiringSdk setTestDomain:YES];
  } else {
    NSLog(@"init tinkoff prod mode");
    [acquiringSdk setTestDomain:NO];
  }

  if (isDebugLog) {
    [acquiringSdk setDebug:YES];
  } else {
    [acquiringSdk setDebug:NO];
  }

  //[acquiringSdk setLogger:nil];
}

RCT_EXPORT_METHOD(GetCardList:(NSDictionary*) options
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    NSError* error = nil;

    if (acquiringSdk == nil) {
        reject(@"init_not_done", @"Не выполнен init", error);
        return;
    };

    [acquiringSdk getCardListWithCustomerKey:[options objectForKey:@"CustomerKey"]
                                     success:^(ASDKGetCardListResponse *response) { resolve([self arrayToDictionary:[response cards]]); }
                                            failure:^(ASDKAcquringSdkError *error) {
                                                NSLog(@"%@",error);
                                                reject([NSString stringWithFormat:@"%ld", [error code]], [error errorMessage], error);
                                            }
    ];
}

RCT_EXPORT_METHOD(RemoveCard:(NSDictionary*) options
              resolve:(RCTPromiseResolveBlock)resolve
              reject:(RCTPromiseRejectBlock)reject) {
    NSError* error = nil;

    if (acquiringSdk == nil) {
        reject(@"init_not_done", @"Не выполнен init", error);
        return;
    };

    [acquiringSdk removeCardWithCustomerKey:[options objectForKey:@"CustomerKey"]
                                    cardId:[options objectForKey:@"CardId"]
                                    success:^(ASDKRemoveCardResponse *response) { resolve([self objectToDictionary:response]); }
                                   failure:^(ASDKAcquringSdkError *error) { NSLog(@"%@",error);
                                   reject([NSString stringWithFormat:@"%ld", [error code]], [error errorMessage], error); }
    ];
}

RCT_EXPORT_METHOD(AddCard:(NSDictionary*) options
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    NSError* error = nil;

    if (acquiringSdk == nil) {
        reject(@"init_not_done", @"Не выполнен init", error);
        return;
    };
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;

    NSLog(@"%@",acquiringSdk);
    ASDKPaymentFormStarter * form = [ASDKPaymentFormStarter paymentFormStarterWithAcquiringSdk:acquiringSdk];

    form.cardScanner = [ASDKCardIOScanner scanner];
    [form presentAttachFormFromViewController:rootViewController
                                    formTitle:@"Новая карта"
                                   formHeader:@"Сохраните данные карты"
                                  description:@"и оплачивайте, не вводя реквизиты"
                                        email:[options objectForKey:@"Email"]
                                cardCheckType:[options objectForKey:@"CardCheckType"]
                                  customerKey:[options objectForKey:@"CustomerKey"]
                               additionalData:[options objectForKey:@"AdditionalData"]
                                      success:^(ASDKResponseAttachCard *result) { resolve(result); }
                                     cancelled:^{
                                         NSLog(@"cancelled"); reject(@"add_card_cancelled", @"Добавление карты отменено", error);
                                     }
                                        error:^(ASDKAcquringSdkError *error) {
                                            NSLog(@"%@",error);
                                            reject([NSString stringWithFormat:@"%ld", [error code]], [NSString stringWithFormat:@"%@", error], error); }
     ];
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
    NSError* error = nil;

    if (acquiringSdk == nil) {
        reject(@"init_not_done", @"Не выполнен init", error);
        return;
    };

    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;

    NSLog(@"%@",acquiringSdk);
    ASDKPaymentFormStarter * form = [ASDKPaymentFormStarter paymentFormStarterWithAcquiringSdk:acquiringSdk];

    form.cardScanner = [ASDKCardIOScanner scanner];

    NSNumber *amountCents = [options objectForKey:@"Amount"];
    double amountRub = (amountCents.doubleValue / 100);
    NSNumber *amount = @(amountRub);

    NSArray *items = [options objectForKey:@"Items"];

    NSDictionary *receiptData = @{
                                  @"Email": [options objectForKey:@"Email"],
                                  @"Phone": [options objectForKey:@"Phone"],
                                  @"Taxation": [options objectForKey:@"Taxation"],
                                  @"Items": items};
    NSDictionary *additionalPaymentData = @{
                                  @"Email": [options objectForKey:@"Email"],
                                  @"Phone": [options objectForKey:@"Phone"]};

    //NSLog(@"%@",receiptData);
    //NSLog(@"%@",additionalPaymentData);

    [form presentPaymentFormFromViewController:rootViewController
      orderId: [options objectForKey:@"OrderID"]
      amount: amount
      title: [options objectForKey:@"PaymentName"]
      description: [options objectForKey:@"PaymentDesc"]
      cardId: [options objectForKey:@"CardID"]
      email: [options objectForKey:@"Email"]
      customerKey: [options objectForKey:@"CustomerKey"]
      recurrent: [options objectForKey:@"IsRecurrent"]
      makeCharge: [options objectForKey:@"MakeCharge"]
      additionalPaymentData: additionalPaymentData
      receiptData: receiptData
      //receiptData:nil
      //success:^(NSNumber *paymentId) { NSLog(@"%@",paymentId); resolve(paymentId); }
      success: ^(ASDKPaymentInfo *paymentInfo) { NSLog(@"%@",paymentInfo); resolve(paymentInfo); }
      cancelled: ^{ NSLog(@"cancelled"); reject(@"payment_cancelled", @"Платеж отменен", error); }
      error: ^(ASDKAcquringSdkError *error) {
          NSLog(@"%@",error);
          reject([NSString stringWithFormat:@"%ld", [error code]], [error errorMessage], error); }
    ];
}

RCT_EXPORT_METHOD(ApplePay:(NSDictionary*) options
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  NSError* error = nil;

    if (acquiringSdk == nil) {
        reject(@"init_not_done", @"Не выполнен init", error);
        return;
    };

    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;

    ASDKPaymentFormStarter * form = [ASDKPaymentFormStarter paymentFormStarterWithAcquiringSdk:acquiringSdk];

    NSDictionary *shipping = [options objectForKey:@"Shipping"];

		PKContact *shippingContact = [[PKContact alloc] init];
		shippingContact.emailAddress = [options objectForKey:@"Email"];
		shippingContact.phoneNumber = [CNPhoneNumber phoneNumberWithStringValue:[options objectForKey:@"Phone"]];

    NSPersonNameComponents *name = [[NSPersonNameComponents alloc] init];
    name.givenName = [shipping objectForKey:@"givenName"];
    name.familyName = [shipping objectForKey:@"familyName"];
    shippingContact.name = name;

		CNMutablePostalAddress *postalAddress = [[CNMutablePostalAddress alloc] init];
		[postalAddress setStreet:[shipping objectForKey:@"Street"]];
		[postalAddress setCountry:[shipping objectForKey:@"Country"]];
		[postalAddress setCity:[shipping objectForKey:@"City"]];
		[postalAddress setPostalCode:[shipping objectForKey:@"PostalCode"]];
		[postalAddress setISOCountryCode:[shipping objectForKey:@"ISOCountryCode"]];
		shippingContact.postalAddress = [postalAddress copy];

    NSNumber *amountCents = [options objectForKey:@"Amount"];
    double amountRub = (amountCents.doubleValue / 100);
    NSNumber *amount = @(amountRub);

    NSDictionary *receiptData = @{
      @"Email": [options objectForKey:@"Email"],
      @"Phone": [options objectForKey:@"Phone"],
      @"Taxation": [options objectForKey:@"Taxation"],
      @"Items": [options objectForKey:@"Items"]};

    [form payWithApplePayFromViewController:rootViewController
      amount: amount
      orderId: [options objectForKey:@"OrderID"]
      description: [options objectForKey:@"PaymentDesc"]
      customerKey: [options objectForKey:@"CustomerKey"]
      sendEmail: YES
      email: [options objectForKey:@"email"]
      appleMerchantId: [options objectForKey:@"appleMerchantId"]
      shippingMethods:nil
      shippingContact:shippingContact
      shippingEditableFields:PKAddressFieldPostalAddress|PKAddressFieldName|PKAddressFieldEmail|PKAddressFieldPhone //PKAddressFieldNone
      recurrent: NO
      additionalPaymentData: [options objectForKey:@"extraData"]
      receiptData: receiptData
      shopsData:nil
      shopsReceiptsData:nil
      success: ^(ASDKPaymentInfo *paymentInfo) { NSLog(@"%@",paymentInfo); resolve(paymentInfo); }
      cancelled: ^{ reject(@"payment_cancelled", @"Платеж отменен", error); }
      error: ^(ASDKAcquringSdkError *error) { NSLog(@"%@",error); reject([NSString stringWithFormat:@"%ld", [error code]], [error errorMessage], error); }
    ];
}

@end
