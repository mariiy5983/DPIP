import 'dart:async';
import 'dart:io';

import 'package:dpip/app.dart';
import 'package:dpip/core/compass.dart';
import 'package:dpip/core/device_info.dart';
import 'package:dpip/core/fcm.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/notify.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/core/service.dart';
import 'package:dpip/core/update.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart';

final fcmReadyCompleter = Completer<void>();
final talker = TalkerManager.instance;

const _platform = MethodChannel('com.exptech.dpip/shortcut');

void main() async {
  final overall = Stopwatch()..start();
  talker.log('--- 冷啟動偵測開始 ---');
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isIOS) {
    // iOS 14 以下改回用 StoreKit1
    InAppPurchaseStoreKitPlatform.enableStoreKit1();
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(systemNavigationBarColor: Colors.transparent),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: [SystemUiOverlay.top]);

  FlutterError.onError = (details) => talker.handle(details.exception, details.stack);

  await _timed('Global', Global.init());
  await Preference.init();
  final isFirstLaunch = Preference.instance.getBool('isFirstLaunch') ?? true;
  GlobalProviders.init();
  initializeTimeZones();
  final initialShortcut = await _getInitialShortcut();

  await _timed(
    '並行任務',
    Future.wait([
      _timed('AppLocalizations.load', AppLocalizations.load()),
      _timed('LocationNameLocalizations.load', LocationNameLocalizations.load()),
    ]),
  );

  if (Platform.isIOS) {
    await DeviceInfo.init();
  } else {
    unawaited(_timed('📱 DeviceInfo.init', DeviceInfo.init()));
  }

  if (isFirstLaunch) {
    talker.log('🟣 首次啟動 → 前置初始化 FCM + 通知');
    await Future.wait([_timed('fcmInit', fcmInit()), _timed('notifyInit', notifyInit())]);
    unawaited(Future(updateInfoToServer));
    await Preference.instance.setBool('isFirstLaunch', false);
  }

  talker.log('🚨 總初始化耗時 (runApp 前): ${overall.elapsedMilliseconds}ms');

  runApp(
    I18n(
      initialLocale: GlobalProviders.ui.locale,
      supportedLocales: [
        'en'.asLocale,
        'ja'.asLocale,
        'ko'.asLocale,
        'ru'.asLocale,
        'vi'.asLocale,
        'zh'.asLocale,
        'zh-Hans'.asLocale,
        'zh-Hant'.asLocale,
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: GlobalProviders.data),
          ChangeNotifierProvider.value(value: GlobalProviders.experimental),
          ChangeNotifierProvider.value(value: GlobalProviders.location),
          ChangeNotifierProvider.value(value: GlobalProviders.map),
          ChangeNotifierProvider.value(value: GlobalProviders.notification),
          ChangeNotifierProvider.value(value: GlobalProviders.ui),
        ],
        child: DpipApp(initialShortcut: initialShortcut),
      ),
    ),
  );

  if (!isFirstLaunch) {
    talker.log('🟢 非首次啟動 → FCM + 通知 為背景初始化');
    unawaited(
      Future(() async {
        try {
          await fcmInit();
          await notifyInit();
          await updateInfoToServer();
        } catch (e, st) {
          talker.error('背景初始化失敗: $e\n$st');
        }
      }),
    );
  }

  unawaited(CompassService.instance.initialize());
  unawaited(_timed('🚀 LocationServiceManager', LocationServiceManager.initalize()).catchError((_) {}));
}

Future<String?> _getInitialShortcut() async {
  try {
    return await _platform.invokeMethod<String>('getInitialShortcut');
  } on PlatformException catch (e, st) {
    talker.error('Failed to get initial shortcut', e, st);
    return null;
  }
}

Future<T> _timed<T>(String name, Future<T> future) async {
  final sw = Stopwatch()..start();
  try {
    final result = await future;
    talker.log('✅ $name 完成。耗時: ${sw.elapsedMilliseconds}ms');
    return result;
  } catch (e) {
    talker.error('❌ $name 失敗。耗時: ${sw.elapsedMilliseconds}ms', e);
    rethrow;
  }
}
