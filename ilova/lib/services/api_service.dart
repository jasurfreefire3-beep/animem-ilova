import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/anime_model.dart';
import '../models/episode_model.dart';
import '../models/manga_model.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Referer': 'https://animem.uz/',
          'Origin': 'https://animem.uz',
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36 AnimemUzApp/1.0',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = StorageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Referer'] = 'https://animem.uz/';
          options.headers['Origin'] = 'https://animem.uz';
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  // Helper for parsing lists
  List<T> _parseList<T>(dynamic data, T Function(Map<String, dynamic>) parser) {
    if (data == null) return [];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(parser).toList();
    }
    if (data is Map) {
      if (data['data'] is List) {
        return (data['data'] as List).whereType<Map<String, dynamic>>().map(parser).toList();
      }
      if (data['animes'] is List) {
        return (data['animes'] as List).whereType<Map<String, dynamic>>().map(parser).toList();
      }
      if (data['episodes'] is List) {
        return (data['episodes'] as List).whereType<Map<String, dynamic>>().map(parser).toList();
      }
      if (data['mangas'] is List) {
        return (data['mangas'] as List).whereType<Map<String, dynamic>>().map(parser).toList();
      }
      if (data['results'] is List) {
        return (data['results'] as List).whereType<Map<String, dynamic>>().map(parser).toList();
      }
    }
    return [];
  }

  // --- ANIMES ---
  Future<List<AnimeModel>> getAnimes({
    String? search,
    String? genre,
    String? status,
    int? year,
    String? sortBy,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.animes,
        queryParameters: {
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          if (genre != null && genre.isNotEmpty && genre != 'Barchasi') 'genre': genre,
          if (status != null && status.isNotEmpty) 'status': status,
          if (year != null) 'year': year,
          if (sortBy != null) 'sort': sortBy,
        },
      );

      if (response.statusCode == 200) {
        return _parseList(response.data, (json) => AnimeModel.fromJson(json));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<AnimeModel?> getAnimeById(dynamic id) async {
    try {
      final response = await _dio.get('${ApiConfig.animes}/$id');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          if (data['data'] is Map<String, dynamic>) {
            return AnimeModel.fromJson(data['data']);
          }
          if (data['anime'] is Map<String, dynamic>) {
            return AnimeModel.fromJson(data['anime']);
          }
          return AnimeModel.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<EpisodeModel>> getAnimeEpisodes(dynamic animeId) async {
    try {
      final response = await _dio.get('${ApiConfig.animes}/$animeId/episodes');
      if (response.statusCode == 200) {
        return _parseList(response.data, (json) => EpisodeModel.fromJson(json));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- MANGAS ---
  Future<List<MangaModel>> getMangas({String? search, String? genre}) async {
    try {
      final response = await _dio.get(
        ApiConfig.mangas,
        queryParameters: {
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          if (genre != null && genre.isNotEmpty && genre != 'Barchasi') 'genre': genre,
        },
      );
      if (response.statusCode == 200) {
        return _parseList(response.data, (json) => MangaModel.fromJson(json));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<MangaModel?> getMangaById(dynamic id) async {
    try {
      final response = await _dio.get('${ApiConfig.mangas}/$id');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          if (data['data'] is Map<String, dynamic>) {
            return MangaModel.fromJson(data['data']);
          }
          if (data['manga'] is Map<String, dynamic>) {
            return MangaModel.fromJson(data['manga']);
          }
          return MangaModel.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<MangaChapterModel?> getMangaChapter(dynamic mangaId, int chapterNumber) async {
    try {
      final response = await _dio.get('${ApiConfig.mangas}/$mangaId/chapters/$chapterNumber');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          if (data['data'] is Map<String, dynamic>) {
            return MangaChapterModel.fromJson(data['data']);
          }
          if (data['chapter'] is Map<String, dynamic>) {
            return MangaChapterModel.fromJson(data['chapter']);
          }
          return MangaChapterModel.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- COMMENTS & REPLIES ---
  Future<List<CommentModel>> getAnimeComments(dynamic animeId) async {
    try {
      final user = StorageService.getUser();
      final response = await _dio.get('${ApiConfig.animes}/$animeId/comments');
      if (response.statusCode == 200) {
        return _parseList(response.data, (json) => CommentModel.fromJson(json, currentUserId: user?.id));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> postAnimeComment(dynamic animeId, String content) async {
    try {
      final user = StorageService.getUser();
      final response = await _dio.post(
        '${ApiConfig.animes}/$animeId/comments',
        data: {
          'user_id': user?.id,
          'user_name': user?.name ?? 'Foydalanuvchi',
          'content': content,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> replyComment(dynamic commentId, String content) async {
    try {
      final response = await _dio.post(
        '/api/comments/$commentId/reply',
        data: {'content': content},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleCommentLike(dynamic commentId) async {
    try {
      final response = await _dio.post('/api/comments/$commentId/like');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- RATINGS ---
  Future<bool> rateAnime(dynamic animeId, int rating) async {
    try {
      final response = await _dio.post(
        '/api/animes/$animeId/rate',
        data: {'rating': rating},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- USER PROFILE & FAVORITES ---
  Future<UserModel?> updateProfile({
    required String name,
    String? bio,
    String? telegram,
    String? instagram,
    String? tiktok,
    String? youtube,
    String? discord,
  }) async {
    try {
      final response = await _dio.put(
        ApiConfig.userProfile,
        data: {
          'name': name,
          'bio': bio,
          'telegram': telegram,
          'instagram': instagram,
          'tiktok': tiktok,
          'youtube': youtube,
          'discord': discord,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data['user'] ?? response.data['data'] ?? response.data;
        if (userData is Map<String, dynamic>) {
          final updatedUser = UserModel.fromJson(userData);
          await StorageService.saveUser(updatedUser);
          return updatedUser;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> uploadAvatarFromDevice(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final response = await _dio.post(
        ApiConfig.userAvatar,
        data: {'avatar_url': base64Image},
      );

      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data['user'] ?? response.data['data'] ?? response.data;
        if (userData is Map<String, dynamic>) {
          final updatedUser = UserModel.fromJson(userData);
          await StorageService.saveUser(updatedUser);
          return updatedUser;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> uploadBannerFromDevice(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      final currentUser = StorageService.getUser();

      final response = await _dio.put(
        ApiConfig.userProfile,
        data: {
          'name': currentUser?.name ?? 'Foydalanuvchi',
          'banner_url': base64Image,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data['user'] ?? response.data['data'] ?? response.data;
        if (userData is Map<String, dynamic>) {
          final updatedUser = UserModel.fromJson(userData);
          await StorageService.saveUser(updatedUser);
          return updatedUser;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateFavorites(List<dynamic> favorites) async {
    try {
      final response = await _dio.post(
        ApiConfig.userFavorites,
        data: {'favorites': favorites},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
