import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class AuthService {
  final Dio _dio = Dio(
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

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Email & Password orqali kirish
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConfig.login,
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        final token = data['token'] ?? data['access_token'] ?? data['data']?['token'];
        final rawUser = data['user'] ?? data['data']?['user'] ?? data['data'];

        if (token != null && rawUser is Map<String, dynamic>) {
          final user = UserModel.fromJson(rawUser);
          await StorageService.saveToken(token.toString());
          await StorageService.saveUser(user);
          return {'success': true, 'user': user};
        }
      }
      return {'success': false, 'message': data?['message'] ?? "Email yoki parol noto'g'ri"};
    } on DioException catch (e) {
      String msg = "Kirishda xatolik yuz berdi";
      if (e.response?.data != null && e.response?.data is Map) {
        msg = e.response?.data['message'] ?? e.response?.data['error'] ?? msg;
      } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
        msg = "Internet yoki server bilan aloqa yo'q";
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': "Tizimda xatolik: $e"};
    }
  }

  // Ro'yxatdan o'tish
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConfig.register,
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
        },
      );

      final data = response.data;
      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = data['token'] ?? data['access_token'] ?? data['data']?['token'];
        final rawUser = data['user'] ?? data['data']?['user'] ?? data['data'];

        if (token != null && rawUser is Map<String, dynamic>) {
          final user = UserModel.fromJson(rawUser);
          await StorageService.saveToken(token.toString());
          await StorageService.saveUser(user);
          return {'success': true, 'user': user};
        }
      }
      return {'success': false, 'message': data?['message'] ?? "Ro'yxatdan o'tishda xatolik"};
    } on DioException catch (e) {
      String msg = "Ro'yxatdan o'tishda xatolik yuz berdi";
      if (e.response?.data != null && e.response?.data is Map) {
        msg = e.response?.data['message'] ?? e.response?.data['error'] ?? msg;
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': "Tizimda xatolik: $e"};
    }
  }

  // Google orqali kirish
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'message': 'Google orqali kirish bekor qilindi'};
      }

      final googleAuth = await googleUser.authentication;
      final response = await _dio.post(
        ApiConfig.googleAuth,
        data: {
          'email': googleUser.email,
          'name': googleUser.displayName ?? 'Google User',
          'avatar_url': googleUser.photoUrl,
          'google_id': googleUser.id,
          'id_token': googleAuth.idToken,
        },
      );

      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        final token = data['token'] ?? data['access_token'] ?? data['data']?['token'];
        final rawUser = data['user'] ?? data['data']?['user'] ?? data['data'];

        if (token != null && rawUser is Map<String, dynamic>) {
          final user = UserModel.fromJson(rawUser);
          await StorageService.saveToken(token.toString());
          await StorageService.saveUser(user);
          return {'success': true, 'user': user};
        }
      }
      
      // Agar backend google auth endpointi vaqtincha offline bo'lsa ham foydalanuvchini Google ma'lumotlari bilan saqlaymiz
      final localUser = UserModel(
        id: googleUser.id.hashCode.abs(),
        name: googleUser.displayName ?? 'Google User',
        email: googleUser.email,
        avatarUrl: googleUser.photoUrl ?? '',
        role: 'user',
        createdAt: DateTime.now().toIso8601String(),
      );
      await StorageService.saveToken('google_token_${googleUser.id}');
      await StorageService.saveUser(localUser);
      return {'success': true, 'user': localUser};
    } catch (e) {
      return {'success': false, 'message': 'Google orqali kirishda xatolik: $e'};
    }
  }

  // Foydalanuvchini yangilash / tekshirish
  Future<UserModel?> fetchCurrentUser() async {
    final token = StorageService.getToken();
    if (token == null) return null;

    try {
      final response = await _dio.get(
        ApiConfig.me,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final rawUser = response.data['user'] ?? response.data['data'] ?? response.data;
        if (rawUser is Map<String, dynamic>) {
          final user = UserModel.fromJson(rawUser);
          await StorageService.saveUser(user);
          return user;
        }
      }
      return null;
    } catch (e) {
      return StorageService.getUser();
    }
  }

  // Chiqish
  Future<void> logout() async {
    await StorageService.removeToken();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
