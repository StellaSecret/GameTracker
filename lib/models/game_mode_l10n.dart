// lib/models/game_mode_l10n.dart
//
// Provides localised label and description for GameMode.
// Import this alongside game_mode.dart wherever a BuildContext is available.

import '../l10n/app_localizations.dart';
import 'game_mode.dart';

extension GameModeL10n on GameMode {
  String label(AppLocalizations l) {
    switch (this) {
      case GameMode.points:
        return l.gameModePoints;
      case GameMode.duel:
        return l.gameModeDuel;
      case GameMode.ranking:
        return l.gameModeRanking;
    }
  }

  String description(AppLocalizations l) {
    switch (this) {
      case GameMode.points:
        return l.gameModePointsDesc;
      case GameMode.duel:
        return l.gameModeDuelDesc;
      case GameMode.ranking:
        return l.gameModeRankingDesc;
    }
  }
}
