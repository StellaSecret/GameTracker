// Non-regression tests for GameSession, Game, Round and StatsEngine.
// Pure Dart — no Flutter dependency, no device needed.
// Run with: flutter test test/stats_engine_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:game_tracker/models/game.dart';
import 'package:game_tracker/models/game_mode.dart';
import 'package:game_tracker/models/game_session.dart';
import 'package:game_tracker/models/stats_engine.dart';

// ── Helpers ────────────────────────────────────────────────────────────────

GameSession pts(Map<String, int> scores, {int day = 0}) => GameSession(
      mode: GameMode.points,
      scores: scores,
      playedAt: DateTime(2024, 1, 1).add(Duration(days: day)),
    );

GameSession duel(String winner, String loser,
        {bool draw = false, int day = 0}) =>
    GameSession(
      mode: GameMode.duel,
      scores: draw
          ? {winner: DuelResult.draw.index, loser: DuelResult.draw.index}
          : {winner: DuelResult.win.index, loser: DuelResult.loss.index},
      playedAt: DateTime(2024, 1, 1).add(Duration(days: day)),
    );

GameSession rank(Map<String, int> ranks, {int day = 0}) => GameSession(
      mode: GameMode.ranking,
      scores: ranks,
      playedAt: DateTime(2024, 1, 1).add(Duration(days: day)),
    );

/// Standard 3-player, 2-game scenario.
/// Catan day4 is a tie (alice=9, bob=9, carol=8) → no winner.
({Game catan, Game chess}) buildScenario() {
  final catan = Game(id: 'catan', name: 'Catan', mode: GameMode.points);
  catan.sessions.addAll([
    pts({'alice': 10, 'bob': 8, 'carol': 6}), // alice
    pts({'alice': 5,  'bob': 12, 'carol': 9}, day: 1), // bob
    pts({'alice': 9,  'bob': 7,  'carol': 11}, day: 2), // carol
    pts({'alice': 14, 'bob': 8,  'carol': 6}, day: 3), // alice
    pts({'alice': 9,  'bob': 9,  'carol': 8}, day: 4), // tie
  ]);
  final chess = Game(id: 'chess', name: 'Chess', mode: GameMode.duel);
  chess.sessions.addAll([
    duel('alice', 'bob'),
    duel('bob',   'alice', day: 1),
    duel('alice', 'bob', day: 2),
    duel('alice', 'bob', day: 3),
    duel('bob',   'alice', day: 4),
  ]);
  return (catan: catan, chess: chess);
}

// ══════════════════════════════════════════════════════════════════════════════

