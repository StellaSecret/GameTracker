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

  /// Merge two AppData instances, deduplicating by id, keeping the most recent entry.
  AppData mergeWith(AppData other) {
    final mergedPlayers = _mergeById<Player>(
      players,
      other.players,
      (p) => p.id,
      (a, b) => a, // players don't have lastModified; keep local
    );
    final mergedGames = _mergeById<Game>(
      games,
      other.games,
      (g) => g.id,
      (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
    );
    return AppData(
      games: mergedGames,
      players: mergedPlayers,
      lastModified: lastModified.isAfter(other.lastModified)
          ? lastModified
          : other.lastModified,
    );
  }

  List<T> _mergeById<T>(
    List<T> local,
    List<T> remote,
    String Function(T) getId,
    T Function(T, T) resolve,
  ) {
    final map = <String, T>{};
    for (final item in remote) {
      map[getId(item)] = item;
    }
    for (final item in local) {
      final id = getId(item);
      if (map.containsKey(id)) {
        // ignore: null_check_on_nullable_type_parameter
        map[id] = resolve(item, map[id] as T);
      } else {
        map[id] = item;
      }
    }
    return map.values.toList();
  }
}
