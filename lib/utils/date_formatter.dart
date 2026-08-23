import 'package:intl/intl.dart';

/// Contextual date formatter that adapts the display format based on
/// when the due date falls relative to "now".
///
/// **In-app format** (card already sits under a section header):
///   Overdue   → Feb 04 · 3:40 PM
///   Today     → 3:40 PM
///   Tomorrow  → 3:40 PM
///   This Week → Thu · 3:41 PM
///   Upcoming  → Feb 11, 2026 · 3:42 PM
///
/// **Notification format** (no visual section context):
///   Today        → Today · 3:40 PM
///   Tomorrow     → Tomorrow · 3:41 PM
///   This week    → Thu · 3:41 PM
///   Further away → Feb 11, 2026
class SmartDateFormatter {
  SmartDateFormatter._();

  // ──────────────────────────────────────────────
  //  IN-APP  (cards inside section groups)
  // ──────────────────────────────────────────────

  /// Returns a contextual date string for display in task cards.
  /// [sectionKey] must be one of: 'overdue', 'today', 'tomorrow', 'week', 'upcoming'.
  static String formatForCard(
    DateTime dueDate,
    String sectionKey, {
    String? locale,
  }) {
    final time = DateFormat.jm(locale).format(dueDate);

    switch (sectionKey) {
      case 'overdue':
        // e.g. "Feb 04 · 3:40 PM"
        final date = DateFormat.MMMd(locale).format(dueDate);
        return '$date · $time';

      case 'today':
        // Only show time – the section header already says "Today"
        return time;

      case 'tomorrow':
        // Only show time – the section header already says "Tomorrow"
        return time;

      case 'week':
        // e.g. "Thu · 3:41 PM"
        final day = DateFormat.E(locale).format(dueDate);
        return '$day · $time';

      case 'upcoming':
        // e.g. "Feb 11, 2026 · 3:42 PM"
        final date = DateFormat.yMMMd(locale).format(dueDate);
        return '$date · $time';

      default:
        final date = DateFormat.yMMMd(locale).format(dueDate);
        return '$date · $time';
    }
  }

  // ──────────────────────────────────────────────
  //  COMPLETED TAB  (no section grouping)
  // ──────────────────────────────────────────────

  /// Returns a contextual date string for the completed-tasks list,
  /// which is a flat list (no section headers).
  static String formatForCompletedCard(
    DateTime dueDate, {
    required String todayLabel,
    required String tomorrowLabel,
    String? locale,
  }) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final tomorrowEnd = tomorrowStart.add(const Duration(days: 1));
    final endOfWeek = todayStart.add(const Duration(days: 7));

    final time = DateFormat.jm(locale).format(dueDate);

    if (dueDate.isBefore(now)) {
      // Overdue
      final date = DateFormat.MMMd(locale).format(dueDate);
      return '$date · $time';
    } else if (dueDate.isBefore(tomorrowStart)) {
      // Today
      return '$todayLabel · $time';
    } else if (dueDate.isBefore(tomorrowEnd)) {
      // Tomorrow
      return '$tomorrowLabel · $time';
    } else if (dueDate.isBefore(endOfWeek)) {
      // This week
      final day = DateFormat.E(locale).format(dueDate);
      return '$day · $time';
    } else {
      // Upcoming
      final date = DateFormat.yMMMd(locale).format(dueDate);
      return '$date · $time';
    }
  }

  // ──────────────────────────────────────────────
  //  NOTIFICATIONS  (no visual section context)
  // ──────────────────────────────────────────────

  /// Returns a contextual string for notification body text.
  /// [isSpanish] toggles Today/Tomorrow labels.
  static String formatForNotification(
    DateTime dueDate, {
    bool isSpanish = false,
  }) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final tomorrowEnd = tomorrowStart.add(const Duration(days: 1));
    final endOfWeek = todayStart.add(const Duration(days: 7));

    final locale = isSpanish ? 'es' : 'en';
    final time = DateFormat.jm(locale).format(dueDate);

    if (dueDate.isBefore(tomorrowStart)) {
      // Today (or overdue but same day)
      final label = isSpanish ? 'Hoy' : 'Today';
      return '$label · $time';
    } else if (dueDate.isBefore(tomorrowEnd)) {
      // Tomorrow
      final label = isSpanish ? 'Mañana' : 'Tomorrow';
      return '$label · $time';
    } else if (dueDate.isBefore(endOfWeek)) {
      // This week
      final day = DateFormat.E(locale).format(dueDate);
      return '$day · $time';
    } else {
      // Further away – just the date, no time
      return DateFormat.yMMMd(locale).format(dueDate);
    }
  }
}
