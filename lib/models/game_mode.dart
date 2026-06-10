// lib/models/game_mode.dart
//
// GameMode labels and descriptions are intentionally NOT stored here as strings
// because they must be localised. Screens obtain them via AppLocalizations:
//
//   final l = AppLocalizations.of(context)!;
//   l.gameModePoints        // "Points" / "Points"
//   l.gameModePointsDesc    // description

enum GameMode {
  points,  // Score ranking per session
  duel,    // Win / Draw / Loss
  ranking, // Positional ranking (1st, 2nd…)
}

extension GameModeExtension on GameMode {
  /// Icon emoji — not translatable, intentionally hardcoded.
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
