// lib/services/google_drive_service.dart
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;

enum SyncStatus { idle, syncing, success, error }

class GoogleDriveService {
  static const _fileName = 'game_tracker_data.json';
  static const _folderName = 'GameTracker';
  static const _mimeJson = 'application/json';

  // driveAppdataScope keeps the file hidden from the user's Drive UI and
  // requires no extra permissions review. Switch to driveFileScope only if
  // you need the file to be user-visible.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  GoogleSignInAccount? _currentUser;
  SyncStatus _status = SyncStatus.idle;
  String? _lastError;

  GoogleSignInAccount? get currentUser => _currentUser;
  SyncStatus get status => _status;
  String? get lastError => _lastError;
  bool get isSignedIn => _currentUser != null;

  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      return _currentUser != null;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  Future<bool> signInSilently() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      return _currentUser != null;
    } catch (_) {
      return false;
    }
  }

  Future<drive.DriveApi?> _getDriveApi() async {
    if (_currentUser == null) return null;
    final authClient = await _googleSignIn.authenticatedClient();
    if (authClient == null) return null;
    return drive.DriveApi(authClient);
  }

  /// Upload (create or update) data to the hidden appdata folder in Drive.
  Future<bool> upload(String jsonData) async {
    _status = SyncStatus.syncing;
    try {
      final api = await _getDriveApi();
      if (api == null) throw Exception('Non authentifié');

      // With driveAppdataScope, files live in the 'appDataFolder' space.
      const space = 'appDataFolder';

      final query = "name='$_fileName' and trashed=false";
      final existing = await api.files.list(
        q: query,
        spaces: space,
        $fields: 'files(id,name)',
      );

      final bytes = utf8.encode(jsonData);
      final media = drive.Media(
        Stream.fromIterable([bytes]),
        bytes.length,
        contentType: _mimeJson,
      );

      if (existing.files != null && existing.files!.isNotEmpty) {
        final fileId = existing.files!.first.id!;
        final metadata = drive.File()..name = _fileName;
        await api.files.update(metadata, fileId, uploadMedia: media);
      } else {
        final metadata = drive.File()
          ..name = _fileName
          ..parents = [space]
          ..mimeType = _mimeJson;
        await api.files.create(metadata, uploadMedia: media);
      }

      _status = SyncStatus.success;
      return true;
    } catch (e) {
      _lastError = e.toString();
      _status = SyncStatus.error;
      return false;
    }
  }

  /// Download data from the hidden appdata folder in Drive.
  Future<String?> download() async {
    _status = SyncStatus.syncing;
    try {
      final api = await _getDriveApi();
      if (api == null) throw Exception('Non authentifié');

      const space = 'appDataFolder';
      final query = "name='$_fileName' and trashed=false";
      final result = await api.files.list(
        q: query,
        spaces: space,
        $fields: 'files(id,name)',
      );

      if (result.files == null || result.files!.isEmpty) {
        _status = SyncStatus.success;
        return null;
      }

      final fileId = result.files!.first.id!;
      final media = await api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final chunks = await media.stream.toList();
      final content = utf8.decode(chunks.expand((b) => b).toList());
      _status = SyncStatus.success;
      return content;
    } catch (e) {
      _lastError = e.toString();
      _status = SyncStatus.error;
      return null;
    }
  }
}
