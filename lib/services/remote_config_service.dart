import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:homework_app/services/analytics_service.dart';

class RemoteConfigService {
  RemoteConfigService._();

  static const String showBannerAdParameter = 'show_banner_ad';
  static const bool defaultShowBannerAd = true;
  static const Duration _fetchTimeout = Duration(seconds: 5);
  static const Duration _minimumFetchInterval = Duration(hours: 12);

  static Future<void>? _initialization;
  static bool _showBannerAd = defaultShowBannerAd;

  static bool get showBannerAd => _showBannerAd;

  /// Completes after the remote value has been activated or the safe local
  /// default has been selected. Banner requests should wait for this future so
  /// users assigned to the no-banner variant never see the banner briefly.
  static Future<void> get ready => initialize();

  static Future<void> initialize() =>
      _initialization ??= _initializeRemoteConfig();

  static Future<void> _initializeRemoteConfig() async {
    _showBannerAd = await resolveShowBannerAd(() async {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: _fetchTimeout,
          minimumFetchInterval: _minimumFetchInterval,
        ),
      );
      await remoteConfig.setDefaults(const {
        showBannerAdParameter: defaultShowBannerAd,
      });
      await remoteConfig.fetchAndActivate();
      return remoteConfig.getBool(showBannerAdParameter);
    });

    await AnalyticsService.logBannerConfigurationApplied(
      showBannerAd: _showBannerAd,
    );
  }

  @visibleForTesting
  static Future<bool> resolveShowBannerAd(
    Future<bool> Function() fetchValue,
  ) async {
    try {
      return await fetchValue();
    } catch (error) {
      debugPrint(
        '[Remote Config] Could not resolve $showBannerAdParameter: $error',
      );
      return defaultShowBannerAd;
    }
  }
}
