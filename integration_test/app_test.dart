// integration_test/app_test.dart
//
// End-to-end tests for GameTracker.
// Run locally  : flutter test integration_test/app_test.dart -d <device-id>
// Run on CI    : see .github/workflows/e2e.yml
//
// Strategy
// ────────
// • We boot the real app but replace external services (Firebase, Drive,
//   purchases) by doing nothing – they are guarded by kIsWeb / try-catch
//   in AppState.init() already, so on a plain Android emulator they simply
//   no-op without crashing.
// • SharedPreferences starts empty on a fresh emulator, so every run begins
//   from a clean slate – no fixtures needed.
// • We find widgets by their visible text / tooltip / icon; this mirrors what
//   a real user sees and survives minor refactors better than key-based lookup.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_tracker/main.dart' as app;
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Waits for the app to settle, then pops all routes back to the root screen.
  /// This is necessary because the emulator is shared across all tests and may
  /// be left on a detail/edit screen by the previous test.
  Future<void> waitReady(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 5));
    // Pop any lingering routes (edit screens, dialogs, detail pages) back to root.
    while (tester.any(find.byTooltip('Back'))) {
      await tester.tap(find.byTooltip('Back').first);
      await tester.pumpAndSettle();
    }
  }

  /// Dismisses the software keyboard without any tap side-effects.
  /// Uses FocusManager to unfocus the active field — safe inside bottom sheets,
  /// dialogs, and full-screen forms where tapping the AppBar would navigate away.
  Future<void> dismissKeyboard(WidgetTester tester) async {
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  /// Scrolls [finder] into the visible area then taps it.
  /// Handles buttons pushed below the fold by long forms.
  Future<void> scrollToAndTap(WidgetTester tester, Finder finder) async {
    // ensureVisible requires exactly one element — guard against 0 or 2+.
    if (!tester.any(finder)) {
      throw TestFailure('scrollToAndTap: no widget found for $finder');
    }
    await tester.ensureVisible(finder.first);
    await tester.pumpAndSettle();
    await tester.tap(finder.first);
    await tester.pumpAndSettle();
  }

  /// Enters [text] into the TextField that has [hint] as its hintText,
  /// or the first TextField if [hint] is omitted.
  /// Dismisses the keyboard afterwards via FocusManager (no tap side-effects).
  Future<void> enterText(
    WidgetTester tester,
    String text, {
    String? hint,
  }) async {
    // find.widgetWithText(TextField, hint) misses TextFormField because
    // TextFormField renders its own internal TextField — the hint lives on
    // the InputDecoration, not as a Text child.  We match by predicate
    // on the internal TextField's decoration instead.
    final Finder finder;
    if (hint != null) {
      finder = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == hint,
      );
    } else {
      finder = find.byType(TextField).first;
    }
    await tester.tap(finder.first);
    await tester.pumpAndSettle();
    await tester.enterText(finder.first, text);
    await tester.pumpAndSettle();
    await dismissKeyboard(tester);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tests
  // ─────────────────────────────────────────────────────────────────────────

  group('Home screen', () {
    testWidgets('shows app title and empty state on first launch',
        (tester) async {
      app.main();
      await waitReady(tester);

      expect(find.text('🎲 GameTracker'), findsOneWidget);
      expect(find.textContaining('Aucun jeu'), findsOneWidget);
    });
  });

  // ── Game CRUD ─────────────────────────────────────────────────────────────

  group('Game management', () {
    testWidgets('creates a new Points game and shows it in the list',
        (tester) async {
      app.main();
      await waitReady(tester);

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      await enterText(tester, 'Catan', hint: 'Nom du jeu');

      await scrollToAndTap(tester, find.text('Créer le jeu'));

      expect(find.text('Catan'), findsOneWidget);
    });

    testWidgets('creates a Duel game', (tester) async {
      app.main();
      await waitReady(tester);

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      await enterText(tester, 'Échecs', hint: 'Nom du jeu');

      await scrollToAndTap(tester, find.text('Duel'));

      await scrollToAndTap(tester, find.text('Créer le jeu'));

      expect(find.text('Échecs'), findsOneWidget);
    });

    testWidgets('edits an existing game name', (tester) async {
      app.main();
      await waitReady(tester);

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      await enterText(tester, 'Ticket to Ride', hint: 'Nom du jeu');
      await scrollToAndTap(tester, find.text('Créer le jeu'));

      await tester.tap(find.text('Ticket to Ride'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_rounded));
      await tester.pumpAndSettle();

      final nameField = find.byWidgetPredicate(
        (w) => w is EditableText && w.controller.text == 'Ticket to Ride',
      );
      await tester.tap(nameField);
      await tester.pumpAndSettle();
      await tester.enterText(nameField, 'Ticket to Ride Legacy');
      await tester.pumpAndSettle();
      await dismissKeyboard(tester);

      await scrollToAndTap(tester, find.text('Enregistrer'));

      final backButton = find.byTooltip('Back');
      if (tester.any(backButton)) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
      }

      expect(find.text('Ticket to Ride Legacy'), findsOneWidget);
    });

    testWidgets('deletes a game', (tester) async {
      app.main();
      await waitReady(tester);

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      await enterText(tester, 'Jeu à supprimer', hint: 'Nom du jeu');
      await scrollToAndTap(tester, find.text('Créer le jeu'));

      await tester.tap(find.text('Jeu à supprimer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_rounded));
      await tester.pumpAndSettle();

      final confirmFinder = find.text('Supprimer');
      if (tester.any(confirmFinder)) {
        await tester.tap(confirmFinder.last);
        await tester.pumpAndSettle();
      }

      expect(find.text('Jeu à supprimer'), findsNothing);
    });
  });

  // ── Player CRUD ───────────────────────────────────────────────────────────

  group('Player management', () {
    testWidgets('navigates to Players screen and adds a player', (tester) async {
      app.main();
      await waitReady(tester);

      await tester.tap(find.byTooltip('Joueurs'));
      await tester.pumpAndSettle();

      expect(find.text('👥 Joueurs'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.person_add_rounded));
      await tester.pumpAndSettle();

      await enterText(tester, 'Alice', hint: 'Prénom ou pseudo');

      await scrollToAndTap(tester, find.text('Ajouter'));

      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('deletes a player', (tester) async {
      app.main();
      await waitReady(tester);

      await tester.tap(find.byTooltip('Joueurs'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person_add_rounded));
      await tester.pumpAndSettle();
      await enterText(tester, 'Bob', hint: 'Prénom ou pseudo');
      await scrollToAndTap(tester, find.text('Ajouter'));

      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_rounded));
      await tester.pumpAndSettle();

      // Confirm the delete dialog
      await tester.tap(find.text('Supprimer').last);
      await tester.pumpAndSettle();

      // Bob should no longer appear in the player list
      expect(
        find.descendant(
          of: find.byType(ListView),
          matching: find.text('Bob'),
        ),
        findsNothing,
      );
    });
  });

  // ── Session recording ─────────────────────────────────────────────────────

  group('Session recording', () {
    Future<void> setupGameAndPlayers(
      WidgetTester tester, {
      String gameName = 'Catan',
      GameMode mode = GameMode.points,
    }) async {
      app.main();
      await waitReady(tester);

      await tester.tap(find.byTooltip('Joueurs'));
      await tester.pumpAndSettle();

      for (final name in ['Alice', 'Bob']) {
        await tester.tap(find.byIcon(Icons.person_add_rounded));
        await tester.pumpAndSettle();
        await enterText(tester, name, hint: 'Prénom ou pseudo');
        await scrollToAndTap(tester, find.text('Ajouter'));
      }

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      await enterText(tester, gameName, hint: 'Nom du jeu');
      if (mode != GameMode.points) {
        await scrollToAndTap(
          tester,
          find.text(mode == GameMode.duel ? 'Duel' : 'Classement'),
        );
      }
      await scrollToAndTap(tester, find.text('Créer le jeu'));
    }

    testWidgets('records a Points session with two players', (tester) async {
      await setupGameAndPlayers(tester, gameName: 'Catan Session');

      await tester.tap(find.text('Catan Session'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alice').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bob').first);
      await tester.pumpAndSettle();

      final scoreFields = find.byType(TextField);
      await tester.enterText(scoreFields.first, '120');
      await tester.pumpAndSettle();
      await tester.enterText(scoreFields.at(1), '85');
      await tester.pumpAndSettle();
      await dismissKeyboard(tester);

      await scrollToAndTap(tester, find.text('Enregistrer la partie'));

      expect(find.textContaining('Alice'), findsWidgets);
    });

    testWidgets('records a Duel session', (tester) async {
      await setupGameAndPlayers(
        tester,
        gameName: 'Échecs E2E',
        mode: GameMode.duel,
      );

      await tester.tap(find.text('Échecs E2E'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alice').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bob').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Victoire').first);
      await tester.pumpAndSettle();

      await scrollToAndTap(tester, find.text('Enregistrer la partie'));

      expect(find.textContaining('Alice'), findsWidgets);
    });
  });

  // ── Search ────────────────────────────────────────────────────────────────

  group('Search', () {
    testWidgets('filters games by name', (tester) async {
      app.main();
      await waitReady(tester);

      // Don't create new games — prior tests already filled the free-tier limit
      // (5 games). Instead search among the games that already exist:
      // "Catan" and "Catan Session" were created by earlier tests.
      // Searching for "Catan" should show both; "Échecs" should show Échecs games
      // and hide any Catan entries.
      await enterText(tester, 'Catan', hint: 'Rechercher un jeu…');
      expect(find.textContaining('Catan'), findsWidgets);

      // Clear and search for something that matches only non-Catan games
      await enterText(tester, 'Échecs', hint: 'Rechercher un jeu…');
      expect(find.textContaining('Échecs'), findsWidgets);
      expect(find.text('Catan'), findsNothing);
    });
  });
}

// Local alias so the helper can reference GameMode without a relative import
// (integration_test lives outside lib/).
enum GameMode { points, duel, ranking }
