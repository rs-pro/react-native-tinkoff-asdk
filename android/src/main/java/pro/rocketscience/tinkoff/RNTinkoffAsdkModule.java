package pro.rocketscience.tinkoff;

import java.util.Map;
import java.util.HashMap;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;

import com.facebook.react.bridge.Arguments;

import com.facebook.react.bridge.Promise;

import com.google.android.gms.wallet.WalletConstants;
import com.google.android.gms.wallet.fragment.WalletFragmentStyle;

import ru.tinkoff.acquiring.sdk.Money;
import ru.tinkoff.acquiring.sdk.Receipt;
import ru.tinkoff.acquiring.sdk.PayFormActivity;
import ru.tinkoff.acquiring.sdk.PayFormStarter;
//import ru.tinkoff.acquiring.sdk.OnPaymentListener;
import ru.tinkoff.acquiring.sdk.GooglePayParams;
import ru.tinkoff.acquiring.sdk.Item;
import ru.tinkoff.acquiring.sdk.Tax;
import ru.tinkoff.acquiring.sdk.Taxation;
import ru.tinkoff.acquiring.sdk.card.io.CameraCardIOScanner;
import ru.tinkoff.acquiring.sdk.Journal;

import android.util.Log;

public class RNTinkoffAsdkModule extends ReactContextBaseJavaModule implements ActivityEventListener {
  private final ReactApplicationContext reactContext;
  private Promise paymentPromise;
  private static final int REQUEST_CODE_PAY = 1;
  private boolean isTestMode = false;
  private PayFormStarter payFormStarter;

