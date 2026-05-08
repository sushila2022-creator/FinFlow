import 'package:flutter/material.dart';

/// ADMOB REMOVED - NO ADS DISPLAYED EVER
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // All methods do nothing - ads are completely disabled
  Future<void> initialize() async {
    // AdMob initialization removed
  }

  bool shouldShowAds(BuildContext context) {
    return false;
  }

  void loadBannerAd() {
    // No ads loaded
  }

  Widget getBannerAdWidget(BuildContext context) {
    return const SizedBox.shrink();
  }

  void loadInterstitialAd() {
    // No ads loaded
  }

  Future<void> showInterstitialAd(BuildContext context) async {
    // No ads shown
  }

  void dispose() {
    // Nothing to dispose
  }
}
