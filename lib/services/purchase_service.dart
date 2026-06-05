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
        hasGroupSync: active.containsKey(kGroupSyncId) || _isDeveloper(),
      );
    } catch (_) {
      _entitlement = Entitlement(
        isPremium:    _isDeveloper(),
        hasGroupSync: _isDeveloper(),
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
    }
  }

  bool _isDeveloper() {
    if (_premiumEmailsRaw.isEmpty) {
      return false;
    }
    final allowed = _premiumEmailsRaw
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
        if (fbEmail != null && allowed.contains(fbEmail)) return true;
      } catch (_) {}
    }
    return false;
  }

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
      final info   = await Purchases.purchasePackage(package);
      final active = info.entitlements.active;
      _entitlement = Entitlement(
        isPremium:    active.containsKey(kPremiumId)   || _isDeveloper(),
        hasGroupSync: active.containsKey(kGroupSyncId) || _isDeveloper(),
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
        hasGroupSync: active.containsKey(kGroupSyncId) || _isDeveloper(),
      );
      notifyListeners();
      return _entitlement.isPremium || _entitlement.hasGroupSync;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }
}
