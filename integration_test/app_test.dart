// integration_test/app_test.dart
//
// End-to-end tests for GameTracker.
//
// Locale-independence strategy
// ────────────────────────────
// Tests NEVER rely on translated text (find.text / find.textContaining) to
// drive interactions. All interactive widgets have been assigned semantic Keys
// (see the Key('...') annotations added throughout the screens). Assertions
// may still use find.byType or structural checks that are locale-agnostic.
//
// The test suite is therefore valid in both 'en' and 'fr' locales, and will
// continue to work when new languages are added.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_tracker/main.dart' as app;
import 'package:game_tracker/screens/paywall_screen.dart';
import 'package:game_tracker/services/storage_service.dart';
import 'package:integration_test/integration_test.dart';

// ── Widget Keys (must match assignments in the screen files) ──────────────────
//
// games_screen.dart
const _kFabAddGame    = Key('fabAddGame');
const _kNavPlayers    = Key('navPlayers');
// add_game_screen.dart
const _kFieldGameName = Key('fieldGameName');
const _kBtnSubmitGame = ValueKey('btnSubmitGame');
const _kBtnDeleteGame = Key('btnDeleteGame');
// players_screen.dart
const _kFabAddPlayer     = Key('fabAddPlayer');
const _kFieldPlayerName  = Key('fieldPlayerName');
const _kBtnSubmitPlayer  = Key('btnSubmitPlayer');
const _kBtnDeletePlayer  = Key('btnDeletePlayer');
// game_detail_screen.dart
const _kBtnEditGame      = Key('btnEditGame');
// add_session_screen.dart
const _kBtnSaveSession = ValueKey('btnSaveSession');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await StorageService().clear();
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Dismisses any open AlertDialog by tapping outside it.
  Future<void> dismissStaleDialog(WidgetTester tester) async {
    if (tester.any(find.byType(AlertDialog))) {
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    }
  }

  /// Waits for the app to settle, dismisses stale dialogs, pops back to root.
  Future<void> waitReady(WidgetTester tester) async {
    await tester.pumpAndSettle();
    // Ensure no keyboard is up.
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    print('waitReady: keyboard dismissed');

    await dismissStaleDialog(tester);
    print('waitReady: stale dialogs dismissed');

    while (tester.any(find.byTooltip('Back'))) {
      print('waitReady: tapping back');
      await tester.tap(find.byTooltip('Back').first);
      await tester.pumpAndSettle();
    }
    print('waitReady: finished');
  }

  /// Unfocuses the active field and ensures keyboard is dismissed.
  Future<void> dismissKeyboard(WidgetTester tester) async {
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  /// Scrolls [finder] into view then taps it.
  Future<void> scrollToAndTap(WidgetTester tester, Finder finder) async {
    // Only scroll if the widget is not already visible.
    if (tester.any(finder) == false) {
      // Find the main vertical scrollable.
      final scrollableFinder = find.byWidgetPredicate(
        (widget) => widget is Scrollable && widget.axis == Axis.vertical,
        skipOffstage: false,
      );

      if (tester.any(scrollableFinder)) {
        await tester.scrollUntilVisible(
          finder,
          500.0,
          scrollable: scrollableFinder.first,
        );
        await tester.pumpAndSettle();
      }
    }

    // Now ensure it is visible and tap it.
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Types [text] into the field identified by [key].
  Future<void> enterTextByKey(
      WidgetTester tester, Key key, String text) async {
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(key), text);
    await tester.pumpAndSettle();
    await dismissKeyboard(tester);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Home screen
  // ─────────────────────────────────────────────────────────────────────────

  group('Home screen', () {
    testWidgets('shows the FAB and nav icons on first launch', (tester) async {
      app.main();
      print('app.main() called'); // Added log
      await waitReady(tester);
      print('waitReady finished'); // Added log

      // The add-game FAB must be present regardless of locale.
      expect(find.byKey(_kFabAddGame), findsOneWidget);
      // The player nav button must be present.
      expect(find.byKey(_kNavPlayers), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Game management
  // ─────────────────────────────────────────────────────────────────────────

  group('Game management', () {
    testWidgets('creates a new Points game and it appears in the list',
        (tester) async {
      app.main();
      await waitReady(tester);

      await tester.tap(find.byKey(_kFabAddGame));
      await tester.pumpAndSettle();

      await enterTextByKey(tester, _kFieldGameName, 'Catan');
      // Points mode is the default — no extra tap needed.
      await scrollToAndTap(tester, find.byKey(_kBtnSubmitGame));

      // The game name should appear in the list.
      expect(find.text('Catan'), findsOneWidget);
    });

    testWidgets('creates a Duel game', (tester) async {
      app.main();
      await waitReady(tester);

      await tester.tap(find.byKey(_kFabAddGame));
      await tester.pumpAndSettle();

      await enterTextByKey(tester, _kFieldGameName, 'Échecs');

      // Tap the Duel mode option — find by its emoji which is locale-independent.
      await scrollToAndTap(tester, find.text('⚔️'));

      await scrollToAndTap(tester, find.byKey(_kBtnSubmitGame));

      expect(find.text('Échecs'), findsOneWidget);
    });

    testWidgets('edits an existing game name', (tester) async {
      app.main();
      await waitReady(tester);

      // Create a game to edit.
      await tester.tap(find.byKey(_kFabAddGame));
      await tester.pumpAndSettle();
      await enterTextByKey(tester, _kFieldGameName, 'Ticket to Ride');
      await scrollToAndTap(tester, find.byKey(_kBtnSubmitGame));

      // Open it.
      await tester.tap(find.text('Ticket to Ride'));
      await tester.pumpAndSettle();

      // Tap the edit button in the game detail app bar.
      await tester.tap(find.byKey(_kBtnEditGame));
      await tester.pumpAndSettle();

      // Find the name field by key and update it.
      await enterTextByKey(
          tester, _kFieldGameName, 'Ticket to Ride Legacy');

      await scrollToAndTap(tester, find.byKey(_kBtnSubmitGame));

      // Pop back to list.
      if (tester.any(find.byTooltip('Back'))) {
        await tester.tap(find.byTooltip('Back').first);
        await tester.pumpAndSettle();
      }

      expect(find.text('Ticket to Ride Legacy'), findsOneWidget);
    });

    testWidgets('deletes a game', (tester) async {
      app.main();
      await waitReady(tester);

      await tester.tap(find.byKey(_kFabAddGame));
      await tester.pumpAndSettle();
      await enterTextByKey(tester, _kFieldGameName, 'ToDelete');
      await scrollToAndTap(tester, find.byKey(_kBtnSubmitGame));

      // Open → edit → delete.
      await tester.tap(find.text('ToDelete'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_kBtnEditGame));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_kBtnDeleteGame));
      await tester.pumpAndSettle();

      // Confirm the AlertDialog — tap the last elevated/text button.
      // We look for an ElevatedButton or TextButton containing the delete icon
      // logic; since we can't use translated text, we tap the second action
      // button in the dialog (Cancel is first, Delete is second).
      final dialogActions =
          find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextButton));
      if (tester.any(dialogActions)) {
        await tester.tap(dialogActions.last);
        await tester.pumpAndSettle();
      }

      expect(find.text('ToDelete'), findsNothing);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Player management
  // ─────────────────────────────────────────────────────────────────────────

  group('Player management', () {
    testWidgets('navigates to Players screen and adds a player',
        (tester) async {
      app.main();
      await waitReady(tester);

      await tester.tap(find.byKey(_kNavPlayers));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(_kFabAddPlayer));
      await tester.pumpAndSettle();

      await enterTextByKey(tester, _kFieldPlayerName, 'Alice');
      await scrollToAndTap(tester, find.byKey(_kBtnSubmitPlayer));

      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('deletes a player', (tester) async {
      app.main();
      await waitReady(tester);

      await tester.tap(find.byKey(_kNavPlayers));
      await tester.pumpAndSettle();

      // Add Bob first.
      await tester.tap(find.byKey(_kFabAddPlayer));
      await tester.pumpAndSettle();
      await enterTextByKey(tester, _kFieldPlayerName, 'Bob');
      await scrollToAndTap(tester, find.byKey(_kBtnSubmitPlayer));

      // Open edit sheet for Bob.
      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();

      // Tap delete in the sheet.
      await tester.tap(find.byKey(_kBtnDeletePlayer));
      await tester.pumpAndSettle();

      // Confirm the dialog — last TextButton = confirm.
      final dialogActions = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextButton));
      if (tester.any(dialogActions)) {
        await tester.tap(dialogActions.last);
        await tester.pumpAndSettle();
      }

      // Bob should no longer appear in the list.
      expect(
        find.descendant(
            of: find.byType(ListView), matching: find.text('Bob')),
        findsNothing,
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Session recording
  // ─────────────────────────────────────────────────────────────────────────

  group('Session recording', () {
    /// Creates two players and one game, leaves the app at the game detail screen.
    Future<void> setupGameAndPlayers(
      WidgetTester tester, {
      String gameName = 'Catan Session',
      bool duel = false,
    }) async {
      app.main();
      await waitReady(tester);

      // Create players.
      await tester.tap(find.byKey(_kNavPlayers));
      await tester.pumpAndSettle();

      for (final name in ['Alice', 'Bob']) {
        await tester.tap(find.byKey(_kFabAddPlayer));
        await tester.pumpAndSettle();
        await enterTextByKey(tester, _kFieldPlayerName, name);
        await scrollToAndTap(tester, find.byKey(_kBtnSubmitPlayer));
      }

      // Back to games.
      await tester.tap(find.byTooltip('Back').first);
      await tester.pumpAndSettle();

      // Create game.
      await tester.tap(find.byKey(_kFabAddGame));
      await tester.pumpAndSettle();
      await enterTextByKey(tester, _kFieldGameName, gameName);
      if (duel) {
        await scrollToAndTap(tester, find.text('⚔️'));
      }
      await scrollToAndTap(tester, find.byKey(_kBtnSubmitGame));
    }

    testWidgets('records a Points session with two players', (tester) async {
      await setupGameAndPlayers(tester, gameName: 'Catan Pts');

      await tester.tap(find.text('Catan Pts'));
      await tester.pumpAndSettle();

      // Open new-session screen via FAB.
      await tester.tap(find.byType(FloatingActionButton).first);
      await tester.pumpAndSettle();

      // Select Alice and Bob via FilterChip.
      await tester.tap(find.text('Alice').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bob').first);
      await tester.pumpAndSettle();

      // Enter scores in the numeric fields.
      final scoreFields = find.byType(TextField);
      await tester.enterText(scoreFields.first, '120');
      await tester.pumpAndSettle();
      await tester.enterText(scoreFields.at(1), '85');
      await tester.pumpAndSettle();
      await dismissKeyboard(tester);

      await scrollToAndTap(tester, find.byKey(_kBtnSaveSession));

      // Session was saved — we're back at the game detail screen.
      expect(find.text('Catan Pts'), findsOneWidget);
    });

    testWidgets('records a Duel session', (tester) async {
      await setupGameAndPlayers(
          tester, gameName: 'Échecs Duel', duel: true);

      await tester.tap(find.text('Échecs Duel'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton).first);
      await tester.pumpAndSettle();

      // Select both players.
      await tester.tap(find.text('Alice').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bob').first);
      await tester.pumpAndSettle();

      // Pick the 🏆 win button for Alice (first _DuelButton with that emoji).
      await tester.tap(find.text('🏆').first);
      await tester.pumpAndSettle();

      await scrollToAndTap(tester, find.byKey(_kBtnSaveSession));

      expect(find.text('Échecs Duel'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Search
  // ─────────────────────────────────────────────────────────────────────────

  group('Search', () {
    testWidgets('filters games by name regardless of locale', (tester) async {
      app.main();
      await waitReady(tester);

      // Create two distinctly-named games so this test is self-contained.
      for (final name in ['SearchGame Alpha', 'SearchGame Beta']) {
        await tester.tap(find.byKey(_kFabAddGame));
        await tester.pumpAndSettle();
        await enterTextByKey(tester, _kFieldGameName, name);
        await scrollToAndTap(tester, find.byKey(_kBtnSubmitGame));
        await waitReady(tester);
      }

      // Find the search TextField by type — there is only one on the home screen.
      final searchField = find.byType(TextField).first;

      await tester.enterText(searchField, 'Alpha');
      await tester.pumpAndSettle();
      expect(find.textContaining('Alpha'), findsWidgets);
      expect(find.text('SearchGame Beta'), findsNothing);

      await tester.enterText(searchField, 'Beta');
      await tester.pumpAndSettle();
      expect(find.textContaining('Beta'), findsWidgets);
      expect(find.text('SearchGame Alpha'), findsNothing);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Paywall Gating
  // ─────────────────────────────────────────────────────────────────────────

  group('Paywall Gating', () {
    testWidgets('shows unlock UI when clicking stats without entitlement',
        (tester) async {
      app.main();
      await waitReady(tester);

      // Verify we are on the games list / home screen.
      expect(find.byKey(const Key('navStats')), findsOneWidget);

      // Tap stats icon.
      await tester.tap(find.byKey(const Key('navStats')));
      await tester.pumpAndSettle();

      // We should be on the stats screen, but locked.
      expect(find.byKey(const Key('btnUnlockStatsWithAd')), findsOneWidget);
    });

    testWidgets('redirects to Group Sync paywall when clicking groups without entitlement',
        (tester) async {
      app.main();
      await waitReady(tester);

      // Verify we are on the games list / home screen.
      expect(find.byKey(const Key('navGroups')), findsOneWidget);

      // Tap groups icon.
      await tester.tap(find.byKey(const Key('navGroups')));
      await tester.pumpAndSettle();

      // We should be on the paywall screen.
      expect(find.byType(PaywallScreen), findsOneWidget);

      // Verify it's the group sync paywall.
      final paywall = tester.widget<PaywallScreen>(find.byType(PaywallScreen));
      expect(paywall.target, PaywallTarget.groupSync);
    });
  });
}
