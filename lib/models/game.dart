// lib/models/game.dart
import 'package:uuid/uuid.dart';
import 'game_mode.dart';
import 'game_session.dart';

class Game {
  final String id;
  String name;
  GameMode mode;
  String? description;
  String? coverEmoji;
  final DateTime createdAt;
  List<GameSession> sessions;

  /// Points mode only: if true, the player with the LOWEST total wins.
  /// e.g. "6 qui prend", "Hearts", "Golf".
  bool lowestScoreWins;

  Game({
    String? id,
    required this.name,
    required this.mode,
    this.description,
    this.coverEmoji,
    DateTime? createdAt,
    List<GameSession>? sessions,
    this.lowestScoreWins = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        sessions = sessions ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mode': mode.name,
        'description': description,
        'coverEmoji': coverEmoji,
        'createdAt': createdAt.toIso8601String(),
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'lowestScoreWins': lowestScoreWins,
      };

  factory Game.fromJson(Map<String, dynamic> json) => Game(
        id: json['id'] as String,
        name: json['name'] as String,
        mode: GameMode.values.firstWhere(
          (m) => m.name == json['mode'],
          orElse: () => GameMode.points,
        ),
        description: json['description'] as String?,
        coverEmoji: json['coverEmoji'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        sessions: (json['sessions'] as List<dynamic>?)
                ?.map((s) => GameSession.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        // Graceful fallback for existing saved games (field absent → false)
        lowestScoreWins: json['lowestScoreWins'] as bool? ?? false,
      );

  Game copyWith({
    String? name,
    GameMode? mode,
    String? description,
    String? coverEmoji,
    List<GameSession>? sessions,
    bool? lowestScoreWins,
  }) =>
      Game(
        id: id,
        name: name ?? this.name,
        mode: mode ?? this.mode,
        description: description ?? this.description,
        coverEmoji: coverEmoji ?? this.coverEmoji,
        createdAt: createdAt,
        sessions: sessions ?? this.sessions,
        lowestScoreWins: lowestScoreWins ?? this.lowestScoreWins,
      );

  // ── Stats helpers ──────────────────────────────────────────────────────────

  /// Returns a map of playerId → wins.
  /// For points mode, respects [lowestScoreWins].
  Map<String, int> get winsByPlayer {
    final map = <String, int>{};
    for (final session in sessions) {
      final winner = session.winnerFor(lowestScoreWins: lowestScoreWins);
      if (winner != null) {
        map[winner] = (map[winner] ?? 0) + 1;
      }
    }
    return map;
  }

  /// Returns a map of playerId → total points (points mode only).
  Map<String, int> get totalPointsByPlayer {
    final map = <String, int>{};
    for (final session in sessions) {
      for (final entry in session.scores.entries) {
        map[entry.key] = (map[entry.key] ?? 0) + entry.value;
      }
    }
    return map;
  }

  /// Returns a map of playerId → record score in a single session.
  /// For [lowestScoreWins] games, "record" means the lowest single-session score.
  Map<String, int> get recordsByPlayer {
    final map = <String, int>{};
    for (final session in sessions) {
      for (final entry in session.scores.entries) {
        final current = map[entry.key];
        final isBetter = current == null ||
            (lowestScoreWins ? entry.value < current : entry.value > current);
        if (isBetter) {
          map[entry.key] = entry.value;
        }
      }
    }
    return map;
  }
}
