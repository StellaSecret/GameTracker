// Moteur de calcul pour toutes les statistiques avancées.
// Pur Dart, sans dépendances Flutter — testable unitairement.

import 'game.dart';
import 'game_mode.dart';
import 'game_session.dart';

// ── Résultats par joueur ───────────────────────────────────────────────────

class PlayerStats {
  final String playerId;

  final int totalGames;
  final int totalWins;
  final double winRate;

  final int? bestScore;
  final int? worstScore;
  final double? avgScore;

  final int currentStreak;
  final int bestStreak;

  final String? favoriteGameId;
  final String? favoriteGameName;
  final int? favoriteGameWins;

  final Map<String, double> winRateByGame;
  final Map<String, int> winsByGame;
  final Map<String, int> gamesByGame;

  final String? nemesisId;
  final int? nemesisLosses;
  final String? rivalId;
  final int? rivalGames;

  const PlayerStats({
    required this.playerId,
    required this.totalGames,
    required this.totalWins,
    required this.winRate,
    this.bestScore,
    this.worstScore,
    this.avgScore,
    required this.currentStreak,
    required this.bestStreak,
    this.favoriteGameId,
    this.favoriteGameName,
    this.favoriteGameWins,
    required this.winRateByGame,
    required this.winsByGame,
    required this.gamesByGame,
    this.nemesisId,
    this.nemesisLosses,
    this.rivalId,
    this.rivalGames,
  });
}

// ── Résultats par jeu ─────────────────────────────────────────────────────

class GameStats {
  final String? dominantPlayerId;
  final int? dominantWins;
  final GameSession? tightestSession;
  final int? tightestGap;
  final Map<String, List<ScorePoint>> scoreHistory;

  const GameStats({
    this.dominantPlayerId,
    this.dominantWins,
    this.tightestSession,
    this.tightestGap,
    required this.scoreHistory,
  });
}

class ScorePoint {
  final DateTime date;
  final int value;
  const ScorePoint(this.date, this.value);
}

// ── Statistiques globales ─────────────────────────────────────────────────

class GlobalStats {
  final List<MapEntry<String, int>> globalRanking;
  final int? absoluteRecord;
  final String? absoluteRecordHolder;
  final String? absoluteRecordGame;
  final DateTime? absoluteRecordDate;
  final String? globalNemesisA;
  final String? globalNemesisB;
  final int? globalNemesisScore;
  final String? globalRivalA;
  final String? globalRivalB;
  final int? globalRivalGames;
  final int totalSessions;
  final int totalGames;
  final String? mostActivePlayerId;
  final int? mostActiveSessions;

  const GlobalStats({
    required this.globalRanking,
    this.absoluteRecord,
    this.absoluteRecordHolder,
    this.absoluteRecordGame,
    this.absoluteRecordDate,
    this.globalNemesisA,
    this.globalNemesisB,
    this.globalNemesisScore,
    this.globalRivalA,
    this.globalRivalB,
    this.globalRivalGames,
    required this.totalSessions,
    required this.totalGames,
    this.mostActivePlayerId,
    this.mostActiveSessions,
  });
}

// ── Moteur ────────────────────────────────────────────────────────────────────

class StatsEngine {
  final List<Game> games;

  StatsEngine(this.games);

  // ── Stats par joueur ──────────────────────────────────────────────────────

