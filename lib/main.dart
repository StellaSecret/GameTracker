import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'config/test_flags.dart';
import 'l10n/app_localizations.dart';
import 'screens/games_screen.dart';
import 'screens/players_screen.dart';
import 'services/ad_service.dart';
import 'services/app_state.dart';
import 'services/google_sign_in_singleton.dart';
import 'theme/app_theme.dart';
import 'theme/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[boot] WidgetsFlutterBinding ready (integrationTest=$kIsIntegrationTest)');

  // Skipped during integration tests: GoogleSignIn.instance.initialize()
  // talks to Google Play Services / Credential Manager on Android, which
  // CI emulator images (e.g. google_atd) don't fully support — the call
  // can hang indefinitely waiting for a callback that never arrives.
  if (!kIsIntegrationTest) {
    await GoogleSignInSingleton.initialize();
  }
  debugPrint('[boot] GoogleSignIn step done');

  // NOTE: Lexend (used for body text, see app_theme.dart) is intentionally
  // fetched over the network via google_fonts at runtime — unlike Outfit
  // (used for headers), it is not bundled as a local asset. Disabling
  // allowRuntimeFetching here without a bundled Lexend-Regular.ttf makes
  // every text style resolution throw instead of falling back, which is
  // worse than the flakiness it was meant to fix. Properly fixing the CI
  // network dependency means self-hosting Lexend .ttf files the same way
  // Outfit already is (download the font, add it under assets/fonts/, and
  // declare it in pubspec.yaml's fonts section) — until then, leave this on.
  GoogleFonts.config.allowRuntimeFetching = true;

  // Pre-load date symbols for every supported locale so DateFormat works
  // without a network call. Add new locales here when the ARB list grows.
  await Future.wait([
    initializeDateFormatting('fr_FR'),
    initializeDateFormatting('en_US'),
  ]);
  debugPrint('[boot] date symbols loaded');

  // Firebase — mobile only (no web config)
  if (!kIsWeb && !kIsIntegrationTest) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase init error: $e');
    }
  }
  debugPrint('[boot] Firebase step done');

  // Mobile Ads SDK — mobile only.
  // Skipped during integration tests: MobileAds.instance.initialize() can
  // hang indefinitely on CI emulator images (e.g. google_atd) that lack full
  // Google Play Services, since its completion callback never fires.
  if (!kIsIntegrationTest) {
    await AdService.init();
  }
  debugPrint('[boot] Ads step done');

  final themeNotifier = ThemeNotifier();
  await themeNotifier.init();
  debugPrint('[boot] theme init done');

  final uri = Uri.base;
  final isDemoMode = uri.queryParameters['demo'] == 'true';
  final state = AppState();
  await state.init(isDemoMode: isDemoMode);
  debugPrint('[boot] AppState init done');

  // Skipped during integration tests: RewardedAd.load() opens a platform
  // channel to the Mobile Ads SDK and its callback never fires on CI emulator
  // images (google_atd) that lack full Google Play Services — causing
  // pumpAndSettle() to spin forever waiting for the frame loop to quiesce.
  if (!kIsIntegrationTest) {
    unawaited(state.adService.preload()); // warm up first ad
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        ChangeNotifierProvider.value(value: themeNotifier),
      ],
      child: const GameTrackerApp(),
    ),
  );
}

class GameTrackerApp extends StatelessWidget {
  const GameTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();

    final isDark = themeNotifier.isDark;
    if (!kIsWeb) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor:
            isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF5F4FB),
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ));
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    return MaterialApp(
      title: 'GameTracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeNotifier.mode,

      // ── Localization ──────────────────────────────────────────────────────
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,

      routes: {
        '/': (_) => const GamesScreen(),
        '/players': (_) => const PlayersScreen(),
      },
      initialRoute: '/',
    );
  }
}
