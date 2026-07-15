// lib/services/ad_service.dart
//
// Wraps Google Mobile Ads rewarded ad loading and display.
//
// Platforms:
//   • Android / iOS : uses google_mobile_ads SDK.
//   • Web           : stubs always return false (ads unsupported).
//
// Ad Unit IDs:
//   Ad unit IDs aren't secrets — Google requires them client-side so the SDK
//   can request ads at all, and anyone with the built APK could extract them
//   regardless of source visibility. The real risk with an open-source repo
//   isn't leakage, it's a fork rebuilding with the production ID still baked
//   in, whose ad traffic then gets attributed to this project's AdMob
//   account. So, same pattern as GOOGLE_WEB_CLIENT_ID / GOOGLE_SERVER_CLIENT_ID
//   in SETUP.md: the production ID is injected at release-build time via
//   --dart-define (see .github/workflows/build.yml, "Build Android (APK & AAB)"),
//   from a GitHub Actions secret. Anyone building from source without that
//   secret gets Google's official public test IDs below as the default —
//   safe to commit, shows test ads only.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/test_flags.dart';

class AdService {
  // ── Ad unit IDs ────────────────────────────────────────────────────────────
  // Defaults are Google's official test rewarded ad units — safe to ship as
  // committed source. Real IDs come from --dart-define at release-build time.
  static const String _kAdUnitAndroid = String.fromEnvironment(
    'ADMOB_REWARDED_AD_UNIT_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917', // test rewarded
  );
  static const String _kAdUnitIOS = String.fromEnvironment(
    'ADMOB_REWARDED_AD_UNIT_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/1712485313', // test rewarded
  );

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
