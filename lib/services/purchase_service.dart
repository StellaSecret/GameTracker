import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/entitlement.dart';
 
class PurchaseService extends ChangeNotifier {
  static const String _kApiKeyAndroid = 'YOUR_REVENUECAT_ANDROID_KEY';
  static const String _kApiKeyIOS = 'YOUR_REVENUECAT_IOS_KEY';
  static const String _kEntitlementId = 'premium';
 
  // On web: always act as free plan, silently.
  Entitlement _entitlement = const Entitlement.free();
  bool _isLoading = true;
  String? _lastError;
 
  Entitlement get entitlement => _entitlement;
  bool get isLoading => _isLoading;
  bool get isPremium => _entitlement.isPremium;
  String? get lastError => _lastError;
 
  Future<void> init() async {
    if (kIsWeb) {
      _isLoading = false;
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
      _entitlement = Entitlement(
        isPremium: info.entitlements.active.containsKey(_kEntitlementId),
      );
    } catch (_) {}
    notifyListeners();
  }
 
  Future<Offering?> getOffering() async {
    if (kIsWeb) return null;
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
