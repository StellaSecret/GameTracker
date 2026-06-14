import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'screens/games_screen.dart';
import 'screens/players_screen.dart';
import 'services/app_state.dart';
import 'services/google_sign_in_singleton.dart';
import 'theme/app_theme.dart';
import 'theme/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GoogleSignInSingleton.initialize();

  GoogleFonts.config.allowRuntimeFetching = true;

  // Pre-load date symbols for every supported locale so DateFormat works
  // without a network call. Add new locales here when the ARB list grows.
  await Future.wait([
    initializeDateFormatting('fr_FR'),
    initializeDateFormatting('en_US'),
  ]);

  // Firebase — mobile only (no web config)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase init error: $e');
    }
  }

  final themeNotifier = ThemeNotifier();
  await themeNotifier.init();

  final uri = Uri.base;
  final isDemoMode = uri.queryParameters['demo'] == 'true';
  final state = AppState();
  await state.init(isDemoMode: isDemoMode);

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
