// lib/services/ad_service.dart
//
// Wraps Google Mobile Ads rewarded ad loading and display.
//
// Platforms:
//   • Android / iOS : uses google_mobile_ads SDK.
//   • Web           : stubs always return false (ads unsupported).
//
// Ad Unit IDs:
//   Replace the _kAdUnitAndroid / _kAdUnitIOS constants with real IDs before
//   publishing.  The current values are Google's official test unit IDs that
//   show test ads only and are safe to leave during development.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/test_flags.dart';

class AdService {
  // ── Ad unit IDs ────────────────────────────────────────────────────────────
  // Replace with production IDs before release.
  static const String _kAdUnitAndroid =
      'ca-app-pub-3940256099942544/5224354917'; // test rewarded
  static const String _kAdUnitIOS =
      'ca-app-pub-3940256099942544/1712485313'; // test rewarded

  static String get _adUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _kAdUnitIOS;
    }
    return _kAdUnitAndroid;
  }

  // ── State ──────────────────────────────────────────────────────────────────
  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  /// Initialises the Mobile Ads SDK.  Must be called once during app startup.
  static Future<void> init() async {
    if (kIsWeb) {
      return;
    }
    await MobileAds.instance.initialize();
  }

  /// Pre-loads a rewarded ad so it is ready immediately when the user taps.
  /// Safe to call multiple times — skips if already loading or loaded.
  Future<void> preload() async {
    if (kIsWeb || _isLoading || _rewardedAd != null) {
      return;
    }
    _isLoading = true;
    await RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
        },
      ),
    );
  }

  /// Shows the rewarded ad.  Returns `true` if the user earned the reward
  /// (i.e. watched enough of the ad), `false` otherwise (skipped / error).
  Future<bool> showRewardedAd() async {
    if (kIsWeb) {
      return false;
    }

    if (kIsIntegrationTest) {
      return true; // Auto-pass in integration tests
    }

    if (_rewardedAd == null) {
      await preload();
      if (_rewardedAd == null) {
        return false;
      }
    }

    final ad = _rewardedAd!;
    _rewardedAd = null; // consumed

    bool earned = false;
    final completer = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {},
      onAdDismissedFullScreenContent: (_) {
        ad.dispose();
        if (!completer.isCompleted) {
          completer.complete(earned);
        }
        preload(); // pre-load next ad silently
      },
      onAdFailedToShowFullScreenContent: (_, __) {
        ad.dispose();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        preload();
      },
    );

    await ad.show(
      onUserEarnedReward: (_, __) {
        earned = true;
      },
    );

    return completer.future;
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
