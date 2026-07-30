import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ConsentService {
  ConsentService._();

  static Future<bool> gatherConsent() async {
    final updateCompleter = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => updateCompleter.complete(),
      (error) => updateCompleter.completeError(error),
    );

    try {
      await updateCompleter.future;
      await ConsentForm.loadAndShowConsentFormIfRequired((error) {
        if (error != null) {
          debugPrint(
            '[UMP] Consent form error ${error.errorCode}: ${error.message}',
          );
        }
      });
    } catch (error) {
      // UMP can still use consent obtained during an earlier session.
      debugPrint('[UMP] Consent information update failed: $error');
    }

    try {
      return await ConsentInformation.instance.canRequestAds();
    } catch (error) {
      debugPrint(
        '[UMP] Could not determine whether ads can be requested: $error',
      );
      return false;
    }
  }

  static Future<bool> isPrivacyOptionsRequired() async {
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (error) {
      debugPrint('[UMP] Could not read privacy options status: $error');
      return false;
    }
  }

  static Future<bool> showPrivacyOptions() async {
    final completer = Completer<bool>();
    try {
      await ConsentForm.showPrivacyOptionsForm((error) {
        if (error != null) {
          debugPrint(
            '[UMP] Privacy options error ${error.errorCode}: ${error.message}',
          );
          completer.complete(false);
        } else {
          completer.complete(true);
        }
      });
      return await completer.future;
    } catch (error) {
      debugPrint('[UMP] Could not show privacy options: $error');
      return false;
    }
  }
}
