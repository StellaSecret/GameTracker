import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import '../models/app_data.dart';
import '../models/entitlement.dart';
import '../models/game.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import 'google_drive_service.dart';
import 'group_service.dart';
import 'purchase_service.dart';
import 'storage_service.dart';

class AppState extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final GoogleDriveService driveService = GoogleDriveService();
  final PurchaseService purchaseService = PurchaseService();
  final GroupService groupService = GroupService();

  AppData _data = AppData();
  bool _isLoading = true;
  String? _syncMessage;
  bool _disposed = false;

  String? _activeGroupId;
  StreamSubscription<AppData?>? _groupSub;

  bool get isLoading => _isLoading;
  String? get syncMessage => _syncMessage;
  String? get activeGroupId => _activeGroupId;
  bool get isInGroup => _activeGroupId != null;
  Entitlement get entitlement => purchaseService.entitlement;

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

  Future<void> init() async {
    _data = await _storage.load();
    _isLoading = false;
    notifyListeners();

    await driveService.signInSilently();

    final driveEmail = driveService.currentUser?.email;
    if (driveEmail != null) {
      purchaseService.setConnectedEmail(driveEmail);
    }

    if (!kIsWeb) {
      await groupService.signInSilently();

      final fbEmail = groupService.userEmail;
      if (fbEmail != null) {
        purchaseService.setConnectedEmail(fbEmail);
      }

      await purchaseService.init();
      purchaseService.addListener(notifyListeners);
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _groupSub?.cancel();
    if (!kIsWeb) {
      purchaseService.removeListener(notifyListeners);
    }
    super.dispose();
  }

  // ── Players ───────────────────────────────────────────────────────────────

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

  Player? findPlayer(String id) =>
      _data.players.firstWhereOrNull((p) => p.id == id);

  // ── Games ─────────────────────────────────────────────────────────────────

  /// Always returns null (no game limit on free tier).
  String? canAddGame() => null;

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
    // Record the deletion as a tombstone so that mergeWith() never
    // re-introduces this game when a Firestore echo arrives.
    final updatedDeletedIds = List<String>.from(_data.deletedGameIds)
      ..add(gameId);
    _data = AppData(
      games: _data.games,
      players: _data.players,
      lastModified: DateTime.now(),
      deletedGameIds: updatedDeletedIds,
    );
    await _storage.save(_data);
    notifyListeners();
    // Push to group in the background – tombstone ensures the echo
    // from our own push cannot restore the deleted game.
    if (_activeGroupId != null && !kIsWeb) {
      groupService.pushGroupData(_activeGroupId!, _data);
    }
  }

  Game? findGame(String id) =>
      _data.games.firstWhereOrNull((g) => g.id == id);

  // ── Sessions ──────────────────────────────────────────────────────────────

  /// Always returns null (no session limit on free tier).
  String? canAddSession(String gameId) => null;

  Future<void> addSession(String gameId, GameSession session) async {
    final game = findGame(gameId);
    if (game == null) {
      return;
    }
    game.sessions.add(session);
    await _persist();
  }

  Future<void> updateSession(String gameId, GameSession session) async {
    final game = findGame(gameId);
    if (game == null) {
      return;
    }
    final idx = game.sessions.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      game.sessions[idx] = session;
      await _persist();
    }
  }

  Future<void> deleteSession(String gameId, String sessionId) async {
    final game = findGame(gameId);
    if (game == null) {
      return;
    }
    game.sessions.removeWhere((s) => s.id == sessionId);
    await _persist();
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _persist() async {
    _data = AppData(
      games: _data.games,
      players: _data.players,
      lastModified: DateTime.now(),
      deletedGameIds: _data.deletedGameIds,
    );
    await _storage.save(_data);
    notifyListeners();
    // Push to group in the background – do NOT await so that the UI
    // (e.g. Navigator.pop) is never blocked by the network call.
    if (_activeGroupId != null && !kIsWeb) {
      groupService.pushGroupData(_activeGroupId!, _data);
    }
  }

  // ── Drive sync ────────────────────────────────────────────────────────────

  Future<bool> syncToDrive() async {
    final driveEmail = driveService.currentUser?.email;
    if (driveEmail != null) {
      purchaseService.setConnectedEmail(driveEmail);
    }
    _setSyncMessage('Synchronisation en cours…');
    final json = _storage.export(_data);
    final ok = await driveService.upload(json);
    _setSyncMessage(ok ? '✓ Synchronisé' : '✗ Erreur: ${driveService.lastError}');
    return ok;
  }

  Future<bool> syncFromDrive() async {
    _setSyncMessage('Téléchargement…');
    final json = await driveService.download();
    if (json == null) {
      _setSyncMessage('Aucune donnée dans Drive.');
      return false;
    }
    try {
      final remote = _storage.import(json);
      _data = _data.mergeWith(remote);
      await _storage.save(_data);
      _setSyncMessage('✓ Données fusionnées');
      notifyListeners();
      return true;
    } catch (e) {
      _setSyncMessage('✗ Erreur import: $e');
      return false;
    }
  }

  // ── Group sync (premium, mobile only) ────────────────────────────────────

  Future<String?> joinGroup(String groupId) async {
    if (kIsWeb || !entitlement.canUseGroupSync) {
      return null;
    }
    _activeGroupId = groupId;
    _groupSub?.cancel();
    _groupSub = groupService.watchGroupData(groupId).listen((remote) {
      if (remote != null) {
        _data = _data.mergeWith(remote);
        _storage.save(_data);
        notifyListeners();
      }
    });
    notifyListeners();
    return groupId;
  }

  Future<String?> createAndJoinGroup(String name) async {
    if (kIsWeb || !entitlement.canUseGroupSync) {
      return null;
    }
    final id = await groupService.createGroup(name, _data);
    if (id != null) {
      await joinGroup(id);
    }
    return id;
  }

  Future<void> leaveGroup() async {
    if (_activeGroupId == null) {
      return;
    }
    await groupService.leaveGroup(_activeGroupId!);
    _groupSub?.cancel();
    _groupSub = null;
    _activeGroupId = null;
    notifyListeners();
  }

  void _setSyncMessage(String msg) {
    _syncMessage = msg;
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      if (!_disposed) {
        _syncMessage = null;
        notifyListeners();
      }
    });
  }
}
