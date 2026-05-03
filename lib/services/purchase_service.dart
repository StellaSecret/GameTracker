// lib/services/purchase_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/entitlement.dart';

class PurchaseService extends ChangeNotifier {
  static const String _kApiKeyAndroid = 'YOUR_REVENUECAT_ANDROID_KEY';
  static const String _kApiKeyIOS = 'YOUR_REVENUECAT_IOS_KEY';
  static const String _kEntitlementId = 'premium';
  static const _premiumEmailsRaw =
      String.fromEnvironment('PREMIUM_EMAILS', defaultValue: '');

  Entitlement _entitlement = const Entitlement.free();
  bool _isLoading = true;
  String? _lastError;

  // Email injecté depuis l'extérieur (Drive ou Firebase) après connexion
  String? _connectedEmail;

  Entitlement get entitlement => _entitlement;
  bool get isLoading => _isLoading;
  bool get isPremium => _entitlement.isPremium;
  String? get lastError => _lastError;

  /// Appelé par AppState dès qu'un email Google est connu (Drive ou Firebase)
  void setConnectedEmail(String? email) {
    _connectedEmail = email?.toLowerCase().trim();
    debugPrint('=== PurchaseService: email reçu: $_connectedEmail ===');
    recheckDeveloperStatus();
  }

  Future<void> init() async {
    if (_isDeveloper()) {
      _entitlement = const Entitlement.premium();
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
    if (kIsWeb) return;
    try {
      final info = await Purchases.getCustomerInfo();
      final hasSub = info.entitlements.active.containsKey(_kEntitlementId);
      _entitlement = Entitlement(isPremium: hasSub || _isDeveloper());
    } catch (_) {
      _entitlement = Entitlement(isPremium: _isDeveloper());
    }
    notifyListeners();
  }

  void recheckDeveloperStatus() {
    if (_entitlement.isPremium) return;
    debugPrint('=== PREMIUM CHECK ===');
    debugPrint('premiumEmailsRaw: $_premiumEmailsRaw');
    debugPrint('connectedEmail: $_connectedEmail');

    // Firebase Auth
    if (!kIsWeb) {
      try {
        final fbEmail = FirebaseAuth.instance.currentUser?.email;
        debugPrint('Firebase email: $fbEmail');
      } catch (e) {
        debugPrint('Firebase error: $e');
      }
    }

    if (_isDeveloper()) {
      debugPrint('=== PREMIUM ACTIVÉ ===');
      _entitlement = const Entitlement.premium();
      notifyListeners();
    }
  }

  bool _isDeveloper() {
    if (_premiumEmailsRaw.isEmpty) return false;
    final allowed = _premiumEmailsRaw
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();

    // Source 1 : email injecté explicitement (Drive ou Firebase)
    if (_connectedEmail != null && allowed.contains(_connectedEmail!)) {
      return true;
    }

    // Source 2 : Firebase Auth (si connecté)
    if (!kIsWeb) {
      try {
        final fbEmail =
            FirebaseAuth.instance.currentUser?.email?.toLowerCase().trim();
        if (fbEmail != null && allowed.contains(fbEmail)) return true;
      } catch (_) {}
    }

    return false;
  }

  Future<Offering?> getOffering() async {
    if (kIsWeb || _kApiKeyAndroid == 'YOUR_REVENUECAT_ANDROID_KEY') return null;
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current;
    } catch (e) {
      _lastError = e.toString();
      return null;
    }
  }

  Future<bool> purchase(Package package) async {
    if (kIsWeb) return false;
    try {
      _lastError = null;
      final info = await Purchases.purchasePackage(package);
      _entitlement = Entitlement(
        isPremium: info.entitlements.active.containsKey(_kEntitlementId),
      );
      notifyListeners();
      return _entitlement.isPremium;
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
    if (kIsWeb) return false;
    try {
      _lastError = null;
      final info = await Purchases.restorePurchases();
      _entitlement = Entitlement(
        isPremium: info.entitlements.active.containsKey(_kEntitlementId),
      );
      notifyListeners();
      return _entitlement.isPremium;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }
}