  public RNTinkoffAsdkModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
    this.reactContext.addActivityEventListener(this);
  }

  @Override
  public String getName() {
    return "RNTinkoffAsdk";
  }

  @Override
  public void onNewIntent(Intent intent) {}

  @Override
  public void onActivityResult(final Activity activity, int requestCode, int resultCode, Intent data) {
    Log.d("Tinkoff", "Tinkoff payment complete");
    WritableMap resp = Arguments.createMap();
    resp.putInt("code", resultCode);

    if (data == null) {
      rejectPromise("payment cancelled");
      return;
    }

    Bundle bundle = data.getExtras();
    if (bundle != null) {
      resp.putString("payment_id", bundle.get("payment_id") + "");
      resp.putString("payment_card_id", bundle.get("payment_card_id") + "");
      for (String key : bundle.keySet()) {
        Log.e("Tinkoff", key + " : " + (bundle.get(key) != null ? bundle.get(key) : "NULL"));
      }
    } else {
      rejectPromise("no payment data");
      return;
    }

    if (requestCode == REQUEST_CODE_PAY) {
      if (resultCode == 500) {
        rejectPromise("Ошибка");
      } else {
        resolvePromise(resp);
      }
    }
  }

  private void resolvePromise(int result) {
    if (paymentPromise != null) {
      paymentPromise.resolve(result);
      paymentPromise = null;
    }
  }

  private void resolvePromise(WritableMap result) {

    if (paymentPromise != null) {
      paymentPromise.resolve(result);
      paymentPromise = null;
    }
  }

  private void rejectPromise(String reason) {
    if (paymentPromise != null) {
      paymentPromise.reject(reason);
      paymentPromise = null;
    }
  }

  private void rejectPromise(Exception reason) {
    if (paymentPromise != null) {
      paymentPromise.reject(reason);
      paymentPromise = null;
    }
  }

  @ReactMethod
  public void init(ReadableMap options, final Promise promise) {
    rejectPromise("Запущен новый процесс оплаты");
    paymentPromise = promise;

    if (!options.hasKey("terminalKey")) {
      rejectPromise("Не передан terminalKey");
      return;
    }
    if (!options.hasKey("password")) {
      rejectPromise("Не передан password");
      return;
    }
    if (!options.hasKey("publicKey")) {
      rejectPromise("Не передан publicKey");
      return;
    }

    payFormStarter = PayFormActivity
        .init(
          options.getString("terminalKey"),
          options.getString("password"),
          options.getString("publicKey")
        );

    if (options.hasKey("testMode")) {
      isTestMode = options.getBoolean("testMode");
    }
    if (isTestMode) {
      Journal.setDebug(true);
      Journal.setDeveloperMode(true);
    } else {
      Journal.setDebug(false);
      Journal.setDeveloperMode(false);
    }
    resolvePromise(0);
  }

  @ReactMethod
  public void isPayWithAppleAvailable(Promise promise) {
    promise.resolve(false);
  }

  @ReactMethod
  public void Pay(
    ReadableMap options,
    final Promise promise
  ) {
    rejectPromise("Запущен новый процесс оплаты");
    paymentPromise = promise;

    Log.d("Notification", "Tinkoff payment start");

    if (payFormStarter == null) {
      rejectPromise("Не выполнен init");
      return;
    }

    boolean isRecurrent, useSafeKeyboard;
    isRecurrent = options.hasKey("IsRecurrent") ? options.getBoolean("IsRecurrent") : false;
    useSafeKeyboard = options.hasKey("UseSafeKeyboard") ? options.getBoolean("UseSafeKeyboard") : true;

    boolean googlePayEnabled = false;
    int googlePayEnvironment = 0;
    GooglePayParams googlePayParams;

    if (options.hasKey("GooglePayParams")) {
      googlePayEnabled = true;

      ReadableMap params = options.getMap("GooglePayParams");

      switch (params.getString("Environment")) {
        case "PRODUCTION":
          googlePayEnvironment = WalletConstants.ENVIRONMENT_PRODUCTION;
          break;
        case "TEST":
          googlePayEnvironment = WalletConstants.ENVIRONMENT_TEST;
          break;
        case "SANDBOX":
          googlePayEnvironment = WalletConstants.ENVIRONMENT_SANDBOX;
          break;
        default:
          rejectPromise("Incorrect google pay environment");
          return;
      }

      googlePayParams = new GooglePayParams.Builder()
        .setMerchantName(params.getString("MerchantName"))
        .setAddressRequired(params.getBoolean("AddressRequired"))
        .setPhoneRequired(params.getBoolean("PhoneRequired"))
        .setEnvironment(googlePayEnvironment)
        //.setTheme(WalletConstants.THEME_DARK)
        .setBuyButtonAppearance(WalletFragmentStyle.BuyButtonAppearance.ANDROID_PAY_LIGHT)
        .build();
    } else {
      googlePayParams = null;
    }

    Activity currentActivity = getCurrentActivity();

    HashMap<String, String> extraData = new HashMap<>();
    if (options.hasKey("ExtraData")) {
      ReadableMap edRn = options.getMap("ExtraData");
      com.facebook.react.bridge.ReadableMapKeySetIterator iterator = edRn.keySetIterator();
      if (iterator.hasNextKey()) {
        while (iterator.hasNextKey()) {
            String key = iterator.nextKey();
            extraData.put(key, edRn.getString(key));
        }
      }
    }

    try {
      payFormStarter
        .prepare(
          options.getString("OrderID"),
          Money.ofCoins(options.getInt("Amount")),
          options.getString("PaymentName"),
          options.getString("PaymentDesc"),
          options.hasKey("CardID") ? options.getString("CardID") : null,
          options.getString("Email"),

          isRecurrent,
          useSafeKeyboard
        )
        .setData(extraData)
        .setCameraCardScanner(new CameraCardIOScanner())
        .setReceipt(createReceipt(options.getArray("Items"), options.getString("Email"), options.getString("Taxation")))
        .setGooglePayParams(googlePayParams)
        .setCustomerKey(options.getString("CustomerKey"))
        .startActivityForResult(currentActivity, REQUEST_CODE_PAY);
    } catch (Exception e) {
      rejectPromise(e);
    }
  }

  private Receipt createReceipt(ReadableArray jsItems, String email, String taxationName) throws Exception {
    Taxation taxation;
    switch (taxationName) {
      case "osn":
        taxation = Taxation.OSN;
        break;
      case "usn_income":
        taxation = Taxation.USN_INCOME;
        break;
      case "usn_income_outcome":
        taxation = Taxation.USN_INCOME_OUTCOME;
        break;
      case "envd":
        taxation = Taxation.ENVD;
        break;
      case "esn":
        taxation = Taxation.ESN;
        break;
      case "patent":
        taxation = Taxation.PATENT;
        break;
      default:
        throw new Exception("Incorrect taxation");
    }

    Item[] items = new Item[jsItems.size()];
    for (int index = 0; index < jsItems.size(); index++) {
      ReadableMap i = jsItems.getMap(index);
      Tax tax;

      switch (i.getString("Tax")) {
        case "none":
          tax = Tax.NONE;
          break;
        case "vat0":
          tax = Tax.VAT_0;
          break;
        case "vat10":
          tax = Tax.VAT_10;
          break;
        case "vat18":
          tax = Tax.VAT_18;
          break;
        case "vat110":
          tax = Tax.VAT_110;
          break;
        case "vat118":
          tax = Tax.VAT_118;
          break;
        case "vat20":
          tax = Tax.VAT_110;
          break;
        case "vat120":
          tax = Tax.VAT_118;
          break;
        default:
          throw new Exception("Incorrect item tax");
      }

      items[index] = new Item(
        i.getString("Name"),
        (long)i.getDouble("Price"),
        i.getDouble("Quantity"),
        (long)i.getDouble("Amount"),
        tax
      );
    }

    return new Receipt(items, email, taxation);
  }
}