  PlayerStats computePlayerStats(String playerId) {
    int totalGames = 0;
    int totalWins = 0;
    final List<int> scores = [];
    final Map<String, int> winsByGame = {};
    final Map<String, int> gamesByGame = {};
    int bestStreak = 0;
    int streakCursor = 0;

    final Map<String, int> winsAgainst = {};
    final Map<String, int> lossesAgainst = {};
    final Map<String, int> gamesAgainst = {};

    final List<_SessionRef> allSessions = [];
    for (final game in games) {
      for (final session in game.sessions) {
        if (session.scores.containsKey(playerId)) {
          allSessions.add(_SessionRef(game: game, session: session));
        }
      }
    }
    allSessions.sort(
        (a, b) => a.session.playedAt.compareTo(b.session.playedAt));

    for (final ref in allSessions) {
      final game = ref.game;
      final session = ref.session;
      totalGames++;
      gamesByGame[game.id] = (gamesByGame[game.id] ?? 0) + 1;

      final isWinner =
          session.winnerFor(lowestScoreWins: game.lowestScoreWins) ==
              playerId;
      if (isWinner) {
        totalWins++;
        winsByGame[game.id] = (winsByGame[game.id] ?? 0) + 1;
        streakCursor++;
        if (streakCursor > bestStreak) {
          bestStreak = streakCursor;
        }
      } else {
        streakCursor = 0;
      }

      if (session.mode == GameMode.points) {
        final score = session.scores[playerId];
        if (score != null) {
          scores.add(score);
        }
      }

      for (final otherId in session.scores.keys) {
        if (otherId == playerId) {
          continue;
        }
        gamesAgainst[otherId] = (gamesAgainst[otherId] ?? 0) + 1;
        final otherWon =
            session.winnerFor(lowestScoreWins: game.lowestScoreWins) ==
                otherId;
        if (isWinner) {
          winsAgainst[otherId] = (winsAgainst[otherId] ?? 0) + 1;
        }
        if (otherWon) {
          lossesAgainst[otherId] = (lossesAgainst[otherId] ?? 0) + 1;
        }
      }
    }

    // Current streak from the end
    int currentStreak = 0;
    for (final ref in allSessions.reversed) {
      final winner = ref.session
          .winnerFor(lowestScoreWins: ref.game.lowestScoreWins);
      if (winner == playerId) {
        currentStreak++;
      } else {
        break;
      }
    }

    // Favorite game
    String? favGameId;
    int favWins = 0;
    for (final entry in winsByGame.entries) {
      if (entry.value > favWins) {
        favWins = entry.value;
        favGameId = entry.key;
      }
    }
    final favGame = favGameId != null
        ? games.where((g) => g.id == favGameId).firstOrNull
        : null;

    // Win rate per game
    final winRateByGame = <String, double>{};
    for (final gid in gamesByGame.keys) {
      final w = winsByGame[gid] ?? 0;
      final t = gamesByGame[gid] ?? 1;
      winRateByGame[gid] = w / t;
    }

    // Nemesis (min 2 games together)
    String? nemesisId;
    int nemesisLosses = 0;
    for (final entry in lossesAgainst.entries) {
      if ((gamesAgainst[entry.key] ?? 0) >= 2 &&
          entry.value > nemesisLosses) {
        nemesisLosses = entry.value;
        nemesisId = entry.key;
      }
    }

    // Rival (min 3 games together)
    String? rivalId;
    int rivalGames = 0;
    for (final entry in gamesAgainst.entries) {
      if (entry.value >= 3 && entry.value > rivalGames) {
        rivalGames = entry.value;
        rivalId = entry.key;
      }
    }

    return PlayerStats(
      playerId: playerId,
      totalGames: totalGames,
      totalWins: totalWins,
      winRate: totalGames > 0 ? totalWins / totalGames : 0,
      bestScore: scores.isEmpty
          ? null
          : scores.reduce((a, b) => a > b ? a : b),
      worstScore: scores.isEmpty
          ? null
          : scores.reduce((a, b) => a < b ? a : b),
      avgScore: scores.isEmpty
          ? null
          : scores.reduce((a, b) => a + b) / scores.length,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      favoriteGameId: favGameId,
      favoriteGameName: favGame?.name,
      favoriteGameWins: favWins > 0 ? favWins : null,
      winRateByGame: winRateByGame,
      winsByGame: winsByGame,
      gamesByGame: gamesByGame,
      nemesisId: nemesisId,
      nemesisLosses: nemesisLosses > 0 ? nemesisLosses : null,
      rivalId: rivalId,
      rivalGames: rivalGames > 0 ? rivalGames : null,
    );
  }

  // ── Stats par jeu ─────────────────────────────────────────────────────────

  GameStats computeGameStats(String gameId) {
    final game = games.where((g) => g.id == gameId).firstOrNull;
    if (game == null) {
      return const GameStats(scoreHistory: {});
    }

    // Dominant player — uses Game.winsByPlayer which is lowestScoreWins-aware
    final wins = game.winsByPlayer;
    String? dominantId;
    int dominantWins = 0;
    for (final e in wins.entries) {
      if (e.value > dominantWins) {
        dominantWins = e.value;
        dominantId = e.key;
      }
    }

    // Tightest session (points mode)
    GameSession? tightest;
    int tightestGap = 999999;
    if (game.mode == GameMode.points) {
      for (final session in game.sessions) {
        if (session.scores.length < 2) {
          continue;
        }
        final sorted = session.scores.values.toList()
          ..sort((a, b) => b - a);
        final gap = (sorted[0] - sorted[1]).abs();
        if (gap < tightestGap) {
          tightestGap = gap;
          tightest = session;
        }
      }
    }

    // Score history (points mode, chronological)
    final history = <String, List<ScorePoint>>{};
    final sortedSessions = List<GameSession>.from(game.sessions)
      ..sort((a, b) => a.playedAt.compareTo(b.playedAt));
    for (final session in sortedSessions) {
      if (session.mode != GameMode.points) {
        continue;
      }
      for (final e in session.scores.entries) {
        history
            .putIfAbsent(e.key, () => [])
            .add(ScorePoint(session.playedAt, e.value));
      }
    }

    return GameStats(
      dominantPlayerId: dominantId,
      dominantWins: dominantWins > 0 ? dominantWins : null,
      tightestSession: tightest,
      tightestGap: tightest != null ? tightestGap : null,
      scoreHistory: history,
    );
  }

