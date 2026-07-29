import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_app/l10n/app_localizations.dart';
import 'package:homework_app/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _testApp({Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('es')],
    home: const OnboardingScreen(isReplay: true),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('skip stores completion and does not start walkthrough', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.text('Your assignments, under control'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding_skip')));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(onboardingCompletedKey), isTrue);
  });

  testWidgets('all pages are reachable and localized in Spanish', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(locale: const Locale('es')));
    await tester.pumpAndSettle();

    expect(find.text('Tus tareas, bajo control'), findsOneWidget);

    for (var page = 0; page < 3; page++) {
      await tester.tap(find.byKey(const ValueKey('onboarding_next')));
      await tester.pumpAndSettle();
    }

    expect(find.text('Observa tu progreso'), findsOneWidget);
    expect(find.text('Comenzar'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding_next')));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(onboardingCompletedKey), isTrue);
  });

  testWidgets('back returns to the previous onboarding page', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('onboarding_next')));
    await tester.pumpAndSettle();
    expect(find.text('Organize by subject'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Your assignments, under control'), findsOneWidget);
  });
}
