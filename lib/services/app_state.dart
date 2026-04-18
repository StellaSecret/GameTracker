// lib/services/app_state.dart
import 'package:flutter/foundation.dart';
import '../models/app_data.dart';
import '../models/game.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import 'storage_service.dart';
import 'google_drive_service.dart';

class AppState extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final GoogleDriveService driveService = GoogleDriveService();

  AppData _data = AppData();
  bool _isLoading = true;
  String? _syncMessage;

  bool get isLoading => _isLoading;
  String? get syncMessage => _syncMessage;

  List<Game> get games {
    final sorted = List<Game>.from(_data.games);
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sorted;
  }

  List<Player> get players {
    final sorted = List<Player>.from(_data.players);
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sorted;
  }

  // ── Init ────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    _data = await _storage.load();
    _isLoading = false;
    notifyListeners();
    // Try silent Google sign-in
    await driveService.signInSilently();
  }

  // ── Players ─────────────────────────────────────────────────────────────────

  Future<void> addPlayer(Player player) async {
    _data.players.add(player);
    await _persist();
  }

  Future<void> updatePlayer(Player player) async {
    final idx = _data.players.indexWhere((p) => p.id == player.id);
    if (idx >= 0) {
      _data.players[idx] = player;
      await _persist();
    }
  }

  Future<void> deletePlayer(String playerId) async {
    _data.players.removeWhere((p) => p.id == playerId);
    await _persist();
  }

  Player? findPlayer(String id) {
    try {
      return _data.players.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Games ───────────────────────────────────────────────────────────────────

  Future<void> addGame(Game game) async {
    _data.games.add(game);
    await _persist();
  }

  Future<void> updateGame(Game game) async {
    final idx = _data.games.indexWhere((g) => g.id == game.id);
    if (idx >= 0) {
      _data.games[idx] = game;
      await _persist();
    }
  }

  Future<void> deleteGame(String gameId) async {
    _data.games.removeWhere((g) => g.id == gameId);
    await _persist();
  }

  Game? findGame(String id) {
    try {
      return _data.games.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Sessions ────────────────────────────────────────────────────────────────

  Future<void> addSession(String gameId, GameSession session) async {
    final game = findGame(gameId);
    if (game == null) return;
    game.sessions.add(session);
    await _persist();
  }

  Future<void> deleteSession(String gameId, String sessionId) async {
    final game = findGame(gameId);
    if (game == null) return;
    game.sessions.removeWhere((s) => s.id == sessionId);
    await _persist();
  }

  // ── Persistence ─────────────────────────────────────────────────────────────

  Future<void> _persist() async {
    _data = AppData(
      games: _data.games,
      players: _data.players,
      lastModified: DateTime.now(),
    );
    await _storage.save(_data);
    notifyListeners();
  }

  // ── Drive Sync ──────────────────────────────────────────────────────────────

  Future<bool> syncToDrive() async {
    _syncMessage = 'Synchronisation en cours…';
    notifyListeners();

    final json = _storage.export(_data);
    final ok = await driveService.upload(json);

    _syncMessage = ok ? 'Synchronisé ✓' : 'Erreur: ${driveService.lastError}';
    notifyListeners();

    await Future.delayed(const Duration(seconds: 3));
    _syncMessage = null;
    notifyListeners();
    return ok;
  }

  Future<bool> syncFromDrive() async {
    _syncMessage = 'Téléchargement…';
    notifyListeners();

    final json = await driveService.download();
    if (json == null) {
      _syncMessage = 'Aucune donnée dans Drive.';
      notifyListeners();
      await Future.delayed(const Duration(seconds: 3));
      _syncMessage = null;
      notifyListeners();
      return false;
    }

    try {
      _data = _storage.import(json);
      await _storage.save(_data);
      _syncMessage = 'Données importées ✓';
      notifyListeners();
    } catch (e) {
      _syncMessage = 'Erreur import: $e';
      notifyListeners();
    }

    await Future.delayed(const Duration(seconds: 3));
    _syncMessage = null;
    notifyListeners();
    return true;
  }
}
