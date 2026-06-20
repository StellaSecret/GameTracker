// lib/services/storage_service.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_data.dart';

class StorageService {
  static const _key = 'game_tracker_data';

  Future<AppData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      return AppData();
    }
    try {
      return AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e, stack) {
      developer.log(
        'StorageService: failed to parse saved data, starting fresh.',
        name: 'GameTracker',
        error: e,
        stackTrace: stack,
      );
      return AppData();
    }
  }

  Future<void> save(AppData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Export data as a JSON string (for Google Drive upload)
  String export(AppData data) => jsonEncode(data.toJson());

  /// Import data from a JSON string (from Google Drive download)
  AppData import(String json) =>
      AppData.fromJson(jsonDecode(json) as Map<String, dynamic>);

  Future<DateTime?> loadStatsUnlockUntil() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt('stats_unlock_until');
    if (ms == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> saveStatsUnlockUntil(DateTime? dt) async {
    final prefs = await SharedPreferences.getInstance();
    if (dt == null) {
      await prefs.remove('stats_unlock_until');
    } else {
      await prefs.setInt('stats_unlock_until', dt.millisecondsSinceEpoch);
    }
  }
}
