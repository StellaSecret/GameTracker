// test_flags.dart is pure config. The integration-test branch of
// testAwareDuration (kIsIntegrationTest == true) only exists in integration
// runs; unit tests cover the default pass-through branch.
// Run with: flutter test test/test_flags_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:game_tracker/config/test_flags.dart';

void main() {
  test('kIsIntegrationTest defaults to false in unit tests', () {
    expect(kIsIntegrationTest, isFalse);
  });

  test('testAwareDuration passes normal durations through unchanged', () {
    final normal = const Duration(milliseconds: 250);
    expect(testAwareDuration(normal), normal);
  });
}