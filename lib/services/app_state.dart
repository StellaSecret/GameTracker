import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_data.dart';
import '../models/entitlement.dart';
import '../models/game.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import 'storage_service.dart';
import 'google_drive_service.dart';
import 'purchase_service.dart';
import 'group_service.dart';

class AppState extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final GoogleDriveService driveService = GoogleDriveService();
  final PurchaseService purchaseService = PurchaseService();
  final GroupService groupService = GroupService();

  AppData _data = AppData();
  bool _isLoading = true;
  String? _syncMessage;

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

    // Étape 1 : Drive sign-in silencieux
    await driveService.signInSilently();

    // Dès que Drive est connecté, injecte l'email dans PurchaseService
    final driveEmail = driveService.currentUser?.email;
    if (driveEmail != null) {
      purchaseService.setConnectedEmail(driveEmail);
    }

    if (!kIsWeb) {
      // Étape 2 : Firebase sign-in silencieux (même compte Google)
      await groupService.signInSilently();

      // Injecte l'email Firebase si disponible
      final fbEmail = groupService.userEmail;
      if (fbEmail != null) {
        purchaseService.setConnectedEmail(fbEmail);
      }

      // Étape 3 : RevenueCat
      await purchaseService.init();
      purchaseService.addListener(notifyListeners);
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _groupSub?.cancel();
    if (!kIsWeb) purchaseService.removeListener(notifyListeners);
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

  Player? findPlayer(String id) {
    try {
      return _data.players.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Games ─────────────────────────────────────────────────────────────────

  String? canAddGame() {
    if (entitlement.canAddGame(_data.games.length)) return null;
    return 'Limite de ${Entitlement.freeGameLimit} jeux atteinte sur le plan gratuit.';
  }

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

  // ── Sessions ──────────────────────────────────────────────────────────────

  String? canAddSession(String gameId) {
    final game = findGame(gameId);
    if (game == null) return null;
    if (entitlement.canAddSession(game.sessions.length)) return null;
    return 'Limite de ${Entitlement.freeSessionLimit} parties par jeu atteinte sur le plan gratuit.';
  }

  Future<void> addSession(String gameId, GameSession session) async {
    final game = findGame(gameId);
    if (game == null) return;
    game.sessions.add(session);
    await _persist();
  }

  Future<void> updateSession(String gameId, GameSession session) async {
    final game = findGame(gameId);
    if (game == null) return;
    final idx = game.sessions.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      game.sessions[idx] = session;
      await _persist();
    }
  }

  Future<void> deleteSession(String gameId, String sessionId) async {
    final game = findGame(gameId);
    if (game == null) return;
    game.sessions.removeWhere((s) => s.id == sessionId);
    await _persist();
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _persist() async {
    _data = AppData(
      games: _data.games,
      players: _data.players,
      lastModified: DateTime.now(),
    );
    await _storage.save(_data);
    if (_activeGroupId != null && !kIsWeb) {
      await groupService.pushGroupData(_activeGroupId!, _data);
    }
    notifyListeners();
  }

  // ── Drive sync ────────────────────────────────────────────────────────────

  Future<bool> syncToDrive() async {
    // Injecte l'email Drive dans PurchaseService après connexion
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
    if (kIsWeb || !entitlement.canUseGroupSync) return null;
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
    if (kIsWeb || !entitlement.canUseGroupSync) return null;
    final id = await groupService.createGroup(name, _data);
    if (id != null) await joinGroup(id);
    return id;
  }

  Future<void> leaveGroup() async {
    if (_activeGroupId == null) return;
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
      _syncMessage = null;
      notifyListeners();
    });
  }
}
