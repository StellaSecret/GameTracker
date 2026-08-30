// Regression tests for the mutants that mutation_test reported as missed in the
// "add mutation testing" CI run (stats_engine, game and app_data survivors).
// Each test kills one or more surviving mutants so the missed list stays empty
// (CI fails otherwise).
// Run with: flutter test test/mutation_regression_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:game_tracker/models/app_data.dart';
import 'package:game_tracker/models/game.dart';
import 'package:game_tracker/models/game_mode.dart';
import 'package:game_tracker/models/game_session.dart';
import 'package:game_tracker/models/stats_engine.dart';

GameSession pts(Map<String, int> scores, {int day = 0}) => GameSession(
      mode: GameMode.points,
      scores: scores,
      playedAt: DateTime(2024, 1, day + 1),
    );

GameSession duel(String winner, String loser, {int day = 0}) => GameSession(
      mode: GameMode.duel,
      scores: {winner: DuelResult.win.index, loser: DuelResult.loss.index},
      playedAt: DateTime(2024, 1, day + 1),
    );

void main() {
  group('mutant regression: stats_engine.dart', () {
    // builtin.if on `if (streakCursor > bestStreak)`: negating it keeps the
    // best streak at 0 (a win never passes `streakCursor > bestStreak`).
    test('bestStreak survives a trailing shorter run', () {
      final g = Game(id: 'g', name: 'G', mode: GameMode.points);
      g.sessions.addAll([
        pts({'alice': 10, 'bob': 5}), // W
        pts({'alice': 11, 'bob': 5}, day: 1), // W
        pts({'alice': 12, 'bob': 5}, day: 2), // W
        pts({'alice': 3, 'bob': 15}, day: 3), // L
        pts({'alice': 10, 'bob': 5}, day: 4), // W
      ]);
      expect(StatsEngine([g]).computePlayerStats('alice').bestStreak, 3);
    });

    // builtin.if on the favorite selection, builtin.op.neq on `favGameId != null`
    // and builtin.op.eq on `g.id == favGameId` all break the resolved name or id.
    test('favorite game is the most won and resolved to its name', () {
      final catan = Game(id: 'catan', name: 'Catan', mode: GameMode.points);
      catan.sessions.addAll([
        pts({'alice': 10, 'bob': 5}),
        pts({'alice': 9, 'bob': 5}, day: 1), // alice wins this one too
      ]);
      final chess = Game(id: 'chess', name: 'Chess', mode: GameMode.points);
      chess.sessions.add(pts({'alice': 4, 'bob': 7})); // alice loses
      final stats = StatsEngine([catan, chess]).computePlayerStats('alice');
      expect(stats.favoriteGameId, 'catan');
      expect(stats.favoriteGameWins, 2);
      expect(stats.favoriteGameName, 'Catan');
    });

    // builtin.op.geq on the nemesis `>= 2` gate: the surviving `>` variant
    // rejects an opponent the player met exactly twice.
    test('nemesis picks the opponent at exactly two games together', () {
      final g = Game(id: 'g', name: 'G', mode: GameMode.duel);
      g.sessions.addAll([
        duel('bob', 'alice'),
        duel('bob', 'alice', day: 1),
      ]);
      final stats = StatsEngine([g]).computePlayerStats('alice');
      expect(stats.nemesisId, 'bob');
      expect(stats.nemesisLosses, 2);
    });

    // builtin.and (&&→||), builtin.if (negated), builtin.logical.and (each
    // operand negated), builtin.if.start/if.end (first/second operand negated)
    // and the `>= 3` → `> 3` variant all break an exactly-three-games rival.
    test('rival picks the most played opponent, keeping the first tie', () {
      final g = Game(id: 'g', name: 'G', mode: GameMode.duel);
      // games together: x=3, y=3, z=2, w=1 (insertion order x,y,z,w)
      g.sessions.addAll([
        duel('x', 'p'),
        duel('x', 'p', day: 1),
        duel('x', 'p', day: 2),
        duel('y', 'p', day: 3),
        duel('y', 'p', day: 4),
        duel('y', 'p', day: 5),
        duel('z', 'p', day: 6),
        duel('z', 'p', day: 7),
        duel('w', 'p', day: 8),
      ]);
      final stats = StatsEngine([g]).computePlayerStats('p');
      expect(stats.rivalId, 'x');
      expect(stats.rivalGames, 3);
    });

    // builtin.op.geq `>= 3` → `== 3`: a single opponent met five times must
    // still qualify (5 == 3 is false, so the mutant drops them entirely).
    test('rival still qualifies with more than three games', () {
      final g = Game(id: 'g', name: 'G', mode: GameMode.duel);
      for (int i = 0; i < 5; i++) {
        g.sessions.add(duel('big', 'p', day: i));
      }
      final stats = StatsEngine([g]).computePlayerStats('p');
      expect(stats.rivalId, 'big');
      expect(stats.rivalGames, 5);
    });

    // builtin.arith.sub on the comparator `b - a` (mutated to `b + a`) makes
    // every comparison positive, so the sort no longer orders descending. Scores
    // are chosen so the descending top-2 gap (90) differs from both an unchanged
    // order (|5-100| = 95) and the mutated sort's output (|10-7| = 3).
    test('tightestGap sorts scores descending', () {
      final g = Game(id: 'g', name: 'G', mode: GameMode.points);
      g.sessions.add(pts({'alice': 5, 'dave': 10, 'carol': 7, 'bob': 100}));
      expect(StatsEngine([g]).computeGameStats('g').tightestGap, 90);
    });

    // builtin.arith.add on the globalWins/h2h counters, builtin.op.eq and
    // builtin.if on `if (loser == winner)`, builtin.if on the nemesis and most
    // active selections: all break ranking, nemesis, rival or most-active.
    test('global stats aggregate ranking, nemesis, rival and most active', () {
      final g = Game(id: 'g', name: 'G', mode: GameMode.duel);
      g.sessions.addAll([
        duel('alice', 'bob'),
        duel('alice', 'bob', day: 1),
        duel('alice', 'carol', day: 2),
      ]);
      final stats = StatsEngine([g]).computeGlobalStats();

      final ranking = Map.fromEntries(stats.globalRanking);
      expect(ranking['alice'], 3);
      expect(ranking['bob'], isNull);
      expect(ranking['carol'], isNull);

      expect(stats.globalNemesisA, 'alice');
      expect(stats.globalNemesisB, 'bob');
      expect(stats.globalNemesisScore, 2);

      expect({stats.globalRivalA!, stats.globalRivalB!},
          containsAll(['alice', 'bob']));
      expect(stats.globalRivalGames, 2);

      expect(stats.mostActivePlayerId, 'alice');
      expect(stats.mostActiveSessions, 3);
    });
  });

  group('mutant regression: game.dart', () {
    // builtin.op.eq on `m.name == json['mode']` (mutated to `!=`) returns the
    // first mode that is NOT the requested one.
    test('fromJson restores the exact mode', () {
      final g = Game(id: 'g', name: 'G', mode: GameMode.duel);
      expect(Game.fromJson(g.toJson()).mode, GameMode.duel);
    });
  });

  group('mutant regression: app_data.dart', () {
    // builtin.op.neq on `json['lastModified'] != null` (mutated to `==`) falls
    // back to DateTime.now() instead of parsing the stored timestamp.
    test('fromJson parses lastModified when present', () {
      final t = DateTime(2020, 5, 6, 7, 8, 9);
      final data = AppData.fromJson({
        'games': <dynamic>[],
        'players': <dynamic>[],
        'lastModified': t.toIso8601String(),
      });
      expect(data.lastModified, t);
    });

    // builtin.function.arg2 swaps `resolve(item, map[id])` arguments. With equal
    // createdAt the original keeps the remote copy, the swapped call keeps the
    // local one — the only observable difference.
    test('mergeWith keeps the remote copy when createdAt ties', () {
      final t = DateTime(2024, 1, 1);
      final local = Game(
          id: 'g', name: 'Local', mode: GameMode.points, createdAt: t);
      final remote = Game(
          id: 'g', name: 'Remote', mode: GameMode.points, createdAt: t);
      final merged = AppData(games: [local]).mergeWith(AppData(games: [remote]));
      expect(merged.games.single.name, 'Remote');
    });
  });
}