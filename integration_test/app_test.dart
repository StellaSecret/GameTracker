// integration_test/app_test.dart
//
// End-to-end integration tests for GameTracker.
//
// Architecture: single-boot, multi-scenario
// ──────────────────────────────────────────
// The app boots ONCE. Each scenario resets state by clearing StorageService
// and navigating back to root, eliminating ~25s of cold-init overhead per test.
//
// Performance notes
// ─────────────────
// • scrollUntilVisible is only called when the target isn't already visible
//   AND the scrollable actually has overflow. When range==0, attempting to
//   scroll causes repeated failed drag attempts (~2s per _addGame call).
// • pumpAndSettle is avoided after taps that trigger notifyListeners() chains
//   (_persist → group push). We use _tapUntil or fixed-duration pump() instead.
// • Session form interactions use pump(300ms) not pumpAndSettle — chip taps
//   and text entry are synchronous; no need to wait for full frame drain.

// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_tracker/main.dart' as app;
import 'package:game_tracker/screens/paywall_screen.dart';
import 'package:game_tracker/services/app_state.dart';
import 'package:game_tracker/services/storage_service.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

// ── Widget Keys ───────────────────────────────────────────────────────────────
const _kFabAddGame     = Key('fabAddGame');
const _kNavPlayers     = Key('navPlayers');
const _kNavStats       = Key('navStats');
const _kNavGroups      = Key('navGroups');
const _kFieldGameName  = Key('fieldGameName');
const _kBtnSubmitGame  = ValueKey('btnSubmitGame');
const _kBtnDeleteGame  = Key('btnDeleteGame');
const _kFabAddPlayer   = Key('fabAddPlayer');
const _kFieldPlayerName = Key('fieldPlayerName');
const _kBtnSubmitPlayer = Key('btnSubmitPlayer');
const _kBtnDeletePlayer = Key('btnDeletePlayer');
const _kBtnEditGame    = Key('btnEditGame');
const _kBtnSaveSession = ValueKey('btnSaveSession');

// ── Timeouts ──────────────────────────────────────────────────────────────────
const _kSettle = Duration(seconds: 15);
const _kBoot   = Duration(seconds: 30);

// ── Globals ───────────────────────────────────────────────────────────────────
late WidgetTester _t;
final _storage = StorageService();

// ─────────────────────────────────────────────────────────────────────────────
// Scroll helper — only scrolls when truly needed
// ─────────────────────────────────────────────────────────────────────────────

/// Finds the Element of the vertical Scrollable that actually has content
/// overflow (maxScrollExtent > 0), or null if none does.
///
/// A screen can legitimately contain more than one vertical Scrollable —
/// e.g. AddGameScreen's outer form ListView AND the multi-line description
/// TextFormField's own internal EditableText (multi-line text fields wrap
/// themselves in a Scrollable too). Diagnostics from a real failure showed
/// exactly this: two vertical Scrollables, one with maxScrollExtent 163.57
/// (the form) and one with maxScrollExtent 0.0 (the text field). Picking
/// "the first" or "the last" match is a coin flip that depends on
/// unspecified tree order — picking the one that actually overflows is
/// the only selection criterion that means what we want ("the thing that
/// needs scrolling to reveal an off-screen control").
Element? _mainVerticalScrollableElement() {
  final sv = find.byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.vertical);
  Element? best;
  double bestExtent = 0;
  for (final e in sv.evaluate()) {
    final w = e.widget as Scrollable;
    final extent = w.controller?.position.maxScrollExtent ?? 0;
    if (extent > bestExtent) {
      bestExtent = extent;
      best = e;
    }
  }
  return best;
}

