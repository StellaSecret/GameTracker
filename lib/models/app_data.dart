// lib/models/app_data.dart
import 'game.dart';
import 'player.dart';

class AppData {
  final List<Game> games;
  final List<Player> players;
  final DateTime lastModified;

  AppData({
    List<Game>? games,
    List<Player>? players,
    DateTime? lastModified,
  })  : games = games ?? [],
        players = players ?? [],
        lastModified = lastModified ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'games': games.map((g) => g.toJson()).toList(),
        'players': players.map((p) => p.toJson()).toList(),
        'lastModified': lastModified.toIso8601String(),
        'version': 1,
      };

  factory AppData.fromJson(Map<String, dynamic> json) => AppData(
        games: (json['games'] as List<dynamic>?)
                ?.map((g) => Game.fromJson(g as Map<String, dynamic>))
                .toList() ??
            [],
        players: (json['players'] as List<dynamic>?)
                ?.map((p) => Player.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
        lastModified: json['lastModified'] != null
            ? DateTime.parse(json['lastModified'] as String)
            : DateTime.now(),
      );
}
