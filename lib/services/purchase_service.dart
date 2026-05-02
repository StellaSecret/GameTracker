// RevenueCat wrapper — mobile only (not available on web).
//
// Emails premium gratuits injectés au build :
//   flutter build apk --dart-define=PREMIUM_EMAILS=email1@x.com,email2@x.com
// Aucun email stocké en clair dans le code ou le repo.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/entitlement.dart';

class PurchaseService extends ChangeNotifier {
  static const String _kApiKeyAndroid = 'YOUR_REVENUECAT_ANDROID_KEY';
  static const String _kApiKeyIOS = 'YOUR_REVENUECAT_IOS_KEY';
  static const String _kEntitlementId = 'premium';

  // Injecté par --dart-define=PREMIUM_EMAILS=email1@x.com,email2@x.com
  // Vide si non défini (builds locaux, CI sans le secret)
  static const _premiumEmailsRaw =
      String.fromEnvironment('PREMIUM_EMAILS', defaultValue: '');

  Entitlement _entitlement = const Entitlement.free();
  bool _isLoading = true;
  String? _lastError;

  Entitlement get entitlement => _entitlement;
  bool get isLoading => _isLoading;
  bool get isPremium => _entitlement.isPremium;
  String? get lastError => _lastError;

  Future<void> init() async {
    // Vérifie d'abord l'override email — fonctionne même sans RevenueCat
    if (_isDeveloper()) {
      _entitlement = const Entitlement.premium();
      _isLoading = false;
      notifyListeners();
      return; // Pas besoin d'initialiser RevenueCat pour les devs
    }

    if (kIsWeb) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    // RevenueCat pas encore configuré (clé placeholder) → on skip silencieusement
    if (_kApiKeyAndroid == 'YOUR_REVENUECAT_ANDROID_KEY') {
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

  /// Retourne true si l'email connecté (Firebase OU Google Drive)
  /// est dans la liste PREMIUM_EMAILS injectée au build.
  /// Vérifie les deux sources pour ne pas nécessiter de connexion Firebase.
  bool _isDeveloper() {
    if (_premiumEmailsRaw.isEmpty) return false;
    final allowed = _premiumEmailsRaw
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();

    // Source 1 : Firebase Auth (groupes premium)
    if (!kIsWeb) {
      try {
        final fbEmail =
            FirebaseAuth.instance.currentUser?.email?.toLowerCase().trim();
        if (fbEmail != null && allowed.contains(fbEmail)) return true;
      } catch (_) {}
    }

    // Source 2 : Google Sign-In / Drive (disponible sur toutes les plateformes)
    try {
      final gsEmail =
          GoogleSignIn().currentUser?.email.toLowerCase().trim();
      if (gsEmail != null && allowed.contains(gsEmail)) return true;
    } catch (_) {}

    return false;
  }

  /// À appeler après une connexion Google (Drive ou Firebase)
  /// pour re-vérifier si l'utilisateur a droit au premium gratuit.
  void recheckDeveloperStatus() {
    if (_entitlement.isPremium) return; // déjà premium, rien à faire
    if (_isDeveloper()) {
      _entitlement = const Entitlement.premium();
      notifyListeners();
    }
  }

  Future<Offering?> getOffering() async {
    if (kIsWeb) return null;
    if (_kApiKeyAndroid == 'YOUR_REVENUECAT_ANDROID_KEY') return null;
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
