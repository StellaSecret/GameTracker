// integration_test/helpers.dart
//
// Shared boot sequence, widget keys, timeouts, and interaction helpers for
// GameTracker's E2E integration tests.
//
// Architecture: single-boot, multi-scenario, sharded across CI jobs
// ───────────────────────────────────────────────────────────────────
// The app boots ONCE per test *file* (not per scenario). Each scenario
// resets state by clearing StorageService and navigating back to root,
// eliminating ~25s of cold-init overhead per scenario.
//
// To keep CI wall-clock time down, the full scenario list is split across
// two files (app_test_part1.dart / app_test_part2.dart) that each import
// this file and run independently on their own emulator in a CI matrix —
// see .github/workflows/build.yml. Every identifier here is intentionally
// public (no leading underscore) so both part files can use it; this file
// has no `main()` of its own and isn't a test target by itself.
//
// Performance notes
// ─────────────────
// • scrollUntilVisible is only called when the target isn't already visible
//   AND the scrollable actually has overflow. When range==0, attempting to
//   scroll causes repeated failed drag attempts (~2s per addGame call).
// • pumpAndSettle is avoided after taps that trigger notifyListeners() chains
//   (_persist → group push). We use tapUntil or fixed-duration pump() instead.
// • Session form interactions use pump(300ms) not pumpAndSettle — chip taps
//   and text entry are synchronous; no need to wait for full frame drain.

// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_tracker/main.dart' as app;
import 'package:game_tracker/services/app_state.dart';
import 'package:game_tracker/services/storage_service.dart';
import 'package:provider/provider.dart';

// ── Widget Keys ───────────────────────────────────────────────────────────────
const kFabAddGame     = Key('fabAddGame');
const kNavPlayers     = Key('navPlayers');
const kNavStats       = Key('navStats');
const kNavGroups      = Key('navGroups');
const kFieldGameName  = Key('fieldGameName');
const kBtnSubmitGame  = ValueKey('btnSubmitGame');
const kBtnDeleteGame  = Key('btnDeleteGame');
const kFabAddPlayer   = Key('fabAddPlayer');
const kFieldPlayerName = Key('fieldPlayerName');
const kBtnSubmitPlayer = Key('btnSubmitPlayer');
const kBtnDeletePlayer = Key('btnDeletePlayer');
const kBtnEditGame    = Key('btnEditGame');
const kBtnSaveSession = ValueKey('btnSaveSession');

// ── Timeouts ──────────────────────────────────────────────────────────────────
const kSettle = Duration(seconds: 15);
const kBoot   = Duration(seconds: 30);

// ── Globals ───────────────────────────────────────────────────────────────────
late WidgetTester t;
final storage = StorageService();

// ─────────────────────────────────────────────────────────────────────────────
// Boot helper
// ─────────────────────────────────────────────────────────────────────────────

