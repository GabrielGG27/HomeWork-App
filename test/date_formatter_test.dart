import 'package:flutter_test/flutter_test.dart';
import 'package:homework_app/utils/date_formatter.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  test('uses localized labels in the completed list', () {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 18);

    final formatted = SmartDateFormatter.formatForCompletedCard(
      tomorrow,
      todayLabel: 'Hoy',
      tomorrowLabel: 'Mañana',
      locale: 'es',
    );

    expect(formatted, startsWith('Mañana ·'));
  });

  test('uses the requested locale for month names', () {
    final formatted = SmartDateFormatter.formatForCard(
      DateTime(2035, 1, 15, 18),
      'upcoming',
      locale: 'es',
    );

    expect(formatted.toLowerCase(), contains('ene'));
    expect(formatted, isNot(contains('Jan')));
  });
}
