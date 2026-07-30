import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:homework_app/services/consent_service.dart';

class AdsService {
  AdsService._();

  static final Completer<void> _ready = Completer<void>();
  static bool _initializationStarted = false;
  static bool _canRequestAds = false;
  static Future<void> _loadQueue = Future<void>.value();

  static Future<void> get ready => _ready.future;
  static bool get canRequestAds => _canRequestAds;

  static Future<void> initialize() async {
    if (_initializationStarted) return ready;
    _initializationStarted = true;

    try {
      await WidgetsBinding.instance.endOfFrame;
      _canRequestAds = await ConsentService.gatherConsent();
      if (!_canRequestAds) {
        _ready.complete();
        return;
      }
      await Future<void>.delayed(const Duration(seconds: 2));
      await MobileAds.instance.initialize();
      _ready.complete();
    } catch (error) {
      _canRequestAds = false;
      debugPrint('[Ads] Initialization failed: $error');
      if (!_ready.isCompleted) _ready.complete();
    }
  }

  static Future<void> enqueueAdLoad(Future<void> Function() load) async {
    await ready;
    if (!_canRequestAds) return;

    final previousLoad = _loadQueue;
    final currentLoad = () async {
      try {
        await previousLoad;
      } catch (_) {
        // A failed request must not prevent later ads from loading.
      }

      await Future<void>.delayed(const Duration(milliseconds: 750));
      await load().timeout(const Duration(seconds: 30));
    }();

    _loadQueue = currentLoad.catchError((_) {});
    await currentLoad;
  }
}
