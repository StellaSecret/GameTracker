// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:game_tracker/models/app_data.dart';
import 'package:game_tracker/models/game.dart';
import 'package:game_tracker/models/game_mode.dart';
import 'package:game_tracker/models/game_session.dart';
import 'package:game_tracker/models/player.dart';

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

  group('AppData.mergeWith', () {
    test('games from both sides are merged by id', () {
      final g1 = Game(id: 'g1', name: 'Chess', mode: GameMode.duel);
      final g2 = Game(id: 'g2', name: 'Catan', mode: GameMode.points);
      final local = AppData(games: [g1]);
      final remote = AppData(games: [g2]);
      final merged = local.mergeWith(remote);
      expect(merged.games.map((g) => g.id), containsAll(['g1', 'g2']));
    });

    test('players from both sides are merged by id', () {
      final p1 = Player(id: 'p1', name: 'Alice');
      final p2 = Player(id: 'p2', name: 'Bob');
      final local = AppData(players: [p1]);
      final remote = AppData(players: [p2]);
      final merged = local.mergeWith(remote);
      expect(merged.players.map((p) => p.id), containsAll(['p1', 'p2']));
    });

    test('deleted game on local side is not present after merge', () {
      final g = Game(id: 'g1', name: 'Chess', mode: GameMode.duel);
      final local = AppData(deletedGameIds: ['g1']);
      final remote = AppData(games: [g]);
      final merged = local.mergeWith(remote);
      expect(merged.games.where((x) => x.id == 'g1'), isEmpty);
    });

    test('deleted game on remote side is not present after merge', () {
      final g = Game(id: 'g1', name: 'Chess', mode: GameMode.duel);
      final local = AppData(games: [g]);
      final remote = AppData(deletedGameIds: ['g1']);
      final merged = local.mergeWith(remote);
      expect(merged.games.where((x) => x.id == 'g1'), isEmpty);
    });

    test('tombstone set is the union of both sides', () {
      final local = AppData(deletedGameIds: ['g1']);
      final remote = AppData(deletedGameIds: ['g2']);
      final merged = local.mergeWith(remote);
      expect(merged.deletedGameIds, containsAll(['g1', 'g2']));
    });

    test('lastModified is the later of the two', () {
      final earlier = DateTime(2024, 3, 15);
      final later = DateTime(2024, 9, 20);
      final local = AppData(lastModified: earlier);
      final remote = AppData(lastModified: later);
      expect(local.mergeWith(remote).lastModified, later);
      expect(remote.mergeWith(local).lastModified, later);
    });

    test('duplicate game id: local copy is kept', () {
      final gLocal = Game(
        id: 'g1', name: 'Local name', mode: GameMode.points,
        createdAt: DateTime(2024, 9, 20),
      );
      final gRemote = Game(
        id: 'g1', name: 'Remote name', mode: GameMode.points,
        createdAt: DateTime(2024, 3, 15),
      );
      final merged = AppData(games: [gLocal]).mergeWith(AppData(games: [gRemote]));
      expect(merged.games.first.name, 'Local name');
    });

    test('deletedGameIds survive a subsequent _persist-style reconstruction', () {
      // Regression test for the bug where _persist() dropped deletedGameIds.
      final original = AppData(deletedGameIds: ['g1', 'g2']);
      // Simulate what _persist() now does (including deletedGameIds).
      final reconstructed = AppData(
        games: original.games,
        players: original.players,
        deletedGameIds: original.deletedGameIds,
      );
      expect(reconstructed.deletedGameIds, containsAll(['g1', 'g2']));
    });
  });

  group('AppData serialization', () {
    test('round-trip preserves games, players and deletedGameIds', () {
      final data = AppData(
        games: [Game(name: 'Chess', mode: GameMode.duel)],
        players: [Player(name: 'Alice'), Player(name: 'Bob')],
        deletedGameIds: ['old-id'],
      );
      final data2 = AppData.fromJson(data.toJson());
      expect(data2.games.length, 1);
      expect(data2.players.length, 2);
      expect(data2.games.first.name, 'Chess');
      expect(data2.deletedGameIds, contains('old-id'));
    });

    test('empty AppData has no games or players', () {
      final data = AppData();
      expect(data.games, isEmpty);
      expect(data.players, isEmpty);
      expect(data.deletedGameIds, isEmpty);
    });
  });
}