/// Boots the app once for this test file's WidgetTester and waits for the
/// GamesScreen (root) to appear. Call this at the top of each part file's
/// single testWidgets() body, before running any scenarios.
Future<void> bootApp(WidgetTester tester) async {
  t = tester;
  print('[suite] booting...');
  runZonedGuarded(
    () => app.main(),
    (e, st) => print('[suite] boot error: $e\n$st'),
  );
  await t.pump(const Duration(milliseconds: 500));
  await t.pumpAndSettle(kBoot);
  expect(find.byKey(kFabAddGame), findsOneWidget,
      reason: 'Expected GamesScreen after boot');
  print('[suite] ready');
}

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
Element? mainVerticalScrollableElement() {
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
Future<void> scrollIntoViewIfNeeded(Finder finder) async {
  if (t.any(finder)) {
    return; // already visible, nothing to do
  }

  final element = mainVerticalScrollableElement();
  if (element == null) {
    return; // nothing has real overflow — content fits, or truly not found
  }

  final scrollable = find.byElementPredicate((e) => e == element);
  await t.scrollUntilVisible(finder, 300, scrollable: scrollable);
  await t.pump(const Duration(milliseconds: 150));
}

// ─────────────────────────────────────────────────────────────────────────────
// Core interaction helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Tap [finder] after optionally scrolling into view. Settles fully.
Future<void> tap(Finder finder) async {
  await scrollIntoViewIfNeeded(finder);
  if (t.any(finder)) {
    await t.ensureVisible(finder);
  }
  await t.tap(finder);
  await t.pumpAndSettle(kSettle);
}

/// Dumps diagnostic info to the test log right before we give up waiting
/// on [finder]. Generic over whatever finder is actually stuck — an
/// earlier version of this hardcoded checks for kBtnSubmitGame, which
/// gave misleading results when the actual stuck call was waiting on a
/// different widget (e.g. btnSaveSession on the session-recording screen).
void dumpDiagnostics(String label, Finder finder) {
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
    final view = t.binding.platformDispatcher.views.first;
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

/// Tap [finder] then pump frames until [until] is visible (max [kSettle]).
/// Use instead of tap when the action triggers async persistence +
/// notifyListeners() chains that would cause pumpAndSettle to spin for minutes.
Future<void> tapUntil(Finder finder, Finder until) async {
  // Wait for finder to be present (it may need a frame or two to appear).
  final appearDeadline = DateTime.now().add(kSettle);
  while (!t.any(finder)) {
    if (DateTime.now().isAfter(appearDeadline)) {
      dumpDiagnostics('finder never appeared', finder);
      throw Exception(
        'tapUntil: finder never appeared: '
        '${finder.describeMatch(Plurality.one)}',
      );
    }
    await t.pump(const Duration(milliseconds: 100));
  }
  await scrollIntoViewIfNeeded(finder);
  if (t.any(finder)) {
    await t.ensureVisible(finder);
  }
  await t.tap(finder);
  final deadline = DateTime.now().add(kSettle);
  while (!t.any(until)) {
    if (DateTime.now().isAfter(deadline)) {
      dumpDiagnostics('until never appeared after tap', until);
      throw Exception(
        'tapUntil timed out waiting for '
        '${until.describeMatch(Plurality.one)}',
      );
    }
    await t.pump(const Duration(milliseconds: 100));
  }
  // The tap above often triggers Navigator.pop, which starts a page
  // transition. During that transition BOTH routes are briefly mounted:
  // the outgoing form (e.g. its EditableText still showing the typed
  // value, which is finder's own screen) and the revealed screen
  // underneath (e.g. a list Text with the same string, until). find.text
  // matches Text and EditableText alike, so until can transiently match
  // more than once right as it first appears.
  //
  // We need to wait until there is NO duplicate. Previously this used
  // t.any(finder) && duplicateExists, an AND — which is wrong: it exits
  // the instant EITHER condition flips, including the moment finder (the
  // submit button) disappears even if the duplicate is still there (the
  // button's route can finish popping slightly before the orphaned
  // EditableText itself unmounts). That let a real duplicate slip through
  // to the caller's findsOneWidget check. The only thing that actually
  // matters is "is there still a duplicate" — check that alone.
  final settleDeadline = DateTime.now().add(kSettle);
  // Require a run of consecutive "no duplicate" reads, not just one.
  // A single instantaneous check right after the tap can read count==1
  // truthfully — simply because the async persist -> notifyListeners()
  // -> Navigator.pop() -> transition chain hasn't started yet, so the
  // transient duplicate (finder's own outgoing route + until's revealed
  // widget, both matching the same text) hasn't appeared *yet* either.
  // That let a real duplicate slip through moments later, right as the
  // caller's own findsOneWidget check ran with no further pumping to
  // catch it. Bridging past that requires demonstrating stability over
  // a real span of time, not a single lucky sample.
  var stableReads = 0;
  while (stableReads < 4) {
    await t.pump(const Duration(milliseconds: 100));
    stableReads = t.widgetList(until).length <= 1 ? stableReads + 1 : 0;
    if (DateTime.now().isAfter(settleDeadline)) {
      break;
    }
  }
}

/// Enter text into [key] field and dismiss keyboard.
/// Uses showKeyboard + updateEditingValue to bypass TextFormField routing
/// issues with enterText — ensures text reaches the TextEditingController.
Future<void> enterField(Key key, String text) async {
  await t.tap(find.byKey(key));
  await t.pump(const Duration(milliseconds: 200));
  await t.showKeyboard(find.byKey(key));
  t.testTextInput.updateEditingValue(TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  ));
  await t.pump(const Duration(milliseconds: 200));
  t.binding.focusManager.primaryFocus?.unfocus();
  await t.pump(const Duration(milliseconds: 300));
}

/// Dismiss keyboard without settling.
Future<void> dismissKb() async {
  t.binding.focusManager.primaryFocus?.unfocus();
  await t.testTextInput.receiveAction(TextInputAction.done);
  await t.pump(const Duration(milliseconds: 200));
}

/// Pop back to GamesScreen root.
Future<void> backToRoot() async {
  t.binding.focusManager.primaryFocus?.unfocus();
  await t.pump(const Duration(milliseconds: 200));
  while (t.any(find.byTooltip('Back'))) {
    await t.tap(find.byTooltip('Back').first);
    final deadline = DateTime.now().add(kSettle);
    while (t.any(find.byTooltip('Back'))) {
      if (DateTime.now().isAfter(deadline)) {
        break;
      }
      await t.pump(const Duration(milliseconds: 100));
    }
  }
  if (t.any(find.byType(AlertDialog))) {
    await t.tapAt(const Offset(10, 10));
    await t.pump(const Duration(milliseconds: 300));
  }
  await t.pump(const Duration(milliseconds: 300));
}

/// Clear storage, re-initialise AppState in-memory, and return to root.
/// StorageService.clear() only wipes SharedPreferences — it does NOT call
/// notifyListeners() on AppState. Without re-init, the widget tree keeps
/// stale games/players in memory and tapUntil can't find newly added items.
Future<void> reset() async {
  await backToRoot();
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
  await t.pump(const Duration(milliseconds: 200));
  t.binding.focusManager.primaryFocus?.unfocus();
  await t.pump(const Duration(milliseconds: 200));
  await storage.clear();
  // Re-load AppState from now-empty storage so in-memory data is cleared.
  final state = Provider.of<AppState>(
    t.element(find.byType(MaterialApp).first),
    listen: false,
  );
  await state.init();
  await t.pump(const Duration(milliseconds: 200));
}

/// Confirm the destructive action in an AlertDialog (last TextButton).
Future<void> confirmDialog() async {
  final actions = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(TextButton),
  );
  if (t.any(actions)) {
    await t.tap(actions.last);
    await t.pumpAndSettle(kSettle);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Domain helpers
// ─────────────────────────────────────────────────────────────────────────────

Future<void> addGame(String name, {String mode = 'points'}) async {
  await tap(find.byKey(kFabAddGame));
  await enterField(kFieldGameName, name);
  if (mode == 'duel') {
    await tap(find.text('⚔️'));
  }
  if (mode == 'ranking') {
    await tap(find.text('🏆'));
  }
  // Scroll to submit only when not already visible (form fits viewport on
  // most runs, but guard against tall content on some display configs).
  await scrollIntoViewIfNeeded(find.byKey(kBtnSubmitGame));
  // tapUntil: avoids pumpAndSettle spinning on _persist → notifyListeners().
  await tapUntil(find.byKey(kBtnSubmitGame), find.text(name));
  final matches = find.text(name).evaluate().length;
  if (matches != 1) {
    // This expect() doesn't go through tapUntil, so the usual diagnostics
    // never fire for it — dump the same info here so a "Found 0" failure
    // (game apparently not visible at all: filtered out by leftover search
    // text? not actually saved? on the wrong screen?) is diagnosed from
    // evidence next time instead of guessed at again.
    debugPrint(
      '--- DIAGNOSTICS: addGame final text check (found $matches, want 1) ---',
    );
    try {
      final searchFields = find.byType(TextField).evaluate().toList();
      debugPrint('TextField count: ${searchFields.length}');
      for (final e in searchFields) {
        final editable = find.descendant(
          of: find.byWidget(e.widget),
          matching: find.byType(EditableText),
        );
        final text = t.any(editable)
            ? (t.widget(editable.first) as EditableText).controller.text
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

Future<void> addPlayer(String name) async {
  await tap(find.byKey(kFabAddPlayer));
  await enterField(kFieldPlayerName, name);
  await tapUntil(find.byKey(kBtnSubmitPlayer), find.text(name));
  expect(find.text(name), findsOneWidget);
}