/// Scrolls [finder] into view only when it isn't already present AND some
/// vertical scrollable actually has overflow (maxScrollExtent > 0).
Future<void> _scrollIntoViewIfNeeded(Finder finder) async {
  if (_t.any(finder)) {
    return; // already visible, nothing to do
  }

  final element = _mainVerticalScrollableElement();
  if (element == null) {
    return; // nothing has real overflow — content fits, or truly not found
  }

  final scrollable = find.byElementPredicate((e) => e == element);
  await _t.scrollUntilVisible(finder, 300, scrollable: scrollable);
  await _t.pump(const Duration(milliseconds: 150));
}

// ─────────────────────────────────────────────────────────────────────────────
// Core interaction helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Tap [finder] after optionally scrolling into view. Settles fully.
Future<void> _tap(Finder finder) async {
  await _scrollIntoViewIfNeeded(finder);
  if (_t.any(finder)) {
    await _t.ensureVisible(finder);
  }
  await _t.tap(finder);
  await _t.pumpAndSettle(_kSettle);
}

/// Dumps diagnostic info to the test log right before we give up waiting
/// on [finder]. Generic over whatever finder is actually stuck — an
/// earlier version of this hardcoded checks for _kBtnSubmitGame, which
/// gave misleading results when the actual stuck call was waiting on a
/// different widget (e.g. btnSaveSession on the session-recording screen).
void _dumpDiagnostics(String label, Finder finder) {
  debugPrint('--- DIAGNOSTICS: $label ---');
  debugPrint('Waiting on: ${finder.toString()}');
  try {
    final allScrollables = find.byWidgetPredicate((w) => w is Scrollable);
    final n = allScrollables.evaluate().length;
    debugPrint('Scrollable count (all axes, default skipOffstage): $n');
    for (final e in allScrollables.evaluate()) {
      final w = e.widget as Scrollable;
      final pos = w.controller?.position;
      debugPrint(
        '  Scrollable axisDirection=${w.axisDirection} '
        'hasController=${w.controller != null} '
        'pixels=${pos?.pixels} maxScrollExtent=${pos?.maxScrollExtent}',
      );
    }
  } catch (e) {
    debugPrint('  (failed to enumerate scrollables: $e)');
  }
  try {
    debugPrint(
      'finder.evaluate().length with default skipOffstage: '
      '${finder.evaluate().length}',
    );
  } catch (e) {
    debugPrint('  (failed to evaluate finder: $e)');
  }
  try {
    final buttons = find.byType(ElevatedButton);
    debugPrint('ElevatedButton count in tree: ${buttons.evaluate().length}');
    final iconButtons = find.byType(IconButton);
    debugPrint('IconButton count in tree: ${iconButtons.evaluate().length}');
    final fabs = find.byType(FloatingActionButton);
    debugPrint(
      'FloatingActionButton count in tree: ${fabs.evaluate().length}',
    );
  } catch (e) {
    debugPrint('  (failed to count buttons: $e)');
  }
  try {
    final view = _t.binding.platformDispatcher.views.first;
    debugPrint(
      'viewInsets.bottom=${view.viewInsets.bottom} '
      'physicalSize=${view.physicalSize}',
    );
  } catch (e) {
    debugPrint('  (failed to read view metrics: $e)');
  }
  try {
    final titles = find
        .descendant(of: find.byType(AppBar), matching: find.byType(Text))
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .toList();
    debugPrint('Current AppBar title text(s): $titles');
  } catch (e) {
    debugPrint('  (failed to read AppBar title: $e)');
  }
  try {
    debugDumpApp();
  } catch (e) {
    debugPrint('  (debugDumpApp failed: $e)');
  }
  debugPrint('--- END DIAGNOSTICS: $label ---');
}

