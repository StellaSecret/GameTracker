// mock_data_generator.dart builds the demo dataset. Assertions are structural
// only, so the tests are deterministic (no dependence on the relative
// timestamps the generator computes from DateTime.now()).
// Run with: flutter test test/mock_data_generator_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:game_tracker/models/game_mode.dart';
import 'package:game_tracker/services/mock_data_generator.dart';

void main() {
  test('generates 4 games, 4 players and 9 sessions', () {
    final data = MockDataGenerator.generate();
    expect(data.games, hasLength(4));
    expect(data.players, hasLength(4));
    expect(data.players.map((p) => p.id), ['p1', 'p2', 'p3', 'p4']);
    final sessionCount =
        data.games.fold<int>(0, (total, g) => total + g.sessions.length);
    expect(sessionCount, 9);
  });

  test('generates three points games and one duel', () {
    final data = MockDataGenerator.generate();
    expect(data.games.where((g) => g.mode == GameMode.points), hasLength(3));
    expect(data.games.where((g) => g.mode == GameMode.duel), hasLength(1));
  });

  test('flags g3 as the only lowest-score-wins game', () {
    final data = MockDataGenerator.generate();
    final g3 = data.games.singleWhere((g) => g.id == 'g3');
    expect(g3.lowestScoreWins, isTrue);
    expect(data.games.where((g) => g.lowestScoreWins), hasLength(1));
  });

  test('every session carries valid scores in the past', () {
    final data = MockDataGenerator.generate();
    final now = DateTime.now();
    var sessionCount = 0;
    for (final g in data.games) {
      for (final s in g.sessions) {
        // Duration-literal mutants (e.g. days: 3 → days: -3) shift the
        // timestamp into the future, so this assertion kills them.
        expect(
          s.playedAt.isBefore(now),
          isTrue,
          reason: '${s.id} playedAt must be in the past',
        );

        // Negating a positive score literal (e.g. 10 → -10) is caught here.
        expect(
          s.scores.values.every((v) => v >= 0),
          isTrue,
          reason: '${s.id} must not have negative scores',
        );

        if (g.mode == GameMode.duel) {
          expect(s.scores, hasLength(2));
        } else {
          expect(s.scores, hasLength(4));
        }
        sessionCount++;
      }
    }
    expect(sessionCount, 9);
  });
}