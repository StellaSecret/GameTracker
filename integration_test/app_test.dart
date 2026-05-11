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

  /// Waits for the loading spinner to disappear, then settles all animations.
  Future<void> waitReady(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  /// Enters [text] into the first TextField that currently has focus,
  /// or into the TextField that has [hint] as its hintText.
  Future<void> enterText(
    WidgetTester tester,
    String text, {
    String? hint,
  }) async {
    final finder = hint != null
        ? find.widgetWithText(TextField, hint)
        : find.byType(TextField).first;
    await tester.tap(finder.first);
    await tester.pumpAndSettle();
    await tester.enterText(finder.first, text);
    await tester.pumpAndSettle();
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

      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.text('Catan'), findsOneWidget);
    });

    testWidgets('creates a Duel game', (tester) async {
      app.main();
      await waitReady(tester);

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      await enterText(tester, 'Échecs', hint: 'Nom du jeu');

      await tester.tap(find.text('Duel'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.text('Échecs'), findsOneWidget);
    });

    testWidgets('edits an existing game name', (tester) async {
      app.main();
      await waitReady(tester);

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      await enterText(tester, 'Ticket to Ride', hint: 'Nom du jeu');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ticket to Ride'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_rounded));
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextField, 'Ticket to Ride');
      await tester.tap(nameField);
      await tester.pumpAndSettle();
      await tester.enterText(nameField, 'Ticket to Ride Legacy');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

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
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

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

      await tester.tap(find.text('Ajouter'));
      await tester.pumpAndSettle();

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
      await tester.tap(find.text('Ajouter'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Bob'), findsNothing);
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
        await tester.tap(find.text('Ajouter'));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      await enterText(tester, gameName, hint: 'Nom du jeu');
      if (mode != GameMode.points) {
        await tester.tap(
          find.text(mode == GameMode.duel ? 'Duel' : 'Classement'),
        );
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
    }

    testWidgets('records a Points session with two players', (tester) async {
      await setupGameAndPlayers(tester);

      await tester.tap(find.text('Catan'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();

      final scoreFields = find.byType(TextField);
      await tester.enterText(scoreFields.first, '120');
      await tester.pumpAndSettle();
      await tester.enterText(scoreFields.at(1), '85');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Alice'), findsWidgets);
    });

    testWidgets('records a Duel session', (tester) async {
      await setupGameAndPlayers(
        tester,
        gameName: 'Échecs',
        mode: GameMode.duel,
      );

      await tester.tap(find.text('Échecs'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Victoire').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Alice'), findsWidgets);
    });
  });

  // ── Search ────────────────────────────────────────────────────────────────

  group('Search', () {
    testWidgets('filters games by name', (tester) async {
      app.main();
      await waitReady(tester);

      for (final name in ['Catan', 'Pandemic']) {
        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.pumpAndSettle();
        await enterText(tester, name, hint: 'Nom du jeu');
        await tester.tap(find.text('Enregistrer'));
        await tester.pumpAndSettle();
      }

      await enterText(tester, 'Cat', hint: 'Rechercher un jeu…');

      expect(find.text('Catan'), findsOneWidget);
      expect(find.text('Pandemic'), findsNothing);
    });
  });
}

// Local alias so the helper can reference GameMode without a relative import
// (integration_test lives outside lib/).
enum GameMode { points, duel, ranking }