  // ── Stats globales ────────────────────────────────────────────────────────

  GlobalStats computeGlobalStats() {
    final Map<String, int> globalWins = {};
    final Map<String, int> globalGames = {};
    int totalSessions = 0;
    int? absRecord;
    String? absHolder;
    String? absGame;
    DateTime? absDate;
    final Map<String, int> h2h = {};

    for (final game in games) {
      totalSessions += game.sessions.length;
      for (final session in game.sessions) {
        final w =
            session.winnerFor(lowestScoreWins: game.lowestScoreWins);
        if (w != null) {
          globalWins[w] = (globalWins[w] ?? 0) + 1;
        }
        for (final pid in session.scores.keys) {
          globalGames[pid] = (globalGames[pid] ?? 0) + 1;
        }

        // Absolute record — for lowestScoreWins, lowest score = record
        if (session.mode == GameMode.points) {
          for (final e in session.scores.entries) {
            final isBetter = absRecord == null ||
                (game.lowestScoreWins
                    ? e.value < absRecord
                    : e.value > absRecord);
            if (isBetter) {
              absRecord = e.value;
              absHolder = e.key;
              absGame = game.name;
              absDate = session.playedAt;
            }
          }
        }

        // H2H
        final players = session.scores.keys.toList();
        final winner =
            session.winnerFor(lowestScoreWins: game.lowestScoreWins);
        if (winner != null) {
          for (final loser in players) {
            if (loser == winner) {
              continue;
            }
            final key = '$winner|$loser';
            h2h[key] = (h2h[key] ?? 0) + 1;
          }
        }
      }
    }

    final ranking = globalWins.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String? nemA, nemB;
    int nemScore = 0;
    for (final e in h2h.entries) {
      if (e.value > nemScore) {
        nemScore = e.value;
        final parts = e.key.split('|');
        nemA = parts[0];
        nemB = parts[1];
      }
    }

    final Map<String, int> pairGames = {};
    for (final game in games) {
      for (final session in game.sessions) {
        final players = session.scores.keys.toList()..sort();
        for (int i = 0; i < players.length; i++) {
          for (int j = i + 1; j < players.length; j++) {
            final key = '${players[i]}|${players[j]}';
            pairGames[key] = (pairGames[key] ?? 0) + 1;
          }
        }
      }
    }
    String? rivA, rivB;
    int rivGames = 0;
    for (final e in pairGames.entries) {
      if (e.value > rivGames) {
        rivGames = e.value;
        final parts = e.key.split('|');
        rivA = parts[0];
        rivB = parts[1];
      }
    }

    String? mostActive;
    int mostActiveSessions = 0;
    for (final e in globalGames.entries) {
      if (e.value > mostActiveSessions) {
        mostActiveSessions = e.value;
        mostActive = e.key;
      }
    }

    return GlobalStats(
      globalRanking: ranking,
      absoluteRecord: absRecord,
      absoluteRecordHolder: absHolder,
      absoluteRecordGame: absGame,
      absoluteRecordDate: absDate,
      globalNemesisA: nemA,
      globalNemesisB: nemB,
      globalNemesisScore: nemScore > 0 ? nemScore : null,
      globalRivalA: rivA,
      globalRivalB: rivB,
      globalRivalGames: rivGames > 0 ? rivGames : null,
      totalSessions: totalSessions,
      totalGames: games.length,
      mostActivePlayerId: mostActive,
      mostActiveSessions:
          mostActiveSessions > 0 ? mostActiveSessions : null,
    );
  }
}

class _SessionRef {
  final Game game;
  final GameSession session;
  const _SessionRef({required this.game, required this.session});
}
