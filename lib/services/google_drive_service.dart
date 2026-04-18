// lib/services/google_drive_service.dart
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

enum SyncStatus { idle, syncing, success, error }

class GoogleDriveService {
  static const _fileName = 'game_tracker_data.json';
  static const _folderName = 'GameTracker';
  static const _mimeJson = 'application/json';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
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
    final account = _currentUser;
    if (account == null) return null;
    final authClient = await _googleSignIn.authenticatedClient();
    if (authClient == null) return null;
    return drive.DriveApi(authClient);
  }

  /// Gets or creates the GameTracker folder in Drive.
  Future<String?> _ensureFolder(drive.DriveApi api) async {
    final query =
        "name='$_folderName' and mimeType='application/vnd.google-apps.folder' and trashed=false";
    final result = await api.files.list(q: query, $fields: 'files(id,name)');
    if (result.files != null && result.files!.isNotEmpty) {
      return result.files!.first.id;
    }
    // Create folder
    final folder = drive.File()
      ..name = _folderName
      ..mimeType = 'application/vnd.google-apps.folder';
    final created = await api.files.create(folder);
    return created.id;
  }

  /// Upload (create or update) data to Google Drive.
  Future<bool> upload(String jsonData) async {
    _status = SyncStatus.syncing;
    try {
      final api = await _getDriveApi();
      if (api == null) throw Exception('Not authenticated');

      final folderId = await _ensureFolder(api);
      if (folderId == null) throw Exception('Could not create folder');

      // Check if file exists
      final query =
          "name='$_fileName' and '$folderId' in parents and trashed=false";
      final existing =
          await api.files.list(q: query, $fields: 'files(id,name)');

      final bytes = utf8.encode(jsonData);
      final media = drive.Media(
        Stream.fromIterable([bytes]),
        bytes.length,
        contentType: _mimeJson,
      );

      if (existing.files != null && existing.files!.isNotEmpty) {
        // Update existing file
        final fileId = existing.files!.first.id!;
        final metadata = drive.File()..name = _fileName;
        await api.files.update(metadata, fileId, uploadMedia: media);
      } else {
        // Create new file
        final metadata = drive.File()
          ..name = _fileName
          ..parents = [folderId]
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

  /// Download data from Google Drive.
  Future<String?> download() async {
    _status = SyncStatus.syncing;
    try {
      final api = await _getDriveApi();
      if (api == null) throw Exception('Not authenticated');

      final folderId = await _ensureFolder(api);
      if (folderId == null) throw Exception('Could not find folder');

      final query =
          "name='$_fileName' and '$folderId' in parents and trashed=false";
      final result =
          await api.files.list(q: query, $fields: 'files(id,name)');

      if (result.files == null || result.files!.isEmpty) {
        _status = SyncStatus.success;
        return null; // No data yet
      }

      final fileId = result.files!.first.id!;
      final media = await api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = await media.stream.toList();
      final content = utf8.decode(bytes.expand((b) => b).toList());
      _status = SyncStatus.success;
      return content;
    } catch (e) {
      _lastError = e.toString();
      _status = SyncStatus.error;
      return null;
    }
  }

  /// Share the GameTracker file with another user by email.
  Future<bool> shareWith(String email) async {
    try {
      final api = await _getDriveApi();
      if (api == null) return false;

      final folderId = await _ensureFolder(api);
      if (folderId == null) return false;

      final permission = drive.Permission()
        ..type = 'user'
        ..role = 'writer'
        ..emailAddress = email;

      await api.permissions.create(permission, folderId!,
          sendNotificationEmail: true);
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }
}
