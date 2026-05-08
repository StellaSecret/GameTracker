// lib/models/game_session.dart
import 'package:uuid/uuid.dart';
import 'game_mode.dart';

enum DuelResult { win, draw, loss }

/// A single round within a session.
/// - Points mode : scores are raw integers (can be negative).
/// - Duel mode   : scores are [DuelResult] indices (win/draw/loss).
class Round {
  /// playerId → score for this round
  final Map<String, int> scores;

  const Round(this.scores);

  Map<String, dynamic> toJson() =>
      {'scores': scores.map((k, v) => MapEntry(k, v))};

  factory Round.fromJson(Map<String, dynamic> json) => Round(
        (json['scores'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as int)),
      );
}

class GameSession {
  final String id;
  final DateTime playedAt;
  final GameMode mode;

  /// Final aggregated scores per player:
  /// - Points  : total across all rounds (sum)
  /// - Ranking : rank (1 = first)
  /// - Duel    : overall DuelResult index when no rounds,
  ///             OR number of rounds won when rounds are present
  final Map<String, int> scores;

  /// Individual rounds (empty = single-score entry, legacy behaviour).
  /// Points : each round has raw point values per player.
  /// Duel   : each round has DuelResult indices per player.
  final List<Round> rounds;

  final String? notes;

  GameSession({
    String? id,
    DateTime? playedAt,
    required this.mode,
    required this.scores,
    List<Round>? rounds,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        playedAt = playedAt ?? DateTime.now(),
        rounds = rounds ?? [];

  /// Whether this session was entered with explicit rounds.
  bool get hasRounds => rounds.isNotEmpty;

  // ── Winner ──────────────────────────────────────────────────────────────────

  /// Returns the playerId of the winner, or null for a tie/draw.
  ///
  /// [lowestScoreWins] is only meaningful for [GameMode.points].
  String? winnerFor({bool lowestScoreWins = false}) {
    if (scores.isEmpty) {
      return null;
    }
    switch (mode) {
      case GameMode.points:
        if (lowestScoreWins) {
          // Lowest total wins (e.g. "6 qui prend")
          final min = scores.values.reduce((a, b) => a < b ? a : b);
          final winners = scores.entries.where((e) => e.value == min).toList();
          return winners.length == 1 ? winners.first.key : null;
        } else {
          // Highest total wins (default)
          final max = scores.values.reduce((a, b) => a > b ? a : b);
          final winners = scores.entries.where((e) => e.value == max).toList();
          return winners.length == 1 ? winners.first.key : null;
        }

      case GameMode.ranking:
        // 1 = first place
        final first = scores.entries.where((e) => e.value == 1).toList();
        return first.length == 1 ? first.first.key : null;

      case GameMode.duel:
        if (hasRounds) {
          // scores = nb rounds won per player
          final max = scores.values.reduce((a, b) => a > b ? a : b);
          final winners = scores.entries.where((e) => e.value == max).toList();
          return winners.length == 1 ? winners.first.key : null;
        } else {
          // Legacy: scores = DuelResult index
          final winners = scores.entries
              .where((e) => e.value == DuelResult.win.index)
              .toList();
          return winners.length == 1 ? winners.first.key : null;
        }
    }
  }

  /// Convenience getter — uses default lowestScoreWins = false.
  /// Use [winnerFor] when you have access to the parent [Game].
  String? get winner => winnerFor();

  // ── Serialization ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'playedAt': playedAt.toIso8601String(),
        'mode': mode.name,
        'scores': scores.map((k, v) => MapEntry(k, v)),
        'rounds': rounds.map((r) => r.toJson()).toList(),
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
        rounds: (json['rounds'] as List<dynamic>?)
                ?.map((r) => Round.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
        notes: json['notes'] as String?,
      );

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Builds aggregated [scores] from [rounds] for a points-mode session.
  /// Returns a new map — does not mutate anything.
  static Map<String, int> aggregatePointsRounds(List<Round> rounds) {
    final totals = <String, int>{};
    for (final round in rounds) {
      for (final entry in round.scores.entries) {
        totals[entry.key] = (totals[entry.key] ?? 0) + entry.value;
      }
    }
    return totals;
  }

  /// Builds aggregated [scores] (rounds won) from duel-mode rounds.
  /// Returns a new map — does not mutate anything.
  static Map<String, int> aggregateDuelRounds(List<Round> rounds) {
    final wins = <String, int>{};
    for (final round in rounds) {
      for (final entry in round.scores.entries) {
        wins.putIfAbsent(entry.key, () => 0);
        if (entry.value == DuelResult.win.index) {
          wins[entry.key] = wins[entry.key]! + 1;
        }
      }
    }
    return wins;
  }
}
