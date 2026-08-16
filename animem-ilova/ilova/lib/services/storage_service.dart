import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class StorageService {
  static const String _keyToken = 'animem_auth_token';
  static const String _keyUser = 'animem_user_data';
  static const String _keyHistory = 'animem_watch_history';
  static const String _keyFavorites = 'animem_local_favorites';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token
  static Future<void> saveToken(String token) async {
    await _prefs?.setString(_keyToken, token);
  }

  static String? getToken() {
    return _prefs?.getString(_keyToken);
  }

  static Future<void> removeToken() async {
    await _prefs?.remove(_keyToken);
    await _prefs?.remove(_keyUser);
  }

  // User
  static Future<void> saveUser(UserModel user) async {
    await _prefs?.setString(_keyUser, jsonEncode(user.toJson()));
  }

  static UserModel? getUser() {
    final userStr = _prefs?.getString(_keyUser);
    if (userStr == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(userStr));
    } catch (_) {
      return null;
    }
  }

  // Watch History
  static Future<void> saveWatchHistory({
    required dynamic animeId,
    required String title,
    required String imageUrl,
    required int episodeNumber,
    required int positionSeconds,
  }) async {
    final historyList = getWatchHistory();
    historyList.removeWhere((item) => item['anime_id'].toString() == animeId.toString());
    
    historyList.insert(0, {
      'anime_id': animeId,
      'title': title,
      'image_url': imageUrl,
      'episode_number': episodeNumber,
      'position_seconds': positionSeconds,
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Faqat so'nggi 50 tasini saqlaymiz
    final trimmed = historyList.take(50).toList();
    await _prefs?.setString(_keyHistory, jsonEncode(trimmed));
  }

  static List<Map<String, dynamic>> getWatchHistory() {
    final str = _prefs?.getString(_keyHistory);
    if (str == null) return [];
    try {
      final List decoded = jsonDecode(str);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> clearWatchHistory() async {
    await _prefs?.remove(_keyHistory);
  }
}
