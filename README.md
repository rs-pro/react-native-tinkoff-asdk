# react-native-tinkoff-asdk

## Статус проекта: в разработке (пока не работает \ не проверено)

Оплата работает, но могут быть баги

## Getting started

`$ yarn add react-native-tinkoff-asdk`

### Mostly automatic installation

`$ react-native link react-native-tinkoff-asdk`

For IOS, add
```
pod 'ASDKCore', :podspec =>  "https://raw.githubusercontent.com/TinkoffCreditSystems/tinkoff-asdk-ios/master/ASDKCore.podspec"
pod 'ASDKUI', :podspec =>  "https://raw.githubusercontent.com/TinkoffCreditSystems/tinkoff-asdk-ios/master/ASDKUI.podspec"
```
to ios/Profile and run pod install

### Proguard

```
-keep class ru.tinkoff.acquiring.sdk.views.** { *; }
```

### Usage
```javascript
import TinkoffASDK from 'react-native-tinkoff-asdk';

TinkoffASDK.init({
  // Тестовые данные из https://github.com/TinkoffCreditSystems/tinkoff-asdk-android/blob/9c7d1727f2ba5d715f240e0be6e4a0fd8b88a1db/sample/src/main/java/ru/tinkoff/acquiring/sample/SessionParams.java
  terminalKey: "TestSDK",
  password: "12345678",
  publicKey: "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqBiorLS9OrFPezixO5lSsF+HiZPFQWDO\n" +
    "7x8gBJp4m86Wwz7ePNE8ZV4sUAZBqphdqSpXkybM4CJwxdj5R5q9+RHsb1dbMjThTXniwPpJdw4W\n" +
    "KqG5/cLDrPGJY9NnPifBhA/MthASzoB+60+jCwkFmf8xEE9rZdoJUc2p9FL4wxKQPOuxCqL2iWOx\n" +
    "AO8pxJBAxFojioVu422RWaQvoOMuZzhqUEpxA9T62lN8t3jj9QfHXaL4Ht8kRaa2JlaURtPJB5iB\n" +
    "M+4pBDnqObNS5NFcXOxloZX4+M8zXaFh70jqWfiCzjyhaFg3rTPE2ClseOdS7DLwfB2kNP3K0GuP\n" +
    "uLzsMwIDAQAB",
  testMode: true,
  debugLog: true
});

const payment = TinkoffASDK.Pay({
  OrderID: "1",                      // ID заказа в вашей системе
  Amount: 32345,                     // сумма для оплаты (в копейках)
  PaymentName: "НАЗВАНИЕ ПЛАТЕЖА",   // название платежа, видимое пользователю
  PaymentDesc: "ОПИСАНИЕ ПЛАТЕЖА",   // описание платежа, видимое пользователю
  CardID: "CARD-ID",                 // ID карточки
  //Email: "batman@gotham.co",         // E-mail клиента для отправки уведомления об оплате
  //CustomerKey: null,                 // ID клиента для сохранения карты
  // тестовые:
  Email: "testCustomerKey1@gmail.com",
  CustomerKey: "testCustomerKey1@gmail.com",
  IsRecurrent: false,                // флаг определяющий является ли платеж рекуррентным [1]
  UseSafeKeyboard: true,             // флаг использования безопасной клавиатуры [2]
  ExtraData: {},
  GooglePayParams: {
    MerchantName: "test",
    AddressRequired: false,
    PhoneRequired: false,
    Environment: "TEST" // "SANDBOX", "PRODUCTION"
  },
  Taxation: "usn_income",
  Items: [
    {
      Name: "test 1",
      Price: 10000, // В копейках (100 рублей)
      Quantity: 2,
      Amount: 20000, // В копейках (200 рублей)
      Tax: "usn_income",
    },
    {
      Name: "test 2",
      Price: 12345,
      Quantity: 1,
      Amount: 12345,
      Tax: "usn_income",
    }
  ]
})

payment.then((r) => {
  console.log(r)
}).catch((e) => {
  console.error(e)
})

// Оплата через Google Pay:
// Ничего делать не нужно, пользователь может выбрать оплату google pay на экране оплаты

// Оплата через Apple Pay:
// Только отдельным методом, вот так:
const hasApplePay = await TinkoffASDK.isPayWithAppleAvailable()
if (hasApplePay) {
  const payment = TinkoffASDK.ApplePay({
    appleMerchantId: "....",
    Phone: "+74956481000",
    Shipping: {
      Street: "Головинское шоссе, дом 5, корп. 1",
      Country: "Россия",
      City: "Москва",
      PostalCode: "125212",
      ISOCountryCode: "643",
      givenName: "имя",
      familyName: "фамилия"
    }
    // Все то же что в простом Pay
  })
}
```

### Google Pay

Настроить по инструкции:

https://github.com/TinkoffCreditSystems/tinkoff-asdk-android#google-pay

### Apple Pay

https://github.com/TinkoffCreditSystems/tinkoff-asdk-ios#%D0%BF%D1%80%D0%B8%D0%BC%D0%B5%D1%80-%D1%80%D0%B0%D0%B1%D0%BE%D1%82%D1%8B

## License

Код обертки - (c) 2019 glebtv for rocketscience.pro - MIT лицензия

Использует файлы из ASDK Тиньков (конкретно ASDKCardIOScanner) на них действует его лицензия:

https://github.com/TinkoffCreditSystems/tinkoff-asdk-ios/blob/master/LICENSE.rtf
https://github.com/TinkoffCreditSystems/tinkoff-asdk-android/blob/master/LICENSE.TXT
