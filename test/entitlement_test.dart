// entitlement.dart had no direct test coverage, so the mutation suite treated
// it as notcovered. These tests exercise every constructor and gate flag so
// the file enters mutation scope.
// Run with: flutter test test/entitlement_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:game_tracker/models/entitlement.dart';

void main() {
  const combos = <(Entitlement, bool, bool)>[
    (Entitlement.free(), false, false),
    (Entitlement.premiumOnly(), true, false),
    (Entitlement.groupSyncOnly(), false, true),
    (Entitlement.full(), true, true),
  ];

  test('constructors set entitlement flags correctly', () {
    for (final (e, premium, sync) in combos) {
      expect(e.isPremium, premium, reason: 'isPremium mismatch');
      expect(e.hasGroupSync, sync, reason: 'hasGroupSync mismatch');
    }
  });

  test('premium gates follow isPremium', () {
    for (final (e, premium, _) in combos) {
      expect(e.canUseAdvancedStats, premium);
      expect(e.canExportSessions, premium);
    }
  });

  test('group sync gate follows hasGroupSync', () {
    for (final (e, _, sync) in combos) {
      expect(e.canUseGroupSync, sync);
    }
  });

  test('free features are never gated', () {
    for (final (e, _, _) in combos) {
      expect(e.canAddGame, isTrue);
      expect(e.canAddSession(7), isTrue);
      expect(e.canUseDriveBackup, isTrue);
    }
  });
}