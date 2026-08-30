// game_mode_l10n.dart was never imported by a test, so it sat outside
// mutation scope. These assert the extension's English mapping.
// Run with: flutter test test/game_mode_l10n_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:game_tracker/l10n/app_localizations_en.dart';
import 'package:game_tracker/models/game_mode.dart';
import 'package:game_tracker/models/game_mode_l10n.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('mode labels map to the English strings', () {
    expect(GameMode.points.label(l10n), 'Points');
    expect(GameMode.duel.label(l10n), 'Duel');
    expect(GameMode.ranking.label(l10n), 'Ranking');
  });

  test('mode descriptions map to the English strings', () {
    expect(GameMode.points.description(l10n), 'Score ranking per session');
    expect(
      GameMode.duel.description(l10n),
      'Win / Draw / Loss between two players',
    );
    expect(
      GameMode.ranking.description(l10n),
      'Positional ranking for multiple players (1st, 2nd…)',
    );
  });

  test('every mode produces a distinct label and description', () {
    final labels = GameMode.values.map((m) => m.label(l10n)).toSet();
    final descriptions =
        GameMode.values.map((m) => m.description(l10n)).toSet();
    expect(labels, hasLength(GameMode.values.length));
    expect(descriptions, hasLength(GameMode.values.length));
  });
}