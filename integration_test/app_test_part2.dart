// integration_test/app_test_part2.dart
//
// E2E scenarios S7–S12. Boots the app once, then runs this shard's
// scenarios in sequence. Runs as its own emulator job in CI, in parallel
// with app_test_part1.dart (S1–S6) — see .github/workflows/build.yml and
// helpers.dart for the shared boot/interaction helpers and the rationale
// for splitting the suite this way.

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_tracker/screens/paywall_screen.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => storage.clear());

  testWidgets('GameTracker E2E suite — part 2 (S7-S12)', (tester) async {
    await bootApp(tester);

    // S7 ─ Delete a player ───────────────────────────────────────────────────
    print('\n[S7] Delete player');
    await reset();
    await tap(find.byKey(kNavPlayers));
    await addPlayer('Bob');
    await t.tap(find.text('Bob'));
    await t.pumpAndSettle(kSettle);
    await t.tap(find.byKey(kBtnDeletePlayer));
    await t.pumpAndSettle(kSettle);
    await confirmDialog();
    expect(
      find.descendant(of: find.byType(ListView), matching: find.text('Bob')),
      findsNothing,
    );
    print('[S7] ✓');

    // S8 ─ Record a Points session ───────────────────────────────────────────
    print('\n[S8] Record Points session');
    await reset();
    await tap(find.byKey(kNavPlayers));
    await addPlayer('Alice');
    await addPlayer('Bob');
    await backToRoot();
    await addGame('Catan Pts');
    await tap(find.text('Catan Pts'));
    await t.tap(find.byType(FloatingActionButton).first);
    await t.pump(const Duration(milliseconds: 500));
    await t.tap(find.text('Alice').first);
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text('Bob').first);
    await t.pump(const Duration(milliseconds: 300));
    final scoreFields = find.byType(TextField);
    await t.enterText(scoreFields.first, '120');
    await t.pump(const Duration(milliseconds: 200));
    await t.enterText(scoreFields.at(1), '85');
    await t.pump(const Duration(milliseconds: 200));
    await dismissKb();
    // Scroll to save button only when not already visible — mirrors the
    // same guard used for btnSubmitGame in addGame, needed here because
    // the save button can be pushed below the fold too, especially in
    // duel mode where each player's row (avatar + win/draw/loss buttons)
    // is visually taller than a points-mode single-line score field.
    await scrollIntoViewIfNeeded(find.byKey(kBtnSaveSession));
    await tapUntil(find.byKey(kBtnSaveSession), find.text('Catan Pts'));
    expect(find.text('Catan Pts'), findsOneWidget);
    print('[S8] ✓');

    // S9 ─ Record a Duel session ─────────────────────────────────────────────
    print('\n[S9] Record Duel session');
    await reset();
    await tap(find.byKey(kNavPlayers));
    await addPlayer('Alice');
    await addPlayer('Bob');
    await backToRoot();
    await addGame('Échecs Duel', mode: 'duel');
    await tap(find.text('Échecs Duel'));
    await t.tap(find.byType(FloatingActionButton).first);
    await t.pump(const Duration(milliseconds: 500));
    await t.tap(find.text('Alice').first);
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text('Bob').first);
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text('🏆').first);
    await t.pump(const Duration(milliseconds: 300));
    await scrollIntoViewIfNeeded(find.byKey(kBtnSaveSession));
    await tapUntil(find.byKey(kBtnSaveSession), find.text('Échecs Duel'));
    expect(find.text('Échecs Duel'), findsOneWidget);
    print('[S9] ✓');

    // S10 ─ Search ───────────────────────────────────────────────────────────
    print('\n[S10] Search');
    await reset();
    await addGame('SearchGame Alpha');
    await addGame('SearchGame Beta');
    final searchField = find.byType(TextField).first;
    await t.enterText(searchField, 'Alpha');
    await t.pumpAndSettle(kSettle);
    expect(find.textContaining('Alpha'), findsWidgets);
    expect(find.text('SearchGame Beta'), findsNothing);
    await t.enterText(searchField, 'Beta');
    await t.pumpAndSettle(kSettle);
    expect(find.textContaining('Beta'), findsWidgets);
    expect(find.text('SearchGame Alpha'), findsNothing);
    print('[S10] ✓');

    // S11 ─ Stats paywall ────────────────────────────────────────────────────
    print('\n[S11] Stats paywall');
    await reset();
    // StatsScreen checks `state.games.isEmpty` BEFORE checking
    // `canUseAdvancedStats` — with zero games it renders a plain empty
    // state (no unlock button at all), not the paywall. Need at least one
    // game for the paywall branch to be reachable.
    await addGame('StatsPaywallGame');
    expect(find.byKey(kNavStats), findsOneWidget);
    await t.tap(find.byKey(kNavStats));
    await t.pumpAndSettle(kSettle);
    expect(find.byKey(const Key('btnUnlockStatsWithAd')), findsOneWidget);
    await backToRoot();
    print('[S11] ✓');

    // S12 ─ Groups paywall ───────────────────────────────────────────────────
    print('\n[S12] Groups paywall');
    await reset();
    expect(find.byKey(kNavGroups), findsOneWidget);
    await t.tap(find.byKey(kNavGroups));
    await t.pumpAndSettle(kSettle);
    expect(find.byType(PaywallScreen), findsOneWidget);
    final paywall = t.widget<PaywallScreen>(find.byType(PaywallScreen));
    expect(paywall.target, PaywallTarget.groupSync);
    print('[S12] ✓');

    print('\n[suite] Part 2 scenarios complete ✓');
  }, timeout: const Timeout(Duration(minutes: 20)));
}
