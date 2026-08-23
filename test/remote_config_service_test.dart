import 'package:flutter_test/flutter_test.dart';
import 'package:homework_app/services/remote_config_service.dart';

void main() {
  test('uses the remotely resolved no-banner value', () async {
    final result = await RemoteConfigService.resolveShowBannerAd(
      () async => false,
    );

    expect(result, isFalse);
  });

  test('keeps banners enabled when Remote Config fails', () async {
    final result = await RemoteConfigService.resolveShowBannerAd(
      () async => throw Exception('network unavailable'),
    );

    expect(result, RemoteConfigService.defaultShowBannerAd);
  });
}
