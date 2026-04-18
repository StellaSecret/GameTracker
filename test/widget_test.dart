// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:game_tracker/models/game.dart';
import 'package:game_tracker/models/game_mode.dart';
import 'package:game_tracker/models/game_session.dart';
import 'package:game_tracker/models/player.dart';
import 'package:game_tracker/models/app_data.dart';

void main() {
  group('Player', () {
    test('creates with defaults', () {
      final p = Player(name: 'Alice');
      expect(p.name, 'Alice');
      expect(p.color, '#6C63FF');
      expect(p.id, isNotEmpty);
    });

    test('serializes and deserializes', () {
      final p = Player(name: 'Bob', color: '#FF6584');
      final p2 = Player.fromJson(p.toJson());
      expect(p2.id, p.id);
      expect(p2.name, p.name);
      expect(p2.color, p.color);
    });

    test('copyWith preserves id', () {
      final p = Player(name: 'Carol');
      final p2 = p.copyWith(name: 'Caroline');
      expect(p2.id, p.id);
      expect(p2.name, 'Caroline');
    });
  });

  group('GameMode', () {
    test('all modes have label, description, icon', () {
      for (final m in GameMode.values) {
        expect(m.label, isNotEmpty);
        expect(m.description, isNotEmpty);
        expect(m.icon, isNotEmpty);
      }
    });
  });

  group('GameSession', () {
    test('points mode winner is highest scorer', () {
      final s = GameSession(
        mode: GameMode.points,
        scores: {'alice': 120, 'bob': 85, 'carol': 100},
      );
      expect(s.winner, 'alice');
    });

    test('duel mode winner detected', () {
      final s = GameSession(
        mode: GameMode.duel,
        scores: {
          'alice': DuelResult.win.index,
          'bob': DuelResult.loss.index,
        },
      );
      expect(s.winner, 'alice');
    });

    test('duel draw returns null winner', () {
      final s = GameSession(
        mode: GameMode.duel,
        scores: {
          'alice': DuelResult.draw.index,
          'bob': DuelResult.draw.index,
        },
      );
      expect(s.winner, isNull);
    });

    test('ranking mode winner is rank 1', () {
      final s = GameSession(
        mode: GameMode.ranking,
        scores: {'alice': 2, 'bob': 1, 'carol': 3},
      );
      expect(s.winner, 'bob');
    });

    test('serializes and deserializes', () {
      final s = GameSession(
        mode: GameMode.points,
        scores: {'alice': 50, 'bob': 30},
        notes: 'Belle partie',
      );
      final s2 = GameSession.fromJson(s.toJson());
      expect(s2.id, s.id);
      expect(s2.scores, s.scores);
      expect(s2.notes, s.notes);
    });
  });

  group('Game stats', () {
    late Game game;

    setUp(() {
      game = Game(name: 'Catan', mode: GameMode.points);
      game.sessions.addAll([
        GameSession(
          mode: GameMode.points,
          scores: {'alice': 10, 'bob': 8},
        ),
        GameSession(
          mode: GameMode.points,
          scores: {'alice': 6, 'bob': 12},
        ),
        GameSession(
          mode: GameMode.points,
          scores: {'alice': 9, 'bob': 7},
        ),
      ]);
    });

    test('winsByPlayer counts correctly', () {
      final wins = game.winsByPlayer;
      expect(wins['alice'], 2); // sessions 1 & 3
      expect(wins['bob'], 1);   // session 2
    });

    test('totalPointsByPlayer sums correctly', () {
      final totals = game.totalPointsByPlayer;
      expect(totals['alice'], 25);
      expect(totals['bob'], 27);
    });

    test('recordsByPlayer returns max', () {
      final records = game.recordsByPlayer;
      expect(records['alice'], 10);
      expect(records['bob'], 12);
    });

    test('serializes and deserializes with sessions', () {
      final g2 = Game.fromJson(game.toJson());
      expect(g2.id, game.id);
      expect(g2.sessions.length, 3);
      expect(g2.winsByPlayer['alice'], 2);
    });
  });

  group('AppData', () {
    test('serializes and deserializes round-trip', () {
      final data = AppData(
        games: [Game(name: 'Chess', mode: GameMode.duel)],
        players: [Player(name: 'Alice'), Player(name: 'Bob')],
      );
      final data2 = AppData.fromJson(data.toJson());
      expect(data2.games.length, 1);
      expect(data2.players.length, 2);
      expect(data2.games.first.name, 'Chess');
    });

    test('empty AppData has no games or players', () {
      final data = AppData();
      expect(data.games, isEmpty);
      expect(data.players, isEmpty);
    });
  });
}
