import 'dart:async';
import 'dart:io';

import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/core/notify.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/constants.dart';
import 'package:dpip/utils/log.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'main.dart';

/// The root widget of the application.
///
/// This widget initializes and configures the application's core services, theming, localization, and navigation
/// infrastructure.
class DpipApp extends StatefulWidget {
  /// Creates a new [DpipApp] instance.
  final String? initialShortcut;

  const DpipApp({super.key, this.initialShortcut});

  @override
  State<DpipApp> createState() => _DpipAppState();
}

class _DpipAppState extends State<DpipApp> with WidgetsBindingObserver {
  bool _hasHandledInitialShortcut = false;

  Future<void> _checkNotificationPermission() async {
    if (Platform.isAndroid) return;
    await fcmReadyCompleter.future;
    final status = (await FirebaseMessaging.instance.getNotificationSettings()).authorizationStatus;
    final allowed = status == .authorized || status == .provisional;

    if (Preference.isFirstLaunch || allowed) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && router.routerDelegate.navigatorKey.currentContext != null) {
        const WelcomePermissionsRoute().go(context);
      }
    });
  }

  Future<void> _checkUpdate() async {
    if (kDebugMode || !Platform.isAndroid) return;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) return;

      if (info.immediateUpdateAllowed) {
        InAppUpdate.performImmediateUpdate();
      } else if (info.flexibleUpdateAllowed) {
        final updateResult = await InAppUpdate.startFlexibleUpdate();
        if (updateResult != AppUpdateResult.success) return;
        InAppUpdate.completeFlexibleUpdate();
      }
    } catch (e, s) {
      TalkerManager.instance.error('_DpipState._checkUpdate', e, s);
    }
  }

  void _tryHandleInitialShortcut() {
    if (_hasHandledInitialShortcut) return;
    if (widget.initialShortcut == null) return;
    if (router.routerDelegate.navigatorKey.currentContext == null) return;

    _hasHandledInitialShortcut = true;

    if (widget.initialShortcut == 'monitor') {
      MapRoute(layers: MapLayer.monitor.name).push(context);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    GlobalProviders.data.onAppLifecycleStateChanged(state);
  }

  @override
  void initState() {
    super.initState();

    _checkUpdate();
    WidgetsBinding.instance.addObserver(this);
    GlobalProviders.data.startFetching();
    _checkNotificationPermission();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(
        const Duration(milliseconds: 500),
        () => handlePendingNotificationNavigation(context),
      );
      _tryHandleInitialShortcut();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return Consumer<SettingsUserInterfaceModel>(
          builder: (context, model, child) {
            final switchTheme = SwitchThemeData(
              thumbIcon: .resolveWith(
                (states) =>
                    states.contains(WidgetState.selected) ? Icon(Symbols.check_rounded) : null,
              ),
            );

            final cardTheme = CardThemeData(
              shape: RoundedRectangleBorder(borderRadius: .circular(16)),
            );

            final notoFallback = switch (I18n.locale.toLanguageTag()) {
              'zh-Hans' => GoogleFonts.notoSansSc().fontFamily!,
              'ja' => GoogleFonts.notoSansJp().fontFamily!,
              'ko' => GoogleFonts.notoSansKr().fontFamily!,
              'vi' || 'ru' => GoogleFonts.notoSans().fontFamily!,
              _ => GoogleFonts.notoSansTc().fontFamily!,
            };

            TextStyle applyFlex(TextStyle? base) => (base ?? const TextStyle()).copyWith(
              fontFamily: 'Google Sans Flex',
              fontFamilyFallback: [...?base?.fontFamilyFallback, notoFallback],
            );

            TextTheme buildTextTheme(TextTheme base) => base.copyWith(
              displayLarge: applyFlex(base.displayLarge),
              displayMedium: applyFlex(base.displayMedium),
              displaySmall: applyFlex(base.displaySmall),
              headlineLarge: applyFlex(base.headlineLarge),
              headlineMedium: applyFlex(base.headlineMedium),
              headlineSmall: applyFlex(base.headlineSmall),
              titleLarge: applyFlex(base.titleLarge),
              titleMedium: applyFlex(base.titleMedium),
              titleSmall: applyFlex(base.titleSmall),
              bodyLarge: applyFlex(base.bodyLarge),
              bodyMedium: applyFlex(base.bodyMedium),
              bodySmall: applyFlex(base.bodySmall),
              labelLarge: applyFlex(base.labelLarge),
              labelMedium: applyFlex(base.labelMedium),
              labelSmall: applyFlex(base.labelSmall),
            );

            ThemeData buildTheme(Brightness brightness, Color? seed) {
              final ThemeData base = .new(
                colorSchemeSeed: seed,
                brightness: brightness,
                snackBarTheme: const .new(behavior: .floating),
                pageTransitionsTheme: kZoomPageTransitionsTheme,
                cardTheme: cardTheme,
                switchTheme: switchTheme,
                // TODO(kamiya4047): Opt-in to new Material 3 update, remove this after it becomes the default option
                sliderTheme: const .new(year2023: false),
                progressIndicatorTheme: const .new(year2023: false),
              );
              return base.copyWith(textTheme: buildTextTheme(base.textTheme));
            }

            final seed = model.themeColor;

            return MaterialApp.router(
              builder: (context, child) {
                final mq = MediaQuery.of(context);
                return MediaQuery(
                  data: mq.copyWith(
                    textScaler: mq.textScaler.clamp(minScaleFactor: 0.5, maxScaleFactor: 1.2),
                  ),
                  child: child!,
                );
              },
              title: 'DPIP',
              theme: buildTheme(.light, seed ?? lightDynamic?.primary),
              darkTheme: buildTheme(.dark, seed ?? darkDynamic?.primary),
              themeMode: model.themeMode,
              localizationsDelegates: I18n.localizationsDelegates,
              supportedLocales: I18n.supportedLocales,
              locale: I18n.locale,
              routerConfig: router,
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
