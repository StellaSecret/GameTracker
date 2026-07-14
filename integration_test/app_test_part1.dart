// integration_test/app_test_part1.dart
//
// E2E scenarios S1–S6. Boots the app once, then runs this shard's
// scenarios in sequence. Runs as its own emulator job in CI, in parallel
// with app_test_part2.dart (S7–S12) — see .github/workflows/build.yml and
// helpers.dart for the shared boot/interaction helpers and the rationale
// for splitting the suite this way.

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => storage.clear());

  testWidgets('GameTracker E2E suite — part 1 (S1-S6)', (tester) async {
    await bootApp(tester);

    // S1 ─ Home screen structure ─────────────────────────────────────────────
    print('\n[S1] Home screen structure');
    expect(find.byKey(kFabAddGame), findsOneWidget);
    expect(find.byKey(kNavPlayers), findsOneWidget);
    print('[S1] ✓');

    // S2 ─ Create a Points game ──────────────────────────────────────────────
    print('\n[S2] Create Points game');
    await reset();
    await addGame('Catan');
    print('[S2] ✓');

    // S3 ─ Create a Duel game ────────────────────────────────────────────────
    print('\n[S3] Create Duel game');
    await reset();
    await addGame('Échecs', mode: 'duel');
    print('[S3] ✓');

    // S4 ─ Edit a game name ──────────────────────────────────────────────────
    print('\n[S4] Edit game name');
    await reset();
    await addGame('Ticket to Ride');
    // Open detail, then edit.
    await tap(find.text('Ticket to Ride'));
    await t.tap(find.byKey(kBtnEditGame));
    await t.pump(const Duration(milliseconds: 500));
    // Focus the name field and replace its text using showKeyboard +
    // testTextInput. This bypasses enterText's TextFormField routing issues
    // and sets the underlying EditableText / TextEditingController directly.
    await t.tap(find.byKey(kFieldGameName));
    await t.pump(const Duration(milliseconds: 200));
    await t.showKeyboard(find.byKey(kFieldGameName));
    t.testTextInput.updateEditingValue(const TextEditingValue(
      text: 'Ticket to Ride Legacy',
      selection: TextSelection.collapsed(offset: 21),
    ));
    await t.pump(const Duration(milliseconds: 300));
    t.binding.focusManager.primaryFocus?.unfocus();
    await t.pump(const Duration(milliseconds: 200));
    // Tap submit and wait for save + pop chain to complete.
    // NOTE: previously this was guarded by `if (t.any(find.byKey(kBtnSubmitGame)))`
    // without first scrolling it into view. Since the button lives inside a
    // scrollable ListView, `t.any` can return false when it's offstage,
    // which silently skipped the save entirely. `tapUntil` already waits
    // for the finder to appear, so just scroll-and-tap unconditionally.
    await scrollIntoViewIfNeeded(find.byKey(kBtnSubmitGame));
    await tapUntil(
      find.byKey(kBtnSubmitGame),
      find.text('Ticket to Ride Legacy'),
    );
    await backToRoot();
    // Poll for renamed game in list (notifyListeners may lag a few frames).
    final d = DateTime.now().add(kSettle);
    while (!t.any(find.text('Ticket to Ride Legacy'))) {
      if (DateTime.now().isAfter(d)) {
        break;
      }
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Ticket to Ride Legacy'), findsOneWidget);
    print('[S4] ✓');

    // S5 ─ Delete a game ─────────────────────────────────────────────────────
    print('\n[S5] Delete game');
    await reset();
    await addGame('ToDelete');
    await tap(find.text('ToDelete'));
    await t.tap(find.byKey(kBtnEditGame));
    await t.pumpAndSettle(kSettle);
    await t.tap(find.byKey(kBtnDeleteGame));
    await t.pumpAndSettle(kSettle);
    await confirmDialog();
    expect(find.text('ToDelete'), findsNothing);
    print('[S5] ✓');

    // S6 ─ Add a player ──────────────────────────────────────────────────────
    print('\n[S6] Add player');
    await reset();
    await tap(find.byKey(kNavPlayers));
    await addPlayer('Alice');
    print('[S6] ✓');

    print('\n[suite] Part 1 scenarios complete ✓');
  }, timeout: const Timeout(Duration(minutes: 20)));
}