/// Tap [finder] then pump frames until [until] is visible (max [_kSettle]).
/// Use instead of _tap when the action triggers async persistence +
/// notifyListeners() chains that would cause pumpAndSettle to spin for minutes.
Future<void> _tapUntil(Finder finder, Finder until) async {
  // Wait for finder to be present (it may need a frame or two to appear).
  final appearDeadline = DateTime.now().add(_kSettle);
  while (!_t.any(finder)) {
    if (DateTime.now().isAfter(appearDeadline)) {
      _dumpDiagnostics('finder never appeared', finder);
      throw Exception(
        '_tapUntil: finder never appeared: '
        '${finder.describeMatch(Plurality.one)}',
      );
    }
    await _t.pump(const Duration(milliseconds: 100));
  }
  await _scrollIntoViewIfNeeded(finder);
  if (_t.any(finder)) {
    await _t.ensureVisible(finder);
  }
  await _t.tap(finder);
  final deadline = DateTime.now().add(_kSettle);
  while (!_t.any(until)) {
    if (DateTime.now().isAfter(deadline)) {
      _dumpDiagnostics('until never appeared after tap', until);
      throw Exception(
        '_tapUntil timed out waiting for '
        '${until.describeMatch(Plurality.one)}',
      );
    }
    await _t.pump(const Duration(milliseconds: 100));
  }
  // The tap above often triggers Navigator.pop, which starts a page
  // transition. During that transition BOTH routes are briefly mounted:
  // the outgoing form (e.g. its EditableText still showing the typed
  // value, which is `finder`'s own screen) and the revealed screen
  // underneath (e.g. a list Text with the same string, `until`). `find.text`
  // matches Text and EditableText alike, so `until` can transiently match
  // more than once right as it first appears.
  //
  // We need to wait until there is NO duplicate. Previously this used
  // `_t.any(finder) && duplicateExists`, an AND — which is wrong: it exits
  // the instant EITHER condition flips, including the moment `finder` (the
  // submit button) disappears even if the duplicate is still there (the
  // button's route can finish popping slightly before the orphaned
  // EditableText itself unmounts). That let a real duplicate slip through
  // to the caller's findsOneWidget check. The only thing that actually
  // matters is "is there still a duplicate" — check that alone.
  final settleDeadline = DateTime.now().add(_kSettle);
  while (_t.widgetList(until).length > 1) {
    if (DateTime.now().isAfter(settleDeadline)) {
      break;
    }
    await _t.pump(const Duration(milliseconds: 100));
  }
  await _t.pump(const Duration(milliseconds: 100));
}

/// Enter text into [key] field and dismiss keyboard.
/// Uses showKeyboard + updateEditingValue to bypass TextFormField routing
/// issues with enterText — ensures text reaches the TextEditingController.
Future<void> _enter(Key key, String text) async {
  await _t.tap(find.byKey(key));
  await _t.pump(const Duration(milliseconds: 200));
  await _t.showKeyboard(find.byKey(key));
  _t.testTextInput.updateEditingValue(TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  ));
  await _t.pump(const Duration(milliseconds: 200));
  _t.binding.focusManager.primaryFocus?.unfocus();
  await _t.pump(const Duration(milliseconds: 300));
}

/// Dismiss keyboard without settling.
Future<void> _dismissKb() async {
  _t.binding.focusManager.primaryFocus?.unfocus();
  await _t.testTextInput.receiveAction(TextInputAction.done);
  await _t.pump(const Duration(milliseconds: 200));
}

