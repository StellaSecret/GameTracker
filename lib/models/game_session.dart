// lib/models/game_session.dart
import 'package:uuid/uuid.dart';
import 'game_mode.dart';

enum DuelResult { win, draw, loss }

class GameSession {
  final String id;
  final DateTime playedAt;
  final GameMode mode;

  /// For GameMode.points and GameMode.ranking: playerId → score/rank
  /// For GameMode.duel: playerId → DuelResult index (0=win, 1=draw, 2=loss)
  final Map<String, int> scores;
  final String? notes;

  GameSession({
    String? id,
    DateTime? playedAt,
    required this.mode,
    required this.scores,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        playedAt = playedAt ?? DateTime.now();

  /// Returns the playerId of the winner, or null for draw/multi-rank.
  String? get winner {
    if (scores.isEmpty) return null;
    switch (mode) {
      case GameMode.points:
        return scores.entries
            .reduce((a, b) => a.value >= b.value ? a : b)
            .key;
      case GameMode.ranking:
        // 1 = first place
        final first = scores.entries.where((e) => e.value == 1);
        return first.length == 1 ? first.first.key : null;
      case GameMode.duel:
        final winners = scores.entries
            .where((e) => e.value == DuelResult.win.index)
            .toList();
        return winners.length == 1 ? winners.first.key : null;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'playedAt': playedAt.toIso8601String(),
        'mode': mode.name,
        'scores': scores.map((k, v) => MapEntry(k, v)),
        'notes': notes,
      };

  factory GameSession.fromJson(Map<String, dynamic> json) => GameSession(
        id: json['id'] as String,
        playedAt: DateTime.parse(json['playedAt'] as String),
        mode: GameMode.values.firstWhere(
          (m) => m.name == json['mode'],
          orElse: () => GameMode.points,
        ),
        scores: (json['scores'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as int)),
        notes: json['notes'] as String?,
      );
}
