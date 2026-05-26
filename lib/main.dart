import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'screens/games_screen.dart';
import 'screens/players_screen.dart';
import 'services/app_state.dart';
import 'theme/app_theme.dart';
import 'theme/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  GoogleFonts.config.allowRuntimeFetching = false;
  await initializeDateFormatting('fr_FR');

  // Firebase — uniquement sur mobile (pas de config web)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase init error: $e');
    }
  }

  final themeNotifier = ThemeNotifier();
  await themeNotifier.init();

  final state = AppState();
  await state.init();

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

    // Sync system UI chrome with the active brightness.
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
      localizationsDelegates: const [],
      routes: {
        '/': (_) => const GamesScreen(),
        '/players': (_) => const PlayersScreen(),
      },
      initialRoute: '/',
    );
  }
}
