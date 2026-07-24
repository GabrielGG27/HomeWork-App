import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  AdsService._();

  static final Completer<void> _ready = Completer<void>();
  static bool _initializationStarted = false;

  static Future<void> get ready => _ready.future;

  static Future<void> initialize() async {
    if (_initializationStarted) return ready;
    _initializationStarted = true;

    try {
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(seconds: 2));
      await MobileAds.instance.initialize();
      _ready.complete();
    } catch (error, stackTrace) {
      _ready.completeError(error, stackTrace);
    }
  }
}
