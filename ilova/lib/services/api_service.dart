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
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Token muddati o'tgan bo'lsa yoki xatolik
          return handler.next(error);
        },
      ),
    );
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
          if (search != null && search.isNotEmpty) 'search': search,
          if (genre != null && genre.isNotEmpty) 'genre': genre,
          if (status != null && status.isNotEmpty) 'status': status,
          if (year != null) 'year': year,
          if (sortBy != null) 'sort': sortBy,
        },
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).map((json) => AnimeModel.fromJson(json)).toList();
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
        return AnimeModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<EpisodeModel>> getAnimeEpisodes(dynamic animeId) async {
    try {
      final response = await _dio.get('${ApiConfig.animes}/$animeId/episodes');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).map((json) => EpisodeModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- MANGAS ---
  Future<List<MangaModel>> getMangas() async {
    try {
      final response = await _dio.get(ApiConfig.mangas);
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).map((json) => MangaModel.fromJson(json)).toList();
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
        return MangaModel.fromJson(response.data);
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
        return MangaChapterModel.fromJson(response.data);
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
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => CommentModel.fromJson(json, currentUserId: user?.id))
            .toList();
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
      if (response.statusCode == 200 && response.data['user'] != null) {
        final updatedUser = UserModel.fromJson(response.data['user']);
        await StorageService.saveUser(updatedUser);
        return updatedUser;
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

      if (response.statusCode == 200 && response.data['user'] != null) {
        final updatedUser = UserModel.fromJson(response.data['user']);
        await StorageService.saveUser(updatedUser);
        return updatedUser;
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

      if (response.statusCode == 200 && response.data['user'] != null) {
        final updatedUser = UserModel.fromJson(response.data['user']);
        await StorageService.saveUser(updatedUser);
        return updatedUser;
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
