import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:homework_app/services/ads_service.dart';

class NativeAdCard extends StatefulWidget {
  final String? adUnitId;
  final double marginHorizontal;
  final double marginVertical;

  const NativeAdCard({
    super.key,
    this.adUnitId,
    this.marginHorizontal = 16.0,
    this.marginVertical = 4.0,
  });

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _adFailed = false;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only load the ad once
    if (_nativeAd == null && !_adFailed && !_isLoading) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    _isLoading = true;
    try {
      await AdsService.ready;
      if (!AdsService.canRequestAds) {
        if (mounted) {
          setState(() => _adFailed = true);
        }
        return;
      }
      await AdsService.enqueueAdLoad(() async {
        if (!mounted) return;

        final completion = Completer<void>();
        final defaultAdUnitId = Platform.isAndroid
            ? 'ca-app-pub-7427500220267639/1697764045'
            : 'ca-app-pub-7427500220267639/1697764045';

        final colorScheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardBgColor = isDark
            ? colorScheme.surfaceContainer
            : colorScheme.surface;

        _nativeAd = NativeAd(
          adUnitId: widget.adUnitId ?? defaultAdUnitId,
          listener: NativeAdListener(
            onAdLoaded: (ad) {
              if (!identical(_nativeAd, ad)) {
                ad.dispose();
                if (!completion.isCompleted) completion.complete();
                return;
              }
              if (mounted) {
                setState(() => _isAdLoaded = true);
              }
              if (!completion.isCompleted) completion.complete();
            },
            onAdFailedToLoad: (ad, error) {
              debugPrint('NativeAd failed to load: $error');
              ad.dispose();
              if (mounted && identical(_nativeAd, ad)) {
                setState(() {
                  _adFailed = true;
                  _nativeAd = null;
                });
              }
              if (!completion.isCompleted) completion.complete();
            },
          ),
          request: const AdRequest(),
          nativeTemplateStyle: NativeTemplateStyle(
            templateType: TemplateType.small,
            mainBackgroundColor: cardBgColor,
            cornerRadius: 12.0,
            primaryTextStyle: NativeTemplateTextStyle(
              textColor: colorScheme.onSurface,
              size: 15.0,
            ),
            secondaryTextStyle: NativeTemplateTextStyle(
              textColor: colorScheme.onSurfaceVariant,
              size: 13.0,
            ),
            tertiaryTextStyle: NativeTemplateTextStyle(
              textColor: colorScheme.onSurfaceVariant,
              size: 12.0,
            ),
            callToActionTextStyle: NativeTemplateTextStyle(
              textColor: colorScheme.onPrimary,
              backgroundColor: colorScheme.primary,
              size: 14.0,
            ),
          ),
        );

        _nativeAd!.load();
        await completion.future;
      });
    } catch (error) {
      debugPrint('NativeAd initialization or load failed: $error');
      _nativeAd?.dispose();
      _nativeAd = null;
      if (mounted) {
        setState(() => _adFailed = true);
      }
    } finally {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_adFailed) {
      return const SizedBox.shrink();
    }

    if (!_isAdLoaded || _nativeAd == null) {
      // Shimmer or generic placeholder card to prevent UI jump
      return Card(
        margin: EdgeInsets.symmetric(
          horizontal: widget.marginHorizontal,
          vertical: widget.marginVertical,
        ),
        child: Container(
          height: 90,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 150,
                      height: 10,
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: widget.marginHorizontal,
        vertical: widget.marginVertical,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(height: 90, child: AdWidget(ad: _nativeAd!)),
      ),
    );
  }
}