void main() {

  // ── Round ─────────────────────────────────────────────────────────────────

  group('Round', () {
    test('serializes and deserializes', () {
      const r = Round({'alice': 10, 'bob': -3});
      final r2 = Round.fromJson(r.toJson());
      expect(r2.scores['alice'], 10);
      expect(r2.scores['bob'], -3);
    });

    test('supports negative scores', () {
      const r = Round({'alice': -5, 'bob': -12});
      expect(r.scores['alice'], -5);
    });
  });

  // ── GameSession.aggregatePointsRounds ─────────────────────────────────────

  group('GameSession.aggregatePointsRounds', () {
    test('sums correctly including negatives', () {
      final totals = GameSession.aggregatePointsRounds([
        const Round({'alice': 10, 'bob': -3}),
        const Round({'alice': 5,  'bob': 8}),
        const Round({'alice': -2, 'bob': 4}),
      ]);
      expect(totals['alice'], 13);
      expect(totals['bob'],   9);
    });

    test('returns empty for empty rounds', () {
      expect(GameSession.aggregatePointsRounds([]), isEmpty);
    });

    test('single round passthrough', () {
      final totals = GameSession.aggregatePointsRounds([
        const Round({'alice': 7, 'bob': 3}),
      ]);
      expect(totals['alice'], 7);
      expect(totals['bob'],   3);
    });
  });

  // ── GameSession.aggregateDuelRounds ──────────────────────────────────────

  group('GameSession.aggregateDuelRounds', () {
    test('counts round wins', () {
      final totals = GameSession.aggregateDuelRounds([
        Round({'alice': DuelResult.win.index,  'bob': DuelResult.loss.index}),
        Round({'alice': DuelResult.loss.index, 'bob': DuelResult.win.index}),
        Round({'alice': DuelResult.win.index,  'bob': DuelResult.loss.index}),
      ]);
      expect(totals['alice'], 2);
      expect(totals['bob'],   1);
    });

    test('draws count as 0 wins', () {
      final totals = GameSession.aggregateDuelRounds([
        Round({'alice': DuelResult.draw.index, 'bob': DuelResult.draw.index}),
        Round({'alice': DuelResult.draw.index, 'bob': DuelResult.draw.index}),
      ]);
      expect(totals['alice'], 0);
      expect(totals['bob'],   0);
    });
  });

  // ── GameSession.hasRounds ─────────────────────────────────────────────────

  group('GameSession.hasRounds', () {
    test('false when no rounds', () {
      final s = GameSession(mode: GameMode.points, scores: {'alice': 10});
      expect(s.hasRounds, isFalse);
    });

    test('true when rounds present', () {
      final s = GameSession(
        mode: GameMode.points,
        scores: {'alice': 10},
        rounds: [const Round({'alice': 10})],
      );
      expect(s.hasRounds, isTrue);
    });
  });

  // ── GameSession serialization ─────────────────────────────────────────────

  group('GameSession serialization', () {
    test('round-trips with rounds', () {
      final s = GameSession(
        mode: GameMode.points,
        scores: {'alice': 13, 'bob': 9},
        rounds: [
          const Round({'alice': 10, 'bob': -3}),
          const Round({'alice': 3,  'bob': 12}),
        ],
      );
      final s2 = GameSession.fromJson(s.toJson());
      expect(s2.id, s.id);
      expect(s2.scores['alice'], 13);
      expect(s2.rounds.length, 2);
      expect(s2.rounds[0].scores['bob'], -3);
      expect(s2.hasRounds, isTrue);
    });

    test('round-trips without rounds (legacy)', () {
      final s = GameSession(mode: GameMode.points, scores: {'alice': 10});
      final s2 = GameSession.fromJson(s.toJson());
      expect(s2.rounds, isEmpty);
      expect(s2.hasRounds, isFalse);
    });
  });

  // ── GameSession.winnerFor ─────────────────────────────────────────────────

  group('GameSession.winnerFor', () {
    test('highest score wins by default', () {
      final s = GameSession(mode: GameMode.points,
          scores: {'alice': 10, 'bob': 5, 'carol': 7});
      expect(s.winnerFor(), 'alice');
    });

    test('lowest score wins when flag set', () {
      final s = GameSession(mode: GameMode.points,
          scores: {'alice': 10, 'bob': 5, 'carol': 7});
      expect(s.winnerFor(lowestScoreWins: true), 'bob');
    });

    test('tie returns null (highest)', () {
      final s = GameSession(mode: GameMode.points,
          scores: {'alice': 10, 'bob': 10});
      expect(s.winnerFor(), isNull);
    });

    test('tie returns null (lowest)', () {
      final s = GameSession(mode: GameMode.points,
          scores: {'alice': 5, 'bob': 5});
      expect(s.winnerFor(lowestScoreWins: true), isNull);
    });

    test('negative scores work with lowestScoreWins', () {
      final s = GameSession(mode: GameMode.points,
          scores: {'alice': -2, 'bob': -8, 'carol': -5});
      expect(s.winnerFor(lowestScoreWins: true), 'bob');
      expect(s.winnerFor(), 'alice');
    });

    test('duel with rounds: winner has most rounds won', () {
      final rounds = [
        Round({'alice': DuelResult.win.index,  'bob': DuelResult.loss.index}),
        Round({'alice': DuelResult.win.index,  'bob': DuelResult.loss.index}),
        Round({'alice': DuelResult.loss.index, 'bob': DuelResult.win.index}),
      ];
      final s = GameSession(
        mode: GameMode.duel,
        scores: GameSession.aggregateDuelRounds(rounds),
        rounds: rounds,
      );
      expect(s.winnerFor(), 'alice');
    });

    test('duel with rounds tie returns null', () {
      final rounds = [
        Round({'alice': DuelResult.win.index,  'bob': DuelResult.loss.index}),
        Round({'alice': DuelResult.loss.index, 'bob': DuelResult.win.index}),
      ];
      final s = GameSession(
        mode: GameMode.duel,
        scores: GameSession.aggregateDuelRounds(rounds),
        rounds: rounds,
      );
      expect(s.winnerFor(), isNull);
    });

    test('ranking: rank 1 wins', () {
      final s = GameSession(mode: GameMode.ranking,
          scores: {'alice': 2, 'bob': 1, 'carol': 3});
      expect(s.winnerFor(), 'bob');
    });
  });

  // ── Game.lowestScoreWins ─────────────────────────────────────────────────

  group('Game.lowestScoreWins', () {
    test('defaults to false', () {
      expect(Game(id: 'g', name: 'G', mode: GameMode.points).lowestScoreWins,
          isFalse);
    });

    test('serializes and deserializes', () {
      final g = Game(id: 'g', name: 'G', mode: GameMode.points,
          lowestScoreWins: true);
      expect(Game.fromJson(g.toJson()).lowestScoreWins, isTrue);
    });

    test('backward compatible: absent field defaults to false', () {
      final g = Game.fromJson({
        'id': 'g', 'name': 'G', 'mode': 'points',
        'createdAt': DateTime.now().toIso8601String(),
        'sessions': <dynamic>[],
      });
      expect(g.lowestScoreWins, isFalse);
    });

    test('copyWith preserves lowestScoreWins', () {
      final g = Game(id: 'g', name: 'G', mode: GameMode.points,
          lowestScoreWins: true);
      expect(g.copyWith(name: 'G2').lowestScoreWins, isTrue);
    });

    test('copyWith can override lowestScoreWins', () {
      final g = Game(id: 'g', name: 'G', mode: GameMode.points,
          lowestScoreWins: true);
      expect(g.copyWith(lowestScoreWins: false).lowestScoreWins, isFalse);
    });
  });

  // ── Game.winsByPlayer with lowestScoreWins ────────────────────────────────

  group('Game.winsByPlayer', () {
    test('lowest wins when flag set', () {
      final g = Game(id: 'g', name: 'G', mode: GameMode.points,
          lowestScoreWins: true);
      g.sessions.addAll([
        pts({'alice': 3, 'bob': 7}), // alice
        pts({'alice': 8, 'bob': 2}, day: 1), // bob
        pts({'alice': 1, 'bob': 5}, day: 2), // alice
      ]);
      expect(g.winsByPlayer['alice'], 2);
      expect(g.winsByPlayer['bob'],   1);
    });

    test('highest wins normally', () {
      final g = Game(id: 'g', name: 'G', mode: GameMode.points);
      g.sessions.addAll([
        pts({'alice': 3, 'bob': 7}), // bob
        pts({'alice': 8, 'bob': 2}, day: 1), // alice
      ]);
      expect(g.winsByPlayer['alice'], 1);
      expect(g.winsByPlayer['bob'],   1);
    });
  });

  // ── Game.recordsByPlayer ──────────────────────────────────────────────────

  group('Game.recordsByPlayer', () {
    test('record = lowest for lowestScoreWins', () {
      final g = Game(id: 'g', name: 'G', mode: GameMode.points,
          lowestScoreWins: true);
      g.sessions.addAll([
        pts({'alice': 10}),
        pts({'alice': 3}),
        pts({'alice': 7}),
      ]);
      expect(g.recordsByPlayer['alice'], 3);
    });

    test('record = highest normally', () {
      final g = Game(id: 'g', name: 'G', mode: GameMode.points);
      g.sessions.addAll([pts({'alice': 10}), pts({'alice': 3})]);
      expect(g.recordsByPlayer['alice'], 10);
    });
  });

  // ── StatsEngine.computePlayerStats ───────────────────────────────────────

  group('StatsEngine.computePlayerStats', () {
    late StatsEngine engine;

    setUp(() {
      final s = buildScenario();
      engine = StatsEngine([s.catan, s.chess]);
    });

    test('totalGames = 5 catan + 5 chess', () {
      expect(engine.computePlayerStats('alice').totalGames, 10);
    });

    test('totalWins: catan d0,d3 + chess d0,d2,d3 = 5', () {
      expect(engine.computePlayerStats('alice').totalWins, 5);
    });

    test('winRate consistent', () {
      final s = engine.computePlayerStats('alice');
      expect(s.winRate, closeTo(s.totalWins / s.totalGames, 1e-9));
    });

    test('unknown player returns zeros', () {
      final s = engine.computePlayerStats('nobody');
      expect(s.totalGames, 0);
      expect(s.totalWins, 0);
      expect(s.winRate, 0.0);
      expect(s.bestScore, isNull);
    });

    test('bestScore is max across sessions', () {
      // alice catan: 10,5,9,14,9 → 14
      expect(engine.computePlayerStats('alice').bestScore, 14);
    });

    test('worstScore is min across sessions', () {
      expect(engine.computePlayerStats('alice').worstScore, 5);
    });

    test('avgScore is mean', () {
      // (10+5+9+14+9)/5 = 9.4
      expect(engine.computePlayerStats('alice').avgScore, closeTo(9.4, 0.001));
    });

    test('currentStreak 0 when last session was loss', () {
      final g = Game(id: 'g', name: 'G', mode: GameMode.points);
      g.sessions.addAll([
        pts({'alice': 10, 'bob': 5}),
        pts({'alice': 3,  'bob': 15}, day: 1),
      ]);
      expect(StatsEngine([g]).computePlayerStats('alice').currentStreak, 0);
    });

    test('currentStreak counts trailing wins', () {
      final g = Game(id: 'g', name: 'G', mode: GameMode.points);
      g.sessions.addAll([
        pts({'alice': 3,  'bob': 15}),
        pts({'alice': 10, 'bob': 5}, day: 1),
        pts({'alice': 11, 'bob': 5}, day: 2),
        pts({'alice': 12, 'bob': 5}, day: 3),
      ]);
      expect(StatsEngine([g]).computePlayerStats('alice').currentStreak, 3);
    });

    test('nemesis is player who beat me most (min 2 games)', () {
      // bob beats alice in chess d1,d4 → nemesis
      final stats = engine.computePlayerStats('alice');
      expect(stats.nemesisId, 'bob');
      expect(stats.nemesisLosses, 3);
    });

    test('nemesis null below 2-game threshold', () {
      final g = Game(id: 'g', name: 'G', mode: GameMode.duel);
      g.sessions.add(duel('bob', 'alice')); // only 1 game
      expect(StatsEngine([g]).computePlayerStats('alice').nemesisId, isNull);
    });

    test('winRateByGame is consistent', () {
      final stats = engine.computePlayerStats('alice');
      for (final entry in stats.winRateByGame.entries) {
        final g = stats.gamesByGame[entry.key] ?? 0;
        final w = stats.winsByGame[entry.key] ?? 0;
        expect(entry.value, closeTo(w / g, 1e-9));
        expect(entry.value, inInclusiveRange(0.0, 1.0));
      }
    });
  });

  // ── StatsEngine + lowestScoreWins ─────────────────────────────────────────

  group('StatsEngine lowestScoreWins', () {
    test('wins correctly attributed', () {
      final g = Game(id: 'g', name: 'Golf', mode: GameMode.points,
          lowestScoreWins: true);
      g.sessions.addAll([
        pts({'alice': 3, 'bob': 7}), // alice
        pts({'alice': 8, 'bob': 2}, day: 1), // bob
        pts({'alice': 1, 'bob': 9}, day: 2), // alice
        pts({'alice': 5, 'bob': 4}, day: 3), // bob
      ]);
      final engine = StatsEngine([g]);
      expect(engine.computePlayerStats('alice').totalWins, 2);
      expect(engine.computePlayerStats('bob').totalWins, 2);
    });

    test('globalRanking respects lowestScoreWins', () {
      final g = Game(id: 'g', name: 'Golf', mode: GameMode.points,
          lowestScoreWins: true);
      g.sessions.addAll([
        pts({'alice': 2, 'bob': 9}), // alice
        pts({'alice': 3, 'bob': 8}, day: 1), // alice
        pts({'alice': 7, 'bob': 1}, day: 2), // bob
      ]);
      final map = Map.fromEntries(
          StatsEngine([g]).computeGlobalStats().globalRanking);
      expect(map['alice'], 2);
      expect(map['bob'], 1);
    });

    test('absoluteRecord = lowest score for lowestScoreWins', () {
      final g = Game(id: 'g', name: 'Golf', mode: GameMode.points,
          lowestScoreWins: true);
      g.sessions.addAll([
        pts({'alice': 10, 'bob': 5}),
        pts({'alice': 2,  'bob': 8}, day: 1),
      ]);
      final global = StatsEngine([g]).computeGlobalStats();
      expect(global.absoluteRecord, 2);
      expect(global.absoluteRecordHolder, 'alice');
    });

    test('mixed games: lowestScoreWins only affects its own game', () {
      final low  = Game(id: 'low',  name: 'Golf',  mode: GameMode.points,
          lowestScoreWins: true);
      final high = Game(id: 'high', name: 'Catan', mode: GameMode.points);
      low.sessions.add(pts({'alice': 3, 'bob': 8}));  // alice wins (low)
      high.sessions.add(pts({'alice': 3, 'bob': 8})); // bob wins (high)
      final engine = StatsEngine([low, high]);

      expect(engine.computePlayerStats('alice').winsByGame['low'],  1);
      expect(engine.computePlayerStats('alice').winsByGame['high'], isNull);
      expect(engine.computePlayerStats('bob').winsByGame['high'],   1);
      expect(engine.computePlayerStats('bob').winsByGame['low'],    isNull);
    });
  });

  // ── StatsEngine + rounds ──────────────────────────────────────────────────

  group('StatsEngine rounds', () {
    test('points session with rounds uses aggregated totals', () {
      final g = Game(id: 'g', name: 'G', mode: GameMode.points);
      final rounds = [
        const Round({'alice': 10, 'bob': 5}),
        const Round({'alice': 3,  'bob': 8}),
        const Round({'alice': 7,  'bob': 2}),
      ];
      g.sessions.add(GameSession(
        mode: GameMode.points,
        scores: GameSession.aggregatePointsRounds(rounds), // alice:20, bob:15
        rounds: rounds,
        playedAt: DateTime(2024),
      ));
      final alice = StatsEngine([g]).computePlayerStats('alice');
      expect(alice.totalWins, 1);
      expect(alice.bestScore, 20);
    });

    test('duel session with rounds: winner has most rounds won', () {
      final g = Game(id: 'g', name: 'G', mode: GameMode.duel);
      final rounds = [
        Round({'alice': DuelResult.win.index,  'bob': DuelResult.loss.index}),
        Round({'alice': DuelResult.win.index,  'bob': DuelResult.loss.index}),
        Round({'alice': DuelResult.loss.index, 'bob': DuelResult.win.index}),
      ];
      g.sessions.add(GameSession(
        mode: GameMode.duel,
        scores: GameSession.aggregateDuelRounds(rounds),
        rounds: rounds,
        playedAt: DateTime(2024),
      ));
      final engine = StatsEngine([g]);
      expect(engine.computePlayerStats('alice').totalWins, 1);
      expect(engine.computePlayerStats('bob').totalWins, 0);
    });

    test('negative rounds with lowestScoreWins: correct winner', () {
      final g = Game(id: 'g', name: '6 qui prend', mode: GameMode.points,
          lowestScoreWins: true);
      final rounds = [
        const Round({'alice': -5, 'bob': -2}),
        const Round({'alice': -3, 'bob': -8}),
      ];
      // alice: -8, bob: -10 → bob is lowest → bob wins
      final scores = GameSession.aggregatePointsRounds(rounds);
      g.sessions.add(GameSession(
          mode: GameMode.points, scores: scores, rounds: rounds,
          playedAt: DateTime(2024)));
      expect(StatsEngine([g]).computePlayerStats('bob').totalWins, 1);
      expect(StatsEngine([g]).computePlayerStats('alice').totalWins, 0);
    });
  });

  // ── StatsEngine.computeGameStats ─────────────────────────────────────────

  group('StatsEngine.computeGameStats', () {
    test('unknown gameId returns empty', () {
      expect(StatsEngine([]).computeGameStats('x').dominantPlayerId, isNull);
    });

    test('dominantPlayerId is top winner', () {
      final s = buildScenario();
      // catan: alice wins d0,d3; bob d1; carol d2; d4 tie
      expect(StatsEngine([s.catan]).computeGameStats('catan').dominantPlayerId,
          'alice');
    });

    test('tightestGap selects min gap', () {
      final g = Game(id: 'g', name: 'G', mode: GameMode.points);
      g.sessions.addAll([
        pts({'alice': 10, 'bob': 5}), // gap 5
        pts({'alice': 10, 'bob': 8}, day: 1), // gap 2
        pts({'alice': 10, 'bob': 9}, day: 2), // gap 1
      ]);
      expect(StatsEngine([g]).computeGameStats('g').tightestGap, 1);
    });

    test('tightestGap works with negatives', () {
      final g = Game(id: 'g', name: 'G', mode: GameMode.points);
      g.sessions.addAll([
        pts({'alice': -3, 'bob': -8}), // gap 5
        pts({'alice': -5, 'bob': -6}, day: 1), // gap 1
      ]);
      expect(StatsEngine([g]).computeGameStats('g').tightestGap, 1);
    });

    test('scoreHistory is chronological', () {
      final s = buildScenario();
      final history = StatsEngine([s.catan]).computeGameStats('catan')
          .scoreHistory['alice']!;
      for (int i = 1; i < history.length; i++) {
        expect(
          history[i].date.isAfter(history[i - 1].date) ||
              history[i].date.isAtSameMomentAs(history[i - 1].date),
          isTrue,
        );
      }
    });

    test('scoreHistory empty for duel game', () {
      final s = buildScenario();
      expect(StatsEngine([s.chess]).computeGameStats('chess').scoreHistory,
          isEmpty);
    });
  });

  // ── StatsEngine.computeGlobalStats ───────────────────────────────────────

  group('StatsEngine.computeGlobalStats', () {
    test('empty engine returns zeros', () {
      final g = StatsEngine([]).computeGlobalStats();
      expect(g.totalGames, 0);
      expect(g.totalSessions, 0);
      expect(g.globalRanking, isEmpty);
      expect(g.absoluteRecord, isNull);
    });

    test('totalSessions sums all', () {
      final s = buildScenario();
      expect(StatsEngine([s.catan, s.chess]).computeGlobalStats().totalSessions,
          10);
    });

    test('globalRanking sorted descending', () {
      final s = buildScenario();
      final ranking =
          StatsEngine([s.catan, s.chess]).computeGlobalStats().globalRanking;
      for (int i = 1; i < ranking.length; i++) {
        expect(ranking[i - 1].value >= ranking[i].value, isTrue);
      }
    });

    test('globalRival is pair with most sessions', () {
      final s = buildScenario();
      final g = StatsEngine([s.catan, s.chess]).computeGlobalStats();
      expect(g.globalRivalGames, 10); // alice-bob: 5+5
      expect({g.globalRivalA!, g.globalRivalB!}, containsAll(['alice', 'bob']));
    });

    test('all draws: empty ranking and no nemesis', () {
      final g = Game(id: 'g', name: 'G', mode: GameMode.duel);
      g.sessions.addAll([
        duel('alice', 'bob', draw: true),
        duel('alice', 'bob', draw: true),
      ]);
      final global = StatsEngine([g]).computeGlobalStats();
      expect(global.globalRanking, isEmpty);
      expect(global.globalNemesisScore, isNull);
    });
  });

  // ── Edge cases ────────────────────────────────────────────────────────────

  group('Edge cases', () {
    test('session insertion order does not affect results', () {
      final sessions = [
        pts({'alice': 10, 'bob': 5}),
        pts({'alice': 3,  'bob': 9}, day: 1),
        pts({'alice': 7,  'bob': 2}, day: 2),
      ];
      final g1 = Game(id: 'g', name: 'G', mode: GameMode.points);
      final g2 = Game(id: 'g', name: 'G', mode: GameMode.points);
      g1.sessions.addAll(sessions);
      g2.sessions.addAll(sessions.reversed.toList());
      final s1 = StatsEngine([g1]).computePlayerStats('alice');
      final s2 = StatsEngine([g2]).computePlayerStats('alice');
      expect(s1.totalWins,     s2.totalWins);
      expect(s1.currentStreak, s2.currentStreak);
      expect(s1.bestScore,     s2.bestScore);
    });

    test('game histories do not bleed into each other', () {
      final g1 = Game(id: 'g1', name: 'G1', mode: GameMode.points);
      final g2 = Game(id: 'g2', name: 'G2', mode: GameMode.points);
      g1.sessions.add(pts({'alice': 10}));
      g2.sessions.add(pts({'alice': 20}));
      final engine = StatsEngine([g1, g2]);
      expect(engine.computeGameStats('g1').scoreHistory['alice']!.first.value, 10);
      expect(engine.computeGameStats('g2').scoreHistory['alice']!.first.value, 20);
    });

    test('single-player session: no tightest, wins correctly', () {
      final g = Game(id: 'g', name: 'G', mode: GameMode.points);
      g.sessions.add(pts({'alice': 42}));
      final engine = StatsEngine([g]);
      expect(engine.computePlayerStats('alice').totalWins, 1);
      expect(engine.computeGameStats('g').tightestSession, isNull);
    });
  });
}
