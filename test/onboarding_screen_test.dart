import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_app/l10n/app_localizations.dart';
import 'package:homework_app/screens/add_homework_screen.dart';
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

  testWidgets('first-task walkthrough starts on the title field', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('es')],
        home: const AddHomeworkScreen(startWalkthrough: true),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Give your assignment a title'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Next'), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).bottomNavigationBar,
      isNotNull,
    );
    expect(
      find.ancestor(
        of: find.text('Give your assignment a title'),
        matching: find.byType(SafeArea),
      ),
      findsWidgets,
    );
  });

  testWidgets('first-task guide advances only after required fields', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'subjects': ['Mathematics'],
      'subject_icons': '{}',
    });
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('es')],
        home: const AddHomeworkScreen(startWalkthrough: true),
      ),
    );
    await tester.pumpAndSettle();

    final nextButton = find.widgetWithText(FilledButton, 'Next');
    expect(tester.widget<FilledButton>(nextButton).onPressed, isNull);

    final subjectBlockers = find.ancestor(
      of: find.byType(DropdownButtonFormField<String>).first,
      matching: find.byType(IgnorePointer),
    );
    expect(
      subjectBlockers
          .evaluate()
          .map((element) => element.widget)
          .whereType<IgnorePointer>()
          .any((widget) => widget.ignoring),
      isTrue,
    );

    await tester.enterText(find.byType(TextFormField).first, 'Study algebra');
    await tester.pump();
    expect(tester.widget<FilledButton>(nextButton).onPressed, isNotNull);
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    expect(find.text('Choose or create a subject'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mathematics').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();

    expect(find.text('Add details if you need them'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    expect(find.text('Choose when it is due'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    expect(find.text('Get a heads-up before it is due'), findsOneWidget);

    final notificationSwitch = find.widgetWithText(
      SwitchListTile,
      'Receive notification',
    );
    expect(tester.widget<SwitchListTile>(notificationSwitch).value, isFalse);

    await tester.tap(notificationSwitch);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(notificationSwitch).value, isTrue);
    expect(find.text('Reminder 1'), findsOneWidget);
    expect(find.text('Add another reminder'), findsOneWidget);
  });
}
