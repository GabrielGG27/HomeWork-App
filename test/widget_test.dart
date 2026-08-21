import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_app/l10n/app_localizations.dart';
import 'package:homework_app/models/attachment.dart';
import 'package:homework_app/models/homework.dart';
import 'package:homework_app/screens/add_homework_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('homework survives a JSON round trip with its attachments', () {
    final dueDate = DateTime(2026, 8, 15, 9, 30);
    final homework = Homework(
      id: 'homework-1',
      title: 'Study algebra',
      subject: 'Mathematics',
      dueDate: dueDate,
      description: 'Exercises 1–10',
      isImportant: true,
      notificationOffsets: const [1440, 30],
      attachments: [
        Attachment(
          id: 'attachment-1',
          type: 'file',
          path: '/app/attachments/exercises.pdf',
          filename: 'exercises.pdf',
          mimeType: 'pdf',
          size: 2048,
          createdAtMs: 1234,
        ),
      ],
    );

    final restored = Homework.fromJson(homework.toJson());

    expect(restored.id, homework.id);
    expect(restored.title, homework.title);
    expect(restored.subject, homework.subject);
    expect(restored.dueDate, dueDate);
    expect(restored.description, homework.description);
    expect(restored.isImportant, isTrue);
    expect(restored.notificationOffsets, [1440, 30]);
    expect(restored.notificationOffset, 1440);
    expect(restored.toJson()['notificationOffset'], 1440);
    expect(restored.attachments, hasLength(1));
    expect(restored.attachments.single.filename, 'exercises.pdf');
    expect(restored.attachments.single.size, 2048);
  });

  test('legacy notification data migrates to one reminder', () {
    final restored = Homework.fromJson({
      'id': 'legacy-homework',
      'title': 'Legacy task',
      'subject': 'History',
      'dueDate': DateTime(2026, 8, 20).millisecondsSinceEpoch,
      'enableNotification': true,
      'notificationOffset': 30,
    });

    expect(restored.notificationOffsets, [30]);
    expect(restored.enableNotification, isTrue);
  });

  test('disabled legacy notification migrates to no reminders', () {
    final restored = Homework.fromJson({
      'id': 'legacy-homework',
      'title': 'Legacy task',
      'subject': 'History',
      'dueDate': DateTime(2026, 8, 20).millisecondsSinceEpoch,
      'enableNotification': false,
      'notificationOffset': 30,
    });

    expect(restored.notificationOffsets, isEmpty);
    expect(restored.enableNotification, isFalse);
  });

  testWidgets('new homework form displays and validates required fields', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('es')],
        home: AddHomeworkScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('New'), findsOneWidget);
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Subject'), findsOneWidget);
    expect(find.text('Reminder 1'), findsOneWidget);
    expect(find.text('Add another reminder'), findsOneWidget);

    final saveButton = find.widgetWithText(ElevatedButton, 'Save');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pump();

    expect(find.text('Enter a title'), findsOneWidget);
    expect(find.text('Select or create a subject'), findsOneWidget);
  });
}
