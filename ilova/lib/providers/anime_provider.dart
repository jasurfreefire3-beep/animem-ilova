import 'package:flutter/material.dart';
import '../models/anime_model.dart';
import '../models/manga_model.dart';
import '../services/api_service.dart';

class AnimeProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<AnimeModel> _allAnimes = [];
  List<AnimeModel> _animes = [];
  List<AnimeModel> _banners = [];
  List<AnimeModel> _top100 = [];
  List<AnimeModel> _recommended = [];
  List<MangaModel> _mangas = [];

  bool _isLoading = false;
  String _selectedGenre = 'Barchasi';
  String _searchQuery = '';

  List<AnimeModel> get animes => _animes;
  List<AnimeModel> get banners => _banners;
  List<AnimeModel> get top100 => _top100;
  List<AnimeModel> get recommended => _recommended;
  List<MangaModel> get mangas => _mangas;
  bool get isLoading => _isLoading;
  String get selectedGenre => _selectedGenre;
  String get searchQuery => _searchQuery;

  AnimeProvider() {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final all = await _apiService.getAnimes();
      _allAnimes = all;
      _animes = all;

      _banners = all.where((a) => a.isBanner || a.tavsiya).take(6).toList();
      if (_banners.isEmpty && all.isNotEmpty) {
        _banners = all.take(5).toList();
      }

      _recommended = all.where((a) => a.tavsiya).toList();
      if (_recommended.isEmpty && all.isNotEmpty) {
        _recommended = all.take(10).toList();
      }

      // Top 100
      final sorted = List<AnimeModel>.from(all);
      sorted.sort((a, b) => b.rating.compareTo(a.rating));
      _top100 = sorted.take(100).toList();

      // Mangalar
      _mangas = await _apiService.getMangas();
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchAnimes(String query, {String? genre}) async {
    _searchQuery = query;
    if (genre != null) _selectedGenre = genre;
    _isLoading = true;
    notifyListeners();

    try {
      final results = await _apiService.getAnimes(
        search: query.trim().isNotEmpty ? query.trim() : null,
        genre: _selectedGenre == 'Barchasi' ? null : _selectedGenre,
      );

      if (results.isNotEmpty) {
        _animes = results;
      } else if (query.trim().isNotEmpty || _selectedGenre != 'Barchasi') {
        // Fallback to local filter if remote returned empty
        final q = query.trim().toLowerCase();
        _animes = _allAnimes.where((a) {
          final matchesQuery = q.isEmpty ||
              a.title.toLowerCase().contains(q) ||
              a.description.toLowerCase().contains(q) ||
              a.janrlar.toLowerCase().contains(q);
          final matchesGenre = _selectedGenre == 'Barchasi' ||
              a.janrlar.toLowerCase().contains(_selectedGenre.toLowerCase());
          return matchesQuery && matchesGenre;
        }).toList();
      } else {
        _animes = _allAnimes;
      }
    } catch (_) {
      final q = query.trim().toLowerCase();
      _animes = _allAnimes.where((a) {
        final matchesQuery = q.isEmpty ||
            a.title.toLowerCase().contains(q) ||
            a.description.toLowerCase().contains(q);
        final matchesGenre = _selectedGenre == 'Barchasi' ||
            a.janrlar.toLowerCase().contains(_selectedGenre.toLowerCase());
        return matchesQuery && matchesGenre;
      }).toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  void setGenre(String genre) {
    _selectedGenre = genre;
    searchAnimes(_searchQuery, genre: genre);
  }
}
