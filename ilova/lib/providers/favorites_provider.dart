import 'package:flutter/material.dart';
import '../models/anime_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class FavoritesProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<dynamic> _favoriteIds = [];

  List<dynamic> get favoriteIds => _favoriteIds;

  FavoritesProvider() {
    _loadFavorites();
  }

  void _loadFavorites() {
    final user = StorageService.getUser();
    if (user != null && user.favorites != null) {
      _favoriteIds = user.favorites!.map((e) {
        if (e is Map && e['id'] != null) return e['id'];
        return e;
      }).toList();
      notifyListeners();
    }
  }

  bool isFavorite(dynamic animeId) {
    return _favoriteIds.any((id) => id.toString() == animeId.toString());
  }

  Future<void> toggleFavorite(AnimeModel anime) async {
    final idStr = anime.id.toString();
    if (isFavorite(anime.id)) {
      _favoriteIds.removeWhere((id) => id.toString() == idStr);
    } else {
      _favoriteIds.add(anime.id);
    }
    notifyListeners();

    // Backendga yangilash
    final user = StorageService.getUser();
    if (user != null) {
      final updatedUser = user.copyWith(favorites: _favoriteIds);
      await StorageService.saveUser(updatedUser);
      await _apiService.updateFavorites(_favoriteIds);
    }
  }
}
