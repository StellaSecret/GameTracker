// lib/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_data.dart';

class StorageService {
  static const _key = 'game_tracker_data';

  Future<AppData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return AppData();
    try {
      return AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
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
}
