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

  Game({
    String? id,
    required this.name,
    required this.mode,
    this.description,
    this.coverEmoji,
    DateTime? createdAt,
    List<GameSession>? sessions,
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
      );

  Game copyWith({
    String? name,
    GameMode? mode,
    String? description,
    String? coverEmoji,
    List<GameSession>? sessions,
  }) =>
      Game(
        id: id,
        name: name ?? this.name,
        mode: mode ?? this.mode,
        description: description ?? this.description,
        coverEmoji: coverEmoji ?? this.coverEmoji,
        createdAt: createdAt,
        sessions: sessions ?? this.sessions,
      );

  // ── Stats helpers ──────────────────────────────────────────────────────────

  /// Returns a map of playerId → wins (points mode: most points; duel: winner; ranking: 1st)
  Map<String, int> get winsByPlayer {
    final map = <String, int>{};
    for (final session in sessions) {
      final winner = session.winner;
      if (winner != null) {
        map[winner] = (map[winner] ?? 0) + 1;
      }
    }
    return map;
  }

  /// Returns a map of playerId → total points (points mode only)
  Map<String, int> get totalPointsByPlayer {
    final map = <String, int>{};
    for (final session in sessions) {
      for (final entry in session.scores.entries) {
        map[entry.key] = (map[entry.key] ?? 0) + entry.value;
      }
    }
    return map;
  }

  /// Returns a map of playerId → record (max points in a single session)
  Map<String, int> get recordsByPlayer {
    final map = <String, int>{};
    for (final session in sessions) {
      for (final entry in session.scores.entries) {
        if ((map[entry.key] ?? 0) < entry.value) {
          map[entry.key] = entry.value;
        }
      }
    }
    return map;
  }
}
