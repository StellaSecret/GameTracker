import '../models/app_data.dart';
import '../models/game.dart';
import '../models/game_mode.dart';
import '../models/game_session.dart';
import '../models/player.dart';

class MockDataGenerator {
  static AppData generate() {
    final p1 = Player(id: 'p1', name: 'Alice');
    final p2 = Player(id: 'p2', name: 'Bob');
    final p3 = Player(id: 'p3', name: 'Charlie');
    final p4 = Player(id: 'p4', name: 'Dave');

    final game1 = Game(id: 'g1', name: 'Catan', mode: GameMode.points);
    game1.sessions = [
      GameSession(id: 's1', mode: GameMode.points, scores: {'p1': 10, 'p2': 8, 'p3': 7, 'p4': 5}, playedAt: DateTime.now().subtract(const Duration(days: 3))),
      GameSession(id: 's2', mode: GameMode.points, scores: {'p1': 5, 'p2': 10, 'p3': 9, 'p4': 6}, playedAt: DateTime.now().subtract(const Duration(days: 2))),
      GameSession(id: 's3', mode: GameMode.points, scores: {'p1': 12, 'p2': 9, 'p3': 4, 'p4': 8}, playedAt: DateTime.now().subtract(const Duration(days: 1))),
    ];

    final game2 = Game(id: 'g2', name: 'Sushi Go', mode: GameMode.points);
    game2.sessions = [
      GameSession(id: 's4', mode: GameMode.points, scores: {'p1': 20, 'p2': 25, 'p3': 15, 'p4': 18}, playedAt: DateTime.now().subtract(const Duration(days: 5))),
      GameSession(id: 's5', mode: GameMode.points, scores: {'p1': 22, 'p2': 21, 'p3': 19, 'p4': 24}, playedAt: DateTime.now().subtract(const Duration(days: 4))),
    ];

    final game3 = Game(id: 'g3', name: '6 Qui Prend', mode: GameMode.points, lowestScoreWins: true);
    game3.sessions = [
      GameSession(id: 's6', mode: GameMode.points, scores: {'p1': 12, 'p2': 4, 'p3': 8, 'p4': 20}, playedAt: DateTime.now().subtract(const Duration(hours: 12))),
      GameSession(id: 's7', mode: GameMode.points, scores: {'p1': 6, 'p2': 14, 'p3': 3, 'p4': 11}, playedAt: DateTime.now().subtract(const Duration(hours: 6))),
    ];

    final game4 = Game(id: 'g4', name: 'Ping Pong', mode: GameMode.duel);
    game4.sessions = [
      GameSession(id: 's8', mode: GameMode.duel, scores: {'p1': 1, 'p2': 0}, playedAt: DateTime.now().subtract(const Duration(hours: 2))),
      GameSession(id: 's9', mode: GameMode.duel, scores: {'p1': 0, 'p2': 1}, playedAt: DateTime.now().subtract(const Duration(hours: 1))),
    ];
    
    return AppData(
      games: [game1, game2, game3, game4],
      players: [p1, p2, p3, p4],
      lastModified: DateTime.now(),
      deletedGameIds: [],
    );
  }
}
