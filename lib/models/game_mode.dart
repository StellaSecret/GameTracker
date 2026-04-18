// lib/models/game_mode.dart

enum GameMode {
  points,   // Classement par points
  duel,     // Victoire / Nul / Défaite
  ranking,  // Classement positionnel (1er, 2ème…)
}

extension GameModeExtension on GameMode {
  String get label {
    switch (this) {
      case GameMode.points:
        return 'Points';
      case GameMode.duel:
        return 'Duel';
      case GameMode.ranking:
        return 'Classement';
    }
  }

  String get description {
    switch (this) {
      case GameMode.points:
        return 'Classement par nombre de points par partie';
      case GameMode.duel:
        return 'Victoire / Match nul / Défaite entre deux joueurs';
      case GameMode.ranking:
        return 'Classement positionnel multi-joueurs (1er, 2ème…)';
    }
  }

  String get icon {
    switch (this) {
      case GameMode.points:
        return '🏆';
      case GameMode.duel:
        return '⚔️';
      case GameMode.ranking:
        return '🎖️';
    }
  }
}
