// storage_service.dart persisted through SharedPreferences; unit tests use the
// in-memory mock store, so the whole file enters mutation scope.
// Run with: flutter test test/storage_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:game_tracker/models/app_data.dart';
import 'package:game_tracker/models/game.dart';
import 'package:game_tracker/models/game_mode.dart';
import 'package:game_tracker/models/player.dart';
import 'package:game_tracker/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('load returns an empty AppData when nothing was saved', () async {
    final service = StorageService();
    final data = await service.load();
    expect(data.games, isEmpty);
    expect(data.players, isEmpty);
  });

  test('save then load round-trips games and players', () async {
    final service = StorageService();
    await service.save(AppData(
      games: [Game(id: 'g1', name: 'Catan', mode: GameMode.points)],
      players: [Player(id: 'p1', name: 'Alice')],
    ));
    final restored = await service.load();
    expect(restored.games.single.id, 'g1');
    expect(restored.games.single.name, 'Catan');
    expect(restored.games.single.mode, GameMode.points);
    expect(restored.players.single.id, 'p1');
    expect(restored.players.single.name, 'Alice');
  });

  test('load swallows corrupted JSON and starts fresh', () async {
    SharedPreferences.setMockInitialValues({
      'game_tracker_data': '{definitely not json',
    });
    final service = StorageService();
    final data = await service.load();
    expect(data.games, isEmpty);
    expect(data.players, isEmpty);
  });

  test('clear removes the stored data', () async {
    final service = StorageService();
    await service.save(AppData(
      games: [Game(id: 'g1', name: 'Catan', mode: GameMode.points)],
    ));
    await service.clear();
    final data = await service.load();
    expect(data.games, isEmpty);
  });

  test('export and import round-trip', () {
    final service = StorageService();
    final json = service.export(AppData(
      games: [Game(id: 'g1', name: 'Catan', mode: GameMode.points)],
    ));
    final imported = service.import(json);
    expect(imported.games.single.id, 'g1');
    expect(imported.games.single.mode, GameMode.points);
  });

  test('loadStatsUnlockUntil returns null when unset', () async {
    final service = StorageService();
    expect(await service.loadStatsUnlockUntil(), isNull);
  });

  test('saveStatsUnlockUntil round-trips and null removes the key', () async {
    final service = StorageService();
    final dt = DateTime(2025, 1, 1);
    await service.saveStatsUnlockUntil(dt);
    expect(await service.loadStatsUnlockUntil(), dt);

    await service.saveStatsUnlockUntil(null);
    expect(await service.loadStatsUnlockUntil(), isNull);
  });
}