/// Pop back to GamesScreen root.
Future<void> _backToRoot() async {
  _t.binding.focusManager.primaryFocus?.unfocus();
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

/// Clear storage, re-initialise AppState in-memory, and return to root.
/// StorageService.clear() only wipes SharedPreferences — it does NOT call
/// notifyListeners() on AppState. Without re-init, the widget tree keeps
/// stale games/players in memory and _tapUntil can't find newly added items.
Future<void> _reset() async {
  await _backToRoot();
  // Clear any leftover search filter text. GamesScreen's search field is
  // plain local widget state (`_search`), not part of AppState — it
  // survives state.init() below untouched. A query left over from an
  // earlier step (e.g. S10's search test) would otherwise silently filter
  // newly-created games out of the visible list in every step after it.
  //
  // Deliberately NOT using enterText here. This runs on a real emulator
  // with a real IME, not a pure widget-test harness — enterText drives the
  // fake testTextInput channel, and evidence from repeated failures shows
  // the value can revert (diagnostics confirmed "Beta" was still the
  // live value immediately after a supposedly-successful enterText('')).
  // That smells like a race between the simulated input and a lingering
  // real platform text-input session. Skip the input pipeline entirely:
  // call the TextField's onChanged directly, which is the actual
  // mechanism that updates `_search` — this reproduces the same state
  // change deterministically without depending on IME choreography.
  for (final e in find.byType(TextField).evaluate().toList()) {
    (e.widget as TextField).onChanged?.call('');
  }
  await _t.pump(const Duration(milliseconds: 200));
  _t.binding.focusManager.primaryFocus?.unfocus();
  await _t.pump(const Duration(milliseconds: 200));
  await _storage.clear();
  // Re-load AppState from now-empty storage so in-memory data is cleared.
  final state = Provider.of<AppState>(
    _t.element(find.byType(MaterialApp).first),
    listen: false,
  );
  await state.init();
  await _t.pump(const Duration(milliseconds: 200));
}

/// Confirm the destructive action in an AlertDialog (last TextButton).
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
// Domain helpers
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _addGame(String name, {String mode = 'points'}) async {
  await _tap(find.byKey(_kFabAddGame));
  await _enter(_kFieldGameName, name);
  if (mode == 'duel') {
    await _tap(find.text('⚔️'));
  }
  if (mode == 'ranking') {
    await _tap(find.text('🏆'));
  }
  // Scroll to submit only when not already visible (form fits viewport on
  // most runs, but guard against tall content on some display configs).
  await _scrollIntoViewIfNeeded(find.byKey(_kBtnSubmitGame));
  // _tapUntil: avoids pumpAndSettle spinning on _persist → notifyListeners().
  await _tapUntil(find.byKey(_kBtnSubmitGame), find.text(name));
  final matches = find.text(name).evaluate().length;
  if (matches != 1) {
    // This expect() doesn't go through _tapUntil, so the usual diagnostics
    // never fire for it — dump the same info here so a "Found 0" failure
    // (game apparently not visible at all: filtered out by leftover search
    // text? not actually saved? on the wrong screen?) is diagnosed from
    // evidence next time instead of guessed at again.
    debugPrint(
      '--- DIAGNOSTICS: _addGame final text check (found $matches, want 1) ---',
    );
    try {
      final searchFields = find.byType(TextField).evaluate().toList();
      debugPrint('TextField count: ${searchFields.length}');
      for (final e in searchFields) {
        final editable = find.descendant(
          of: find.byWidget(e.widget),
          matching: find.byType(EditableText),
        );
        final text = _t.any(editable)
            ? (_t.widget(editable.first) as EditableText).controller.text
            : '(no EditableText found)';
        debugPrint('  TextField current text: "$text"');
      }
    } catch (e) {
      debugPrint('  (failed to inspect TextFields: $e)');
    }
    try {
      final titles = find
          .descendant(of: find.byType(AppBar), matching: find.byType(Text))
          .evaluate()
          .map((e) => (e.widget as Text).data)
          .toList();
      debugPrint('Current AppBar title text(s): $titles');
    } catch (e) {
      debugPrint('  (failed to read AppBar title: $e)');
    }
    try {
      final allTexts = find
          .byType(Text)
          .evaluate()
          .map((e) => (e.widget as Text).data)
          .where((d) => d != null && d.isNotEmpty)
          .toList();
      debugPrint('All visible Text widgets: $allTexts');
    } catch (e) {
      debugPrint('  (failed to enumerate Text widgets: $e)');
    }
    debugPrint('--- END DIAGNOSTICS ---');
  }
  expect(find.text(name), findsOneWidget);
}

Future<void> _addPlayer(String name) async {
  await _tap(find.byKey(_kFabAddPlayer));
  await _enter(_kFieldPlayerName, name);
  await _tapUntil(find.byKey(_kBtnSubmitPlayer), find.text(name));
  expect(find.text(name), findsOneWidget);
}

// ─────────────────────────────────────────────────────────────────────────────
// Suite
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => _storage.clear());

  testWidgets('GameTracker full E2E suite', (tester) async {
    _t = tester;

    // ── Boot ────────────────────────────────────────────────────────────────
    print('[suite] booting...');
    runZonedGuarded(
      () => app.main(),
      (e, st) => print('[suite] boot error: $e\n$st'),
    );
    await _t.pump(const Duration(milliseconds: 500));
    await _t.pumpAndSettle(_kBoot);
    expect(find.byKey(_kFabAddGame), findsOneWidget,
        reason: 'Expected GamesScreen after boot');
    print('[suite] ready');

    // S1 ─ Home screen structure ─────────────────────────────────────────────
    print('\n[S1] Home screen structure');
    expect(find.byKey(_kFabAddGame), findsOneWidget);
    expect(find.byKey(_kNavPlayers), findsOneWidget);
    print('[S1] ✓');

    // S2 ─ Create a Points game ──────────────────────────────────────────────
    print('\n[S2] Create Points game');
    await _reset();
    await _addGame('Catan');
    print('[S2] ✓');

    // S3 ─ Create a Duel game ────────────────────────────────────────────────
    print('\n[S3] Create Duel game');
    await _reset();
    await _addGame('Échecs', mode: 'duel');
    print('[S3] ✓');

    // S4 ─ Edit a game name ──────────────────────────────────────────────────
    print('\n[S4] Edit game name');
    await _reset();
    await _addGame('Ticket to Ride');
    // Open detail, then edit.
    await _tap(find.text('Ticket to Ride'));
    await _t.tap(find.byKey(_kBtnEditGame));
    await _t.pump(const Duration(milliseconds: 500));
    // Focus the name field and replace its text using showKeyboard +
    // testTextInput. This bypasses enterText's TextFormField routing issues
    // and sets the underlying EditableText / TextEditingController directly.
    await _t.tap(find.byKey(_kFieldGameName));
    await _t.pump(const Duration(milliseconds: 200));
    await _t.showKeyboard(find.byKey(_kFieldGameName));
    _t.testTextInput.updateEditingValue(const TextEditingValue(
      text: 'Ticket to Ride Legacy',
      selection: TextSelection.collapsed(offset: 21),
    ));
    await _t.pump(const Duration(milliseconds: 300));
    _t.binding.focusManager.primaryFocus?.unfocus();
    await _t.pump(const Duration(milliseconds: 200));
    // Tap submit and wait for save + pop chain to complete.
    // NOTE: previously this was guarded by `if (_t.any(find.byKey(_kBtnSubmitGame)))`
    // without first scrolling it into view. Since the button lives inside a
    // scrollable ListView, `_t.any` can return false when it's offstage,
    // which silently skipped the save entirely. `_tapUntil` already waits
    // for the finder to appear, so just scroll-and-tap unconditionally.
    await _scrollIntoViewIfNeeded(find.byKey(_kBtnSubmitGame));
    await _tapUntil(
      find.byKey(_kBtnSubmitGame),
      find.text('Ticket to Ride Legacy'),
    );
    await _backToRoot();
    // Poll for renamed game in list (notifyListeners may lag a few frames).
    final d = DateTime.now().add(_kSettle);
    while (!_t.any(find.text('Ticket to Ride Legacy'))) {
      if (DateTime.now().isAfter(d)) {
        break;
      }
      await _t.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Ticket to Ride Legacy'), findsOneWidget);
    print('[S4] ✓');

    // S5 ─ Delete a game ─────────────────────────────────────────────────────
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

    // S6 ─ Add a player ──────────────────────────────────────────────────────
    print('\n[S6] Add player');
    await _reset();
    await _tap(find.byKey(_kNavPlayers));
    await _addPlayer('Alice');
    print('[S6] ✓');

    // S7 ─ Delete a player ───────────────────────────────────────────────────
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

    // S8 ─ Record a Points session ───────────────────────────────────────────
    print('\n[S8] Record Points session');
    await _reset();
    await _tap(find.byKey(_kNavPlayers));
    await _addPlayer('Alice');
    await _addPlayer('Bob');
    await _backToRoot();
    await _addGame('Catan Pts');
    await _tap(find.text('Catan Pts'));
    await _t.tap(find.byType(FloatingActionButton).first);
    await _t.pump(const Duration(milliseconds: 500));
    await _t.tap(find.text('Alice').first);
    await _t.pump(const Duration(milliseconds: 300));
    await _t.tap(find.text('Bob').first);
    await _t.pump(const Duration(milliseconds: 300));
    final scoreFields = find.byType(TextField);
    await _t.enterText(scoreFields.first, '120');
    await _t.pump(const Duration(milliseconds: 200));
    await _t.enterText(scoreFields.at(1), '85');
    await _t.pump(const Duration(milliseconds: 200));
    await _dismissKb();
    // Scroll to save button only when not already visible — mirrors the
    // same guard used for btnSubmitGame in _addGame, needed here because
    // the save button can be pushed below the fold too, especially in
    // duel mode where each player's row (avatar + win/draw/loss buttons)
    // is visually taller than a points-mode single-line score field.
    await _scrollIntoViewIfNeeded(find.byKey(_kBtnSaveSession));
    await _tapUntil(find.byKey(_kBtnSaveSession), find.text('Catan Pts'));
    expect(find.text('Catan Pts'), findsOneWidget);
    print('[S8] ✓');

    // S9 ─ Record a Duel session ─────────────────────────────────────────────
    print('\n[S9] Record Duel session');
    await _reset();
    await _tap(find.byKey(_kNavPlayers));
    await _addPlayer('Alice');
    await _addPlayer('Bob');
    await _backToRoot();
    await _addGame('Échecs Duel', mode: 'duel');
    await _tap(find.text('Échecs Duel'));
    await _t.tap(find.byType(FloatingActionButton).first);
    await _t.pump(const Duration(milliseconds: 500));
    await _t.tap(find.text('Alice').first);
    await _t.pump(const Duration(milliseconds: 300));
    await _t.tap(find.text('Bob').first);
    await _t.pump(const Duration(milliseconds: 300));
    await _t.tap(find.text('🏆').first);
    await _t.pump(const Duration(milliseconds: 300));
    await _scrollIntoViewIfNeeded(find.byKey(_kBtnSaveSession));
    await _tapUntil(find.byKey(_kBtnSaveSession), find.text('Échecs Duel'));
    expect(find.text('Échecs Duel'), findsOneWidget);
    print('[S9] ✓');

    // S10 ─ Search ───────────────────────────────────────────────────────────
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

    // S11 ─ Stats paywall ────────────────────────────────────────────────────
    print('\n[S11] Stats paywall');
    await _reset();
    // StatsScreen checks `state.games.isEmpty` BEFORE checking
    // `canUseAdvancedStats` — with zero games it renders a plain empty
    // state (no unlock button at all), not the paywall. Need at least one
    // game for the paywall branch to be reachable.
    await _addGame('StatsPaywallGame');
    expect(find.byKey(_kNavStats), findsOneWidget);
    await _t.tap(find.byKey(_kNavStats));
    await _t.pumpAndSettle(_kSettle);
    expect(find.byKey(const Key('btnUnlockStatsWithAd')), findsOneWidget);
    await _backToRoot();
    print('[S11] ✓');

    // S12 ─ Groups paywall ───────────────────────────────────────────────────
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
