import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/adhkar_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/streak_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'services/audio_service.dart';
import 'services/auth_service.dart';
import 'services/pwa_install_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdhkarProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => StreakProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()..init()),
        ChangeNotifierProvider(create: (_) => AudioService()),
        ChangeNotifierProvider(create: (_) => PwaInstallService()),
        ChangeNotifierProvider(create: (_) => NotificationService()..init()),
      ],
      child: const AdhkarGazaApp(),
    ),
  );
}

class AdhkarGazaApp extends StatelessWidget {
  const AdhkarGazaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      title: settingsProvider.isFrench ? 'Adhkar Gaza' : 'أذكار غزة',
      debugShowCheckedModeBanner: false,

      // ── Theme ───────────────────────────────────
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,

      // ── Directionality & Locale ─────────────────
      locale: Locale(settingsProvider.language),
      supportedLocales: const [Locale('ar'), Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const HomeScreen(),
    );
  }
}
