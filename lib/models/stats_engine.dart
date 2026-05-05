// Moteur de calcul pour toutes les statistiques avancées.
// Pur Dart, sans dépendances Flutter — testable unitairement.

import 'game.dart';
import 'game_mode.dart';
import 'game_session.dart';

// ── Résultats par joueur ───────────────────────────────────────────────────

class PlayerStats {
  final String playerId;

  // Victoires / taux
  final int totalGames;       // sessions jouées
  final int totalWins;
  final double winRate;       // 0.0 → 1.0

  // Points (mode points uniquement)
  final int? bestScore;
  final int? worstScore;
  final double? avgScore;

  // Série
  final int currentStreak;   // série actuelle en cours
  final int bestStreak;

  // Jeu favori (où il gagne le plus en absolu)
  final String? favoriteGameId;
  final String? favoriteGameName;
  final int? favoriteGameWins;

  // Taux par jeu : gameId → winRate
  final Map<String, double> winRateByGame;
  final Map<String, int> winsByGame;
  final Map<String, int> gamesByGame;  // nb sessions par jeu

  // Nemesis : playerId → nb fois perdu contre lui
  final String? nemesisId;
  final int? nemesisLosses;

  // Rival : playerId → indice de rivalité (parties ensemble)
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
  // Joueur dominant
  final String? dominantPlayerId;
  final int? dominantWins;

  // Partie la plus serrée (écart min entre 1er et 2ème en mode points)
  final GameSession? tightestSession;
  final int? tightestGap;

  // Évolution : liste (date, score) par joueur
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
  // Classement général : playerId → score composite (victoires pondérées)
  final List<MapEntry<String, int>> globalRanking;

  // Records absolus
  final int? absoluteRecord;
  final String? absoluteRecordHolder;
  final String? absoluteRecordGame;
  final DateTime? absoluteRecordDate;

  // Paires nemesis/rival globales
  final String? globalNemesisA;
  final String? globalNemesisB;
  final int? globalNemesisScore; // nb victoires de A sur B

  final String? globalRivalA;
  final String? globalRivalB;
  final int? globalRivalGames;

  // Funfacts
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

// ── Moteur ────────────────────────────────────────────────────────────────

class StatsEngine {
  final List<Game> games;

  StatsEngine(this.games);

  // ── Stats par joueur ───────────────────────────────────────────────────

