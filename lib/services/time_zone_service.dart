import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class TimeZoneService {
  TimeZoneService._();

  static bool _databaseInitialized = false;
  static String? _configuredIdentifier;

  /// Configures timezone's local clock and reports whether it changed.
  ///
  /// Once a valid device timezone has been configured, a transient platform
  /// failure preserves it instead of silently switching scheduled reminders
  /// to UTC.
  static Future<bool> configureLocalTimeZone() async {
    if (!_databaseInitialized) {
      tz_data.initializeTimeZones();
      _databaseInitialized = true;
    }

    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      final identifier = timeZone.identifier;
      final changed = identifier != _configuredIdentifier;
      tz.setLocalLocation(tz.getLocation(identifier));
      _configuredIdentifier = identifier;
      return changed;
    } catch (error) {
      debugPrint('Could not configure the device timezone: $error');
      if (_configuredIdentifier == null) {
        tz.setLocalLocation(tz.getLocation('UTC'));
        _configuredIdentifier = 'UTC';
      }
      return false;
    }
  }
}
