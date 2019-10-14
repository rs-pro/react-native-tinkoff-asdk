package pro.rocketscience.tinkoff;

import android.app.Activity;
import android.content.Intent;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.Promise;

import com.google.android.gms.wallet.WalletConstants;
import com.google.android.gms.wallet.fragment.WalletFragmentStyle;

import ru.tinkoff.acquiring.sdk.Money;
import ru.tinkoff.acquiring.sdk.Receipt;
import ru.tinkoff.acquiring.sdk.PayFormActivity;
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
    Log.d("Notification", "Tinkoff payment complete");

    if (requestCode == REQUEST_CODE_PAY) {
      if (resultCode == 500) {
          rejectPromise("Ошибка");
      }
      resolvePromise(resultCode);
    }
  }

  private void resolvePromise(int result) {
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
  public void Payment(
    ReadableMap options,
    final Promise promise
  ) {
    rejectPromise("Запущен новый процесс оплаты");
    paymentPromise = promise;

    Log.d("Notification", "Tinkoff payment start");

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

    boolean testMode = false;
    if (options.hasKey("testMode")) {
      testMode = options.getBoolean("testMode");
    }
    if (testMode) {
      Journal.setDebug(true);
      Journal.setDeveloperMode(true);
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

    try {
      PayFormActivity
        .init(
          options.getString("terminalKey"),
          options.getString("password"),
          options.getString("publicKey")
        )
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
      case "OSN":
        taxation = Taxation.OSN;
        break;
      case "USN_INCOME":
        taxation = Taxation.USN_INCOME;
        break;
      case "USN_INCOME_OUTCOME":
        taxation = Taxation.USN_INCOME_OUTCOME;
        break;
      case "ENVD":
        taxation = Taxation.ENVD;
        break;
      case "ESN":
        taxation = Taxation.ESN;
        break;
      case "PATENT":
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
        case "NONE":
          tax = Tax.NONE;
          break;
        case "VAT_0":
          tax = Tax.VAT_0;
          break;
        case "VAT_10":
          tax = Tax.VAT_10;
          break;
        case "VAT_18":
          tax = Tax.VAT_18;
          break;
        case "VAT_110":
          tax = Tax.VAT_110;
          break;
        case "VAT_118":
          tax = Tax.VAT_118;
          break;
        case "VAT_20":
          tax = Tax.VAT_110;
          break;
        case "VAT_120":
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