  PlayerStats computePlayerStats(String playerId) {
    int totalGames = 0;
    int totalWins = 0;
    final List<int> scores = [];
    final Map<String, int> winsByGame = {};
    final Map<String, int> gamesByGame = {};
    int currentStreak = 0;
    int bestStreak = 0;
    int streakCursor = 0;

    // Nemesis / Rival : playerB → wins of playerId against playerB
    final Map<String, int> winsAgainst = {};   // how many times I beat X
    final Map<String, int> lossesAgainst = {}; // how many times X beat me
    final Map<String, int> gamesAgainst = {};  // games together

    // Toutes les sessions triées chronologiquement
    final List<_SessionRef> allSessions = [];
    for (final game in games) {
      for (final session in game.sessions) {
        if (session.scores.containsKey(playerId)) {
          allSessions.add(_SessionRef(game: game, session: session));
        }
      }
    }
    allSessions.sort((a, b) => a.session.playedAt.compareTo(b.session.playedAt));

    for (final ref in allSessions) {
      final game = ref.game;
      final session = ref.session;
      totalGames++;
      gamesByGame[game.id] = (gamesByGame[game.id] ?? 0) + 1;

      final isWinner = session.winner == playerId;
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

      // Points
      if (session.mode == GameMode.points) {
        final score = session.scores[playerId];
        if (score != null) {
          scores.add(score);
        }
      }

      // Nemesis / Rival
      for (final otherId in session.scores.keys) {
        if (otherId == playerId) {
          continue;
        }
        gamesAgainst[otherId] = (gamesAgainst[otherId] ?? 0) + 1;
        final otherWon = session.winner == otherId;
        final iWon = session.winner == playerId;
        if (iWon) {
          winsAgainst[otherId] = (winsAgainst[otherId] ?? 0) + 1;
        }
        if (otherWon) {
          lossesAgainst[otherId] = (lossesAgainst[otherId] ?? 0) + 1;
        }
      }
    }

    // Streak actuelle (depuis la fin)
    currentStreak = 0;
    for (final ref in allSessions.reversed) {
      if (ref.session.winner == playerId) {
        currentStreak++;
      } else {
        break;
      }
    }

    // Jeu favori
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

    // Win rate par jeu
    final winRateByGame = <String, double>{};
    for (final gid in gamesByGame.keys) {
      final w = winsByGame[gid] ?? 0;
      final t = gamesByGame[gid] ?? 1;
      winRateByGame[gid] = w / t;
    }

    // Nemesis : le joueur contre qui j'ai le plus perdu (min 2 parties communes)
    String? nemesisId;
    int nemesisLosses = 0;
    for (final entry in lossesAgainst.entries) {
      if ((gamesAgainst[entry.key] ?? 0) >= 2 && entry.value > nemesisLosses) {
        nemesisLosses = entry.value;
        nemesisId = entry.key;
      }
    }

    // Rival : le joueur avec qui j'ai joué le plus (min 3 parties)
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
      bestScore: scores.isEmpty ? null : scores.reduce((a, b) => a > b ? a : b),
      worstScore: scores.isEmpty ? null : scores.reduce((a, b) => a < b ? a : b),
      avgScore: scores.isEmpty ? null : scores.reduce((a, b) => a + b) / scores.length,
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

  // ── Stats par jeu ──────────────────────────────────────────────────────

  GameStats computeGameStats(String gameId) {
    final game = games.where((g) => g.id == gameId).firstOrNull;
    if (game == null) {
      return const GameStats(scoreHistory: {});
    }

    // Dominant
    final wins = game.winsByPlayer;
    String? dominantId;
    int dominantWins = 0;
    for (final e in wins.entries) {
      if (e.value > dominantWins) {
        dominantWins = e.value;
        dominantId = e.key;
      }
    }

    // Partie la plus serrée (mode points)
    GameSession? tightest;
    int tightestGap = 999999;
    if (game.mode == GameMode.points) {
      for (final session in game.sessions) {
        if (session.scores.length < 2) {
          continue;
        }
        final sorted = session.scores.values.toList()..sort((a, b) => b - a);
        final gap = sorted[0] - sorted[1];
        if (gap < tightestGap) {
          tightestGap = gap;
          tightest = session;
        }
      }
    }

    // Historique des scores par joueur (chronologique)
    final history = <String, List<ScorePoint>>{};
    final sorted = List<GameSession>.from(game.sessions)
      ..sort((a, b) => a.playedAt.compareTo(b.playedAt));
    for (final session in sorted) {
      if (session.mode != GameMode.points) {
        continue;
      }
      for (final e in session.scores.entries) {
        history.putIfAbsent(e.key, () => []).add(ScorePoint(session.playedAt, e.value));
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

  // ── Stats globales ────────────────────────────────────────────────────

  GlobalStats computeGlobalStats() {
    final Map<String, int> globalWins = {};
    final Map<String, int> globalGames = {};
    int totalSessions = 0;
    int? absRecord;
    String? absHolder;
    String? absGame;
    DateTime? absDate;

    // Head-to-head : "A|B" → wins of A over B
    final Map<String, int> h2h = {};

    for (final game in games) {
      totalSessions += game.sessions.length;
      for (final session in game.sessions) {
        // Wins
        final w = session.winner;
        if (w != null) {
          globalWins[w] = (globalWins[w] ?? 0) + 1;
        }
        for (final pid in session.scores.keys) {
          globalGames[pid] = (globalGames[pid] ?? 0) + 1;
        }
        // Record absolu (mode points)
        if (session.mode == GameMode.points) {
          for (final e in session.scores.entries) {
            if (absRecord == null || e.value > absRecord) {
              absRecord = e.value;
              absHolder = e.key;
              absGame = game.name;
              absDate = session.playedAt;
            }
          }
        }
        // H2H
        final players = session.scores.keys.toList();
        final winner = session.winner;
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

    // Classement global
    final ranking = globalWins.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Nemesis global : la paire A→B avec le plus de victoires de A sur B
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

    // Rival global : la paire qui a joué le plus ensemble
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

    // Joueur le plus actif
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
      mostActiveSessions: mostActiveSessions > 0 ? mostActiveSessions : null,
    );
  }
}

class _SessionRef {
  final Game game;
  final GameSession session;
  const _SessionRef({required this.game, required this.session});
}
