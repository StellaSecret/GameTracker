// lib/models/entitlement.dart

/// Describes what the user is allowed to do.
class Entitlement {
  /// Max number of games allowed on free plan. null = unlimited.
  static const int freeGameLimit = 5;

  /// Max number of sessions stored per game on free plan. null = unlimited.
  static const int freeSessionLimit = 20;

  final bool isPremium;

  const Entitlement({required this.isPremium});

  const Entitlement.free() : isPremium = false;
  const Entitlement.premium() : isPremium = true;

  bool canAddGame(int currentCount) =>
      isPremium || currentCount < freeGameLimit;

  bool canAddSession(int currentSessionCount) =>
      isPremium || currentSessionCount < freeSessionLimit;

  /// Real-time group sync is a premium feature.
  bool get canUseGroupSync => isPremium;
}
