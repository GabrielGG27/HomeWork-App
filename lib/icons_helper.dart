import 'package:flutter/material.dart';

// Move available icons to a top-level constant so they can be referenced for tree shaking
const List<IconData> kAvailableIcons = [
  Icons.book,
  Icons.menu_book_rounded,
  Icons.calculate,
  Icons.science,
  Icons.computer,
  Icons.local_restaurant,
  Icons.language,
  Icons.brush,
  Icons.music_note,
  Icons.sports_soccer,
  Icons.code,
  Icons.palette,
  Icons.work,
  Icons.school,
  Icons.lightbulb,
  Icons.local_florist,
  Icons.theater_comedy,
  Icons.show_chart,
  Icons.park,
];

// Helper to look up icon by code point
IconData getIconFromCodePoint(int codePoint) {
  // Try to find the icon in our constant allowed list
  try {
    return kAvailableIcons.firstWhere((icon) => icon.codePoint == codePoint);
  } catch (_) {
    // If not found (e.g. data corruption or legacy), fallback to a default constant
    return Icons.book;
  }
}
