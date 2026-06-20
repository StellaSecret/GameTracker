// integration_test/app_test.dart
//
// End-to-end integration tests for GameTracker.
//
// Architecture: single-boot, multi-scenario
// ──────────────────────────────────────────
// The app boots ONCE. Each scenario resets state by clearing StorageService
// and navigating back to root, eliminating ~25s of cold-init overhead per test.
//
// Locale-independence
// ───────────────────
// Tests never use translated text to drive interactions. All tappable
// widgets carry semantic Keys assigned in the screen files.

// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_tracker/main.dart' as app;
import 'package:game_tracker/screens/paywall_screen.dart';
import 'package:game_tracker/services/storage_service.dart';
import 'package:integration_test/integration_test.dart';

// ── Widget Keys ───────────────────────────────────────────────────────────────
// games_screen.dart
const _kFabAddGame    = Key('fabAddGame');
const _kNavPlayers    = Key('navPlayers');
const _kNavStats      = Key('navStats');
const _kNavGroups     = Key('navGroups');
// add_game_screen.dart
const _kFieldGameName = Key('fieldGameName');
const _kBtnSubmitGame = ValueKey('btnSubmitGame');
const _kBtnDeleteGame = Key('btnDeleteGame');
// players_screen.dart
const _kFabAddPlayer    = Key('fabAddPlayer');
const _kFieldPlayerName = Key('fieldPlayerName');
const _kBtnSubmitPlayer = Key('btnSubmitPlayer');
const _kBtnDeletePlayer = Key('btnDeletePlayer');
// game_detail_screen.dart
const _kBtnEditGame   = Key('btnEditGame');
// add_session_screen.dart
const _kBtnSaveSession = ValueKey('btnSaveSession');

// ── Timeouts ──────────────────────────────────────────────────────────────────
const _kSettle = Duration(seconds: 15);
const _kBoot   = Duration(seconds: 30); // generous for cold SharedPrefs init

// ── Globals shared across the single testWidgets call ────────────────────────
late WidgetTester _t;
final _storage = StorageService();

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Pop back to the root (GamesScreen) by tapping Back until none remains.
Future<void> _backToRoot() async {
  _t.binding.focusManager.primaryFocus?.unfocus();
  await _t.testTextInput.receiveAction(TextInputAction.done);
  await _t.pump(const Duration(milliseconds: 200));
  while (_t.any(find.byTooltip('Back'))) {
    await _t.tap(find.byTooltip('Back').first);
    final deadline = DateTime.now().add(_kSettle);
    while (_t.any(find.byTooltip('Back'))) {
      if (DateTime.now().isAfter(deadline)) {
        break;
      }
      await _t.pump(const Duration(milliseconds: 100));
    }
  }
  if (_t.any(find.byType(AlertDialog))) {
    await _t.tapAt(const Offset(10, 10));
    await _t.pump(const Duration(milliseconds: 300));
  }
  await _t.pump(const Duration(milliseconds: 300));
}

/// Clear persisted storage and navigate back to root for a clean slate.
Future<void> _reset() async {
  await _backToRoot();
  await _storage.clear();
  await _t.pump(const Duration(milliseconds: 100));
  await _t.pumpAndSettle(_kSettle);
}

/// Dismiss keyboard.
Future<void> _dismissKb() async {
  _t.binding.focusManager.primaryFocus?.unfocus();
  await _t.testTextInput.receiveAction(TextInputAction.done);
  await _t.pumpAndSettle(_kSettle);
}

/// Scroll [finder] into view and tap it, then settle.
Future<void> _tap(Finder finder) async {
  if (!_t.any(finder)) {
    final sv = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axis == Axis.vertical,
      skipOffstage: false,
    );
    if (_t.any(sv)) {
      await _t.scrollUntilVisible(finder, 500, scrollable: sv.first);
      await _t.pumpAndSettle(_kSettle);
    }
  }
  await _t.ensureVisible(finder);
  await _t.tap(finder);
  await _t.pumpAndSettle(_kSettle);
}

/// Tap [finder] and pump frames until [until] appears (max [_kSettle]).
/// Prefer over [_tap] when the tap triggers async work + navigation, to avoid
/// pumpAndSettle spinning on background notifyListeners() chains.
Future<void> _tapUntil(Finder finder, Finder until) async {
  await _t.ensureVisible(finder);
  await _t.tap(finder);
  final deadline = DateTime.now().add(_kSettle);
  while (!_t.any(until)) {
    if (DateTime.now().isAfter(deadline)) {
      throw Exception(
        '_tapUntil timed out waiting for ${until.describeMatch(Plurality.one)}',
      );
    }
    await _t.pump(const Duration(milliseconds: 100));
  }
  await _t.pump(const Duration(milliseconds: 100));
}

/// Enter text into a field identified by [key].
Future<void> _enter(Key key, String text) async {
  await _t.tap(find.byKey(key));
  await _t.pumpAndSettle(_kSettle);
  await _t.enterText(find.byKey(key), text);
  await _t.pumpAndSettle(_kSettle);
  await _dismissKb();
}

