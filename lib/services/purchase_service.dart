// lib/services/purchase_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/entitlement.dart';

class PurchaseService extends ChangeNotifier {
  static const String _kApiKeyAndroid = 'YOUR_REVENUECAT_ANDROID_KEY';
  static const String _kApiKeyIOS     = 'YOUR_REVENUECAT_IOS_KEY';

  /// RevenueCat entitlement IDs — must match what you configure in the RC dashboard.
  static const String kPremiumId   = 'premium';    // one-time / annual
  static const String kGroupSyncId = 'group_sync'; // monthly subscription

  static const _premiumEmailsRaw =
      String.fromEnvironment('PREMIUM_EMAILS');

  // Separate from _premiumEmailsRaw on purpose: Premium and Group Sync are
  // deliberately independent entitlements (see entitlement.dart) — a
  // comp'd/beta group-sync tester shouldn't automatically get Premium's
  // advanced stats/CSV export as a side effect, and vice versa.
  static const _groupSyncEmailsRaw =
      String.fromEnvironment('GROUP_SYNC_EMAILS');

  Entitlement _entitlement = const Entitlement.free();
  bool _isLoading = true;
  String? _lastError;
  String? _connectedEmail;

  Entitlement get entitlement => _entitlement;
  bool get isLoading    => _isLoading;
  bool get isPremium    => _entitlement.isPremium;
  bool get hasGroupSync => _entitlement.hasGroupSync;
  String? get lastError => _lastError;

  void setConnectedEmail(String? email) {
    _connectedEmail = email?.toLowerCase().trim();
    recheckDeveloperStatus();
  }

  Future<void> init() async {
    if (_isDeveloper()) {
      _entitlement = const Entitlement.full();
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (kIsWeb || _kApiKeyAndroid == 'YOUR_REVENUECAT_ANDROID_KEY') {
      // No RevenueCat lookup possible here (web, or RC not configured yet) —
      // still honor a group-sync-only comp if the connected email is
      // allowlisted, so it isn't silently ignored on this path.
      _entitlement = Entitlement(
        isPremium: _entitlement.isPremium,
        hasGroupSync: _isGroupSyncAllowlisted(),
      );
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      await Purchases.setLogLevel(LogLevel.error);
      final config = PurchasesConfiguration(
        defaultTargetPlatform == TargetPlatform.android
            ? _kApiKeyAndroid
            : _kApiKeyIOS,
      );
      await Purchases.configure(config);
      await _refreshEntitlement();
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshEntitlement() async {
    if (kIsWeb) {
      return;
    }
    try {
      final info   = await Purchases.getCustomerInfo();
      final active = info.entitlements.active;
      _entitlement = Entitlement(
        isPremium:    active.containsKey(kPremiumId)   || _isDeveloper(),
        hasGroupSync: active.containsKey(kGroupSyncId) || _isDeveloper() || _isGroupSyncAllowlisted(),
      );
    } catch (_) {
      _entitlement = Entitlement(
        isPremium:    _isDeveloper(),
        hasGroupSync: _isDeveloper() || _isGroupSyncAllowlisted(),
      );
    }
    notifyListeners();
  }

  void recheckDeveloperStatus() {
    if (_entitlement.isPremium && _entitlement.hasGroupSync) {
      return;
    }
    if (_isDeveloper()) {
      debugPrint('=== DEVELOPER — full entitlement activated ===');
      _entitlement = const Entitlement.full();
      notifyListeners();
      return;
    }
    if (!_entitlement.hasGroupSync && _isGroupSyncAllowlisted()) {
      debugPrint('=== GROUP SYNC allowlist — group sync activated ===');
      _entitlement = Entitlement(
        isPremium: _entitlement.isPremium,
        hasGroupSync: true,
      );
      notifyListeners();
    }
  }

  /// Returns true if the currently known email (set via [setConnectedEmail],
  /// or the signed-in Firebase Auth user) appears in [rawList] — a
  /// comma-separated string from a --dart-define, same format used by both
  /// PREMIUM_EMAILS and GROUP_SYNC_EMAILS.
  bool _emailInList(String rawList) {
    if (rawList.isEmpty) {
      return false;
    }
    final allowed = rawList
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
    if (_connectedEmail != null && allowed.contains(_connectedEmail!)) {
      return true;
    }
    if (!kIsWeb) {
      try {
        final fbEmail =
            FirebaseAuth.instance.currentUser?.email?.toLowerCase().trim();
        if (fbEmail != null && allowed.contains(fbEmail)) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  /// PREMIUM_EMAILS allowlist — grants full developer/reviewer access to
  /// BOTH entitlements at once (e.g. App Store reviewers, your own dev
  /// testing). Unchanged, pre-existing mechanism.
  bool _isDeveloper() => _emailInList(_premiumEmailsRaw);

  /// GROUP_SYNC_EMAILS allowlist — grants ONLY Group Sync, independent of
  /// Premium. Use this for comp'ing/beta-testing the real-time group
  /// feature for specific users without also handing them Premium's
  /// advanced stats/CSV export.
  bool _isGroupSyncAllowlisted() => _emailInList(_groupSyncEmailsRaw);

  /// Returns the current offering for [productId].
  /// Pass [kPremiumId] or [kGroupSyncId] to get the right offering.
  Future<Offering?> getOffering({String productId = kPremiumId}) async {
    if (kIsWeb || _kApiKeyAndroid == 'YOUR_REVENUECAT_ANDROID_KEY') {
      return null;
    }
    try {
      final offerings = await Purchases.getOfferings();
      // RevenueCat lets you name offerings — fall back to current if no match.
      return offerings.all[productId] ?? offerings.current;
    } catch (e) {
      _lastError = e.toString();
      return null;
    }
  }

  Future<bool> purchase(Package package) async {
    if (kIsWeb) {
      return false;
    }
    try {
      _lastError = null;
      // v10: Use PurchaseParams.package(package)
      final purchaseParams = PurchaseParams.package(package);
      final result = await Purchases.purchase(purchaseParams);

      // v10: Access CustomerInfo via purchaseResult.customerInfo
      final active = result.customerInfo.entitlements.active;
      _entitlement = Entitlement(
        isPremium:    active.containsKey(kPremiumId)   || _isDeveloper(),
        hasGroupSync: active.containsKey(kGroupSyncId) || _isDeveloper() || _isGroupSyncAllowlisted(),
      );
      notifyListeners();
      return _entitlement.isPremium || _entitlement.hasGroupSync;
    } catch (e) {
      if (e is PurchasesErrorCode &&
          e == PurchasesErrorCode.purchaseCancelledError) {
        return false;
      }
      _lastError = e.toString();
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    if (kIsWeb) {
      return false;
    }
    try {
      _lastError = null;
      final info   = await Purchases.restorePurchases();
      final active = info.entitlements.active;
      _entitlement = Entitlement(
        isPremium:    active.containsKey(kPremiumId)   || _isDeveloper(),
        hasGroupSync: active.containsKey(kGroupSyncId) || _isDeveloper() || _isGroupSyncAllowlisted(),
      );
      notifyListeners();
      return _entitlement.isPremium || _entitlement.hasGroupSync;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }
}
