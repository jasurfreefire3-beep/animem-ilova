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
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.signIn();
      } catch (signInErr) {
        // Agar Google Sign In da platform exception bo'lsa
        return {'success': false, 'message': 'Google xizmatlariga ulanib bo\'lmadi: $signInErr'};
      }

      if (googleUser == null) {
        return {'success': false, 'message': 'Google orqali kirish bekor qilindi'};
      }

      try {
        final response = await _dio.post(
          ApiConfig.googleAuth,
          data: {
            'email': googleUser.email,
            'name': googleUser.displayName ?? 'Google User',
            'avatar_url': googleUser.photoUrl,
            'google_id': googleUser.id,
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
      } catch (backendErr) {
        // Server bilan bog'lanishda fallback
      }

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

  // --- RESEND EMAIL OTP VERIFICATION ---

  // 1. Ro'yxatdan o'tish uchun kod yuborish
  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    try {
      final response = await _dio.post(
        ApiConfig.sendCode,
        data: {'email': email.trim().toLowerCase()},
      );
      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        return {'success': true, 'message': data['message'] ?? 'Kod emailga yuborildi'};
      }
      return {'success': false, 'message': data?['error'] ?? 'Kodni yuborib bo\'lmadi'};
    } on DioException catch (e) {
      String msg = "Kodni yuborishda xatolik";
      if (e.response?.data != null && e.response?.data is Map) {
        msg = e.response?.data['error'] ?? e.response?.data['message'] ?? msg;
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }

  // 2. Email kodini tekshirish
  Future<Map<String, dynamic>> verifyCode(String email, String code) async {
    try {
      final response = await _dio.post(
        ApiConfig.verifyCode,
        data: {
          'email': email.trim().toLowerCase(),
          'code': code.trim(),
        },
      );
      final data = response.data;
      if (response.statusCode == 200 && data != null && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Kod to\'g\'ri tasdiqlandi'};
      }
      return {'success': false, 'message': data?['error'] ?? 'Kod noto\'g\'ri'};
    } on DioException catch (e) {
      String msg = "Kodni tekshirishda xatolik";
      if (e.response?.data != null && e.response?.data is Map) {
        msg = e.response?.data['error'] ?? e.response?.data['message'] ?? msg;
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }

  // 3. Tasdiqlangan email bilan to'liq ro'yxatdan o'tish
  Future<Map<String, dynamic>> registerVerified({
    required String name,
    required String email,
    required String password,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.registerVerified,
        data: {
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'code': code.trim(),
        },
      );
      final data = response.data;
      if ((response.statusCode == 200 || response.statusCode == 201) && data != null) {
        final token = data['token'];
        final rawUser = data['user'];
        if (token != null && rawUser is Map<String, dynamic>) {
          final user = UserModel.fromJson(rawUser);
          await StorageService.saveToken(token.toString());
          await StorageService.saveUser(user);
          return {'success': true, 'user': user};
        }
      }
      return {'success': false, 'message': data?['error'] ?? 'Ro\'yxatdan o\'tishda xatolik'};
    } on DioException catch (e) {
      String msg = "Ro'yxatdan o'tishda xatolik";
      if (e.response?.data != null && e.response?.data is Map) {
        msg = e.response?.data['error'] ?? e.response?.data['message'] ?? msg;
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }

  // --- FORGOT PASSWORD (PAROLNI TIKLASH) ---

  // 1. Parolni tiklash uchun kod yuborish
  Future<Map<String, dynamic>> forgotPasswordSendCode(String email) async {
    try {
      final response = await _dio.post(
        ApiConfig.forgotSendCode,
        data: {'email': email.trim().toLowerCase()},
      );
      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        return {'success': true, 'message': data['message'] ?? 'Tiklash kodi emailga yuborildi'};
      }
      return {'success': false, 'message': data?['error'] ?? 'Kodni yuborib bo\'lmadi'};
    } on DioException catch (e) {
      String msg = "Kodni yuborishda xatolik";
      if (e.response?.data != null && e.response?.data is Map) {
        msg = e.response?.data['error'] ?? e.response?.data['message'] ?? msg;
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }

  // 2. Parolni tiklash kodini tekshirish
  Future<Map<String, dynamic>> forgotPasswordVerifyCode(String email, String code) async {
    try {
      final response = await _dio.post(
        ApiConfig.forgotVerifyCode,
        data: {
          'email': email.trim().toLowerCase(),
          'code': code.trim(),
        },
      );
      final data = response.data;
      if (response.statusCode == 200 && data != null && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Kod to\'g\'ri'};
      }
      return {'success': false, 'message': data?['error'] ?? 'Kod noto\'g\'ri'};
    } on DioException catch (e) {
      String msg = "Kodni tekshirishda xatolik";
      if (e.response?.data != null && e.response?.data is Map) {
        msg = e.response?.data['error'] ?? e.response?.data['message'] ?? msg;
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }

  // 3. Yangi parol o'rnatish
  Future<Map<String, dynamic>> forgotPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.forgotReset,
        data: {
          'email': email.trim().toLowerCase(),
          'code': code.trim(),
          'newPassword': newPassword,
        },
      );
      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        final token = data['token'];
        final rawUser = data['user'];
        if (token != null && rawUser is Map<String, dynamic>) {
          final user = UserModel.fromJson(rawUser);
          await StorageService.saveToken(token.toString());
          await StorageService.saveUser(user);
          return {'success': true, 'user': user};
        }
        return {'success': true, 'message': data['message'] ?? 'Parol yangilandi'};
      }
      return {'success': false, 'message': data?['error'] ?? 'Parolni o\'zgartirib bo\'lmadi'};
    } on DioException catch (e) {
      String msg = "Parolni o'zgartirishda xatolik";
      if (e.response?.data != null && e.response?.data is Map) {
        msg = e.response?.data['error'] ?? e.response?.data['message'] ?? msg;
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }

  // --- TELEGRAM BOT AUTH ---

  // 1. Telegram sessiya yaratish
  Future<String?> createTelegramSession() async {
    try {
      final response = await _dio.get(ApiConfig.telegramSession);
      if (response.statusCode == 200 && response.data != null) {
        return response.data['sessionId'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 2. Telegram sessiya holatini tekshirish
  Future<Map<String, dynamic>> checkTelegramStatus(String sessionId) async {
    try {
      final response = await _dio.get('${ApiConfig.telegramStatus}/$sessionId');
      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        if (data['status'] == 'authorized' && data['token'] != null) {
          final rawUser = data['user'];
          if (rawUser is Map<String, dynamic>) {
            final user = UserModel.fromJson(rawUser);
            await StorageService.saveToken(data['token'].toString());
            await StorageService.saveUser(user);
            return {'status': 'authorized', 'user': user};
          }
        }
        return {'status': data['status'] ?? 'pending'};
      }
      return {'status': 'pending'};
    } catch (e) {
      return {'status': 'error', 'message': '$e'};
    }
  }

  // 3. Telegram orqali simulyatsiya / to'g'ridan-to'g'ri kirish
  Future<Map<String, dynamic>> simulateTelegramLogin({
    required String sessionId,
    required String name,
    String? username,
    String? phone,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.telegramSimulate,
        data: {
          'sessionId': sessionId,
          'first_name': name,
          'username': username,
          'phone': phone,
        },
      );
      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        final token = data['token'];
        final rawUser = data['user'];
        if (token != null && rawUser is Map<String, dynamic>) {
          final user = UserModel.fromJson(rawUser);
          await StorageService.saveToken(token.toString());
          await StorageService.saveUser(user);
          return {'success': true, 'user': user};
        }
      }
      return {'success': false, 'message': data?['error'] ?? 'Telegram orqali kirishda xatolik'};
    } catch (e) {
      return {'success': false, 'message': '$e'};
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
