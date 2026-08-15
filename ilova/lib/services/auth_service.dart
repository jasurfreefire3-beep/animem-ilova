import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class AuthService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      headers: {'Content-Type': 'application/json'},
    ),
  );

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Email & Password orqali kirish
  Future<UserModel?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConfig.login,
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data['token'] != null) {
        final token = response.data['token'];
        final user = UserModel.fromJson(response.data['user']);

        await StorageService.saveToken(token);
        await StorageService.saveUser(user);
        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Ro'yxatdan o'tish
  Future<UserModel?> register(String name, String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConfig.register,
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data['token'] != null) {
        final token = response.data['token'];
        final user = UserModel.fromJson(response.data['user']);

        await StorageService.saveToken(token);
        await StorageService.saveUser(user);
        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Google orqali kirish
  Future<UserModel?> loginWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

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

      if (response.statusCode == 200 && response.data['token'] != null) {
        final token = response.data['token'];
        final user = UserModel.fromJson(response.data['user']);

        await StorageService.saveToken(token);
        await StorageService.saveUser(user);
        return user;
      }
      return null;
    } catch (e) {
      return null;
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

      if (response.statusCode == 200 && response.data['user'] != null) {
        final user = UserModel.fromJson(response.data['user']);
        await StorageService.saveUser(user);
        return user;
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
