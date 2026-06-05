// lib/models/entitlement.dart

/// Three independent entitlements — each can be held simultaneously.
///
/// Free (everyone)
///   • Unlimited games, sessions, players
///   • Drive backup (local/user-owned, no server cost)
///
/// Premium (one-time purchase or annual subscription)
///   • Advanced stats — win-rate trends, head-to-head, streaks
///   • CSV export     — session history download
///
/// Group Sync (monthly subscription — kept separate because Firestore
///   reads/writes cost money at scale; a one-time Premium payment cannot
///   sustainably fund an ongoing per-user infrastructure cost)
///   • Real-time sync between players via Firestore
///
/// Users can hold Premium + Group Sync simultaneously.
class Entitlement {
  final bool isPremium;
  final bool hasGroupSync;

  const Entitlement({
    required this.isPremium,
    required this.hasGroupSync,
  });

  const Entitlement.free()
      : isPremium = false,
        hasGroupSync = false;

  const Entitlement.premiumOnly()
      : isPremium = true,
        hasGroupSync = false;

  const Entitlement.groupSyncOnly()
      : isPremium = false,
        hasGroupSync = true;

  const Entitlement.full()
      : isPremium = true,
        hasGroupSync = true;

  // ── Always free ───────────────────────────────────────────────────────────

  bool get canAddGame => true;
  bool canAddSession(int _) => true;

  /// Drive backup is free — local/user-owned operation, no server cost.
  bool get canUseDriveBackup => true;

  // ── Premium features ──────────────────────────────────────────────────────

  /// Advanced stats: win-rate trends, head-to-head records, streak details.
  bool get canUseAdvancedStats => isPremium;

  /// CSV export of session history.
  bool get canExportSessions => isPremium;

  // ── Group Sync subscription ───────────────────────────────────────────────

  /// Real-time group sync via Firestore.
  /// Gated separately because Firestore cost scales with active groups.
  bool get canUseGroupSync => hasGroupSync;
}
