import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'services/notification_service.dart';
import 'screens/homework_list_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/purchases_service.dart';
import 'services/ads_service.dart';

import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  tz_data.initializeTimeZones();
  try {
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    final deviceTimeZone = tzInfo.identifier;
    tz.setLocalLocation(tz.getLocation(deviceTimeZone));
  } catch (e) {
    tz.setLocalLocation(tz.getLocation('UTC'));
  }

  await NotificationService.initializeNotifications();

  runApp(const MyApp());
  unawaited(AdsService.initialize());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  static void setThemeMode(BuildContext context, ThemeMode newThemeMode) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setThemeMode(newThemeMode);
  }
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isReady = false;
  bool _hasCompletedOnboarding = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final languageCode = prefs.getString('languageCode');
    final themeString = prefs.getString('themeMode');
    setState(() {
      if (languageCode != null) _locale = Locale(languageCode);
      _themeMode = switch (themeString) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      };
      _hasCompletedOnboarding = prefs.getBool(onboardingCompletedKey) ?? false;
      _isReady = true;
    });
  }

  void setLocale(Locale value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', value.languageCode);
    if (!mounted) return;
    setState(() {
      _locale = value;
    });
  }

  void setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String themeString = 'system';
    if (mode == ThemeMode.dark) themeString = 'dark';
    if (mode == ThemeMode.light) themeString = 'light';
    await prefs.setString('themeMode', themeString);
    if (!mounted) return;
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PurchasesService(),
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
        ),
        themeMode: _themeMode,
        locale: _locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'), // English
          Locale('es'), // Spanish
        ],
        home: !_isReady
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : _hasCompletedOnboarding
            ? const HomeworkListScreen()
            : const OnboardingScreen(),
      ),
    );
  }
}
