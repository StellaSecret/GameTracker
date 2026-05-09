// lib/models/app_data.dart
import 'game.dart';
import 'player.dart';

class AppData {
  final List<Game> games;
  final List<Player> players;
  final DateTime lastModified;
  /// IDs of games that have been deleted. Used to prevent Firestore echoes
  /// from restoring a deleted game during group sync.
  final List<String> deletedGameIds;

  AppData({
    List<Game>? games,
    List<Player>? players,
    DateTime? lastModified,
    List<String>? deletedGameIds,
  })  : games = games ?? [],
        players = players ?? [],
        lastModified = lastModified ?? DateTime.now(),
        deletedGameIds = deletedGameIds ?? [];

  Map<String, dynamic> toJson() => {
        'games': games.map((g) => g.toJson()).toList(),
        'players': players.map((p) => p.toJson()).toList(),
        'lastModified': lastModified.toIso8601String(),
        'deletedGameIds': deletedGameIds,
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
        deletedGameIds:
            List<String>.from(json['deletedGameIds'] as List? ?? []),
      );

  /// Merge two AppData instances, deduplicating by id, keeping the most recent entry.
  /// Deleted game IDs are propagated so that a game removed on one device is
  /// never re-introduced by a Firestore echo or another device's push.
  AppData mergeWith(AppData other) {
    // Union of tombstones from both sides.
    final allDeletedIds = <String>{
      ...deletedGameIds,
      ...other.deletedGameIds,
    };

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
    )
    // Remove any game whose ID appears in the tombstone set.
      ..removeWhere((g) => allDeletedIds.contains(g.id));

    return AppData(
      games: mergedGames,
      players: mergedPlayers,
      lastModified: lastModified.isAfter(other.lastModified)
          ? lastModified
          : other.lastModified,
      deletedGameIds: allDeletedIds.toList(),
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