/// Add a game with [name] in [mode] ('points', 'duel', or 'ranking').
/// Leaves the app on the GamesScreen list with the game visible.
Future<void> _addGame(String name, {String mode = 'points'}) async {
  await _tap(find.byKey(_kFabAddGame));
  await _enter(_kFieldGameName, name);
  if (mode == 'duel') {
    await _tap(find.text('⚔️'));
  }
  if (mode == 'ranking') {
    await _tap(find.text('🏆'));
  }
  // _tapUntil avoids pumpAndSettle spinning on notifyListeners() chains
  // triggered by _persist() after the save completes (~90s on SwiftShader).
  await _tapUntil(find.byKey(_kBtnSubmitGame), find.text(name));
  expect(find.text(name), findsOneWidget);
}

/// Add a player with [name]. Must already be on the PlayersScreen.
Future<void> _addPlayer(String name) async {
  await _tap(find.byKey(_kFabAddPlayer));
  await _enter(_kFieldPlayerName, name);
  await _tap(find.byKey(_kBtnSubmitPlayer));
  expect(find.text(name), findsOneWidget);
}

/// Confirm the last TextButton in an AlertDialog (the destructive action).
Future<void> _confirmDialog() async {
  final actions = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(TextButton),
  );
  if (_t.any(actions)) {
    await _t.tap(actions.last);
    await _t.pumpAndSettle(_kSettle);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Test suite — single boot, sequential scenarios
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _storage.clear();
  });

  testWidgets('GameTracker full E2E suite', (tester) async {
    _t = tester;

    // ── Boot ────────────────────────────────────────────────────────────────
    print('[suite] booting app...');
    runZonedGuarded(
      () => app.main(),
      (e, st) => print('[suite] UNCAUGHT boot error: $e\n$st'),
    );
    await _t.pump(const Duration(milliseconds: 500));
    await _t.pumpAndSettle(_kBoot);
    print('[suite] app ready');

    expect(
      find.byKey(_kFabAddGame),
      findsOneWidget,
      reason: 'Expected to land on GamesScreen after boot',
    );

    // ════════════════════════════════════════════════════════════════════════
    // S1 · Home screen structure
    // ════════════════════════════════════════════════════════════════════════
    print('\n[S1] Home screen structure');
    expect(find.byKey(_kFabAddGame), findsOneWidget);
    expect(find.byKey(_kNavPlayers), findsOneWidget);
    print('[S1] ✓');

    // ════════════════════════════════════════════════════════════════════════
    // S2 · Create a Points game
    // ════════════════════════════════════════════════════════════════════════
    print('\n[S2] Create Points game');
    await _reset();
    await _addGame('Catan');
    print('[S2] ✓');

    // ════════════════════════════════════════════════════════════════════════
    // S3 · Create a Duel game
    // ════════════════════════════════════════════════════════════════════════
    print('\n[S3] Create Duel game');
    await _reset();
    await _addGame('Échecs', mode: 'duel');
    print('[S3] ✓');

    // ════════════════════════════════════════════════════════════════════════
    // S4 · Edit a game name
    // ════════════════════════════════════════════════════════════════════════
    print('\n[S4] Edit game name');
    await _reset();
    await _addGame('Ticket to Ride');
    await _tap(find.text('Ticket to Ride'));
    await _t.tap(find.byKey(_kBtnEditGame));
    await _t.pumpAndSettle(_kSettle);
    await _enter(_kFieldGameName, 'Ticket to Ride Legacy');
    await _tap(find.byKey(_kBtnSubmitGame));
    if (_t.any(find.byTooltip('Back'))) {
      await _t.tap(find.byTooltip('Back').first);
      await _t.pumpAndSettle(_kSettle);
    }
    expect(find.text('Ticket to Ride Legacy'), findsOneWidget);
    print('[S4] ✓');

    // ════════════════════════════════════════════════════════════════════════
    // S5 · Delete a game
    // ════════════════════════════════════════════════════════════════════════
    print('\n[S5] Delete game');
    await _reset();
    await _addGame('ToDelete');
    await _tap(find.text('ToDelete'));
    await _t.tap(find.byKey(_kBtnEditGame));
    await _t.pumpAndSettle(_kSettle);
    await _t.tap(find.byKey(_kBtnDeleteGame));
    await _t.pumpAndSettle(_kSettle);
    await _confirmDialog();
    expect(find.text('ToDelete'), findsNothing);
    print('[S5] ✓');

    // ════════════════════════════════════════════════════════════════════════
    // S6 · Add a player
    // ════════════════════════════════════════════════════════════════════════
    print('\n[S6] Add player');
    await _reset();
    await _tap(find.byKey(_kNavPlayers));
    await _addPlayer('Alice');
    print('[S6] ✓');

    // ════════════════════════════════════════════════════════════════════════
    // S7 · Delete a player
    // ════════════════════════════════════════════════════════════════════════
    print('\n[S7] Delete player');
    await _reset();
    await _tap(find.byKey(_kNavPlayers));
    await _addPlayer('Bob');
    await _t.tap(find.text('Bob'));
    await _t.pumpAndSettle(_kSettle);
    await _t.tap(find.byKey(_kBtnDeletePlayer));
    await _t.pumpAndSettle(_kSettle);
    await _confirmDialog();
    expect(
      find.descendant(of: find.byType(ListView), matching: find.text('Bob')),
      findsNothing,
    );
    print('[S7] ✓');

    // ════════════════════════════════════════════════════════════════════════
    // S8 · Record a Points session
    // ════════════════════════════════════════════════════════════════════════
    print('\n[S8] Record Points session');
    await _reset();
    await _tap(find.byKey(_kNavPlayers));
    await _addPlayer('Alice');
    await _addPlayer('Bob');
    await _backToRoot();
    await _addGame('Catan Pts');
    await _tap(find.text('Catan Pts'));
    await _t.tap(find.byType(FloatingActionButton).first);
    await _t.pumpAndSettle(_kSettle);
    await _t.tap(find.text('Alice').first);
    await _t.pumpAndSettle(_kSettle);
    await _t.tap(find.text('Bob').first);
    await _t.pumpAndSettle(_kSettle);
    final scoreFields = find.byType(TextField);
    await _t.enterText(scoreFields.first, '120');
    await _t.pumpAndSettle(_kSettle);
    await _t.enterText(scoreFields.at(1), '85');
    await _t.pumpAndSettle(_kSettle);
    await _dismissKb();
    await _tap(find.byKey(_kBtnSaveSession));
    expect(find.text('Catan Pts'), findsOneWidget);
    print('[S8] ✓');

    // ════════════════════════════════════════════════════════════════════════
    // S9 · Record a Duel session
    // ════════════════════════════════════════════════════════════════════════
    print('\n[S9] Record Duel session');
    await _reset();
    await _tap(find.byKey(_kNavPlayers));
    await _addPlayer('Alice');
    await _addPlayer('Bob');
    await _backToRoot();
    await _addGame('Échecs Duel', mode: 'duel');
    await _tap(find.text('Échecs Duel'));
    await _t.tap(find.byType(FloatingActionButton).first);
    await _t.pumpAndSettle(_kSettle);
    await _t.tap(find.text('Alice').first);
    await _t.pumpAndSettle(_kSettle);
    await _t.tap(find.text('Bob').first);
    await _t.pumpAndSettle(_kSettle);
    await _t.tap(find.text('🏆').first);
    await _t.pumpAndSettle(_kSettle);
    await _tap(find.byKey(_kBtnSaveSession));
    expect(find.text('Échecs Duel'), findsOneWidget);
    print('[S9] ✓');

    // ════════════════════════════════════════════════════════════════════════
    // S10 · Search filters games
    // ════════════════════════════════════════════════════════════════════════
    print('\n[S10] Search');
    await _reset();
    await _addGame('SearchGame Alpha');
    await _addGame('SearchGame Beta');
    final searchField = find.byType(TextField).first;
    await _t.enterText(searchField, 'Alpha');
    await _t.pumpAndSettle(_kSettle);
    expect(find.textContaining('Alpha'), findsWidgets);
    expect(find.text('SearchGame Beta'), findsNothing);
    await _t.enterText(searchField, 'Beta');
    await _t.pumpAndSettle(_kSettle);
    expect(find.textContaining('Beta'), findsWidgets);
    expect(find.text('SearchGame Alpha'), findsNothing);
    print('[S10] ✓');

    // ════════════════════════════════════════════════════════════════════════
    // S11 · Stats paywall gating
    // ════════════════════════════════════════════════════════════════════════
    print('\n[S11] Stats paywall');
    await _reset();
    expect(find.byKey(_kNavStats), findsOneWidget);
    await _t.tap(find.byKey(_kNavStats));
    await _t.pumpAndSettle(_kSettle);
    expect(find.byKey(const Key('btnUnlockStatsWithAd')), findsOneWidget);
    await _backToRoot();
    print('[S11] ✓');

    // ════════════════════════════════════════════════════════════════════════
    // S12 · Groups paywall gating
    // ════════════════════════════════════════════════════════════════════════
    print('\n[S12] Groups paywall');
    await _reset();
    expect(find.byKey(_kNavGroups), findsOneWidget);
    await _t.tap(find.byKey(_kNavGroups));
    await _t.pumpAndSettle(_kSettle);
    expect(find.byType(PaywallScreen), findsOneWidget);
    final paywall = _t.widget<PaywallScreen>(find.byType(PaywallScreen));
    expect(paywall.target, PaywallTarget.groupSync);
    print('[S12] ✓');

    print('\n[suite] All scenarios complete ✓');
  }, timeout: const Timeout(Duration(minutes: 20)));
}
