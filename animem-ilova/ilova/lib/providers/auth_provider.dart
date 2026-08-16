import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _initUser();
  }

  void _initUser() {
    _user = StorageService.getUser();
    notifyListeners();
    checkAuth();
  }

  Future<void> checkAuth() async {
    final freshUser = await _authService.fetchCurrentUser();
    if (freshUser != null) {
      _user = freshUser;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(email, password);
    _isLoading = false;

    if (result['success'] == true && result['user'] != null) {
      _user = result['user'] as UserModel;
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] ?? "Email yoki parol noto'g'ri";
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> sendEmailLoginCode(String email) => _authService.sendEmailLoginCode(email);

  Future<bool> verifyEmailLoginCode(String email, String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final result = await _authService.verifyEmailLoginCode(email, code);
    _isLoading = false;
    if (result['success'] == true && result['user'] != null) {
      _user = result['user'] as UserModel;
      notifyListeners();
      return true;
    }
    _errorMessage = result['message'] ?? 'Kirishda xatolik';
    notifyListeners();
    return false;
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.register(name, email, password);
    _isLoading = false;

    if (result['success'] == true && result['user'] != null) {
      _user = result['user'] as UserModel;
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] ?? "Ro'yxatdan o'tishda xatolik yuz berdi";
      notifyListeners();
      return false;
    }
  }

  // Resend Email orqali tasdiqlangan ro'yxatdan o'tish
  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    return await _authService.sendVerificationCode(email);
  }

  Future<Map<String, dynamic>> verifyCode(String email, String code) async {
    return await _authService.verifyCode(email, code);
  }

  Future<bool> registerVerified({
    required String name,
    required String email,
    required String password,
    required String code,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.registerVerified(
      name: name,
      email: email,
      password: password,
      code: code,
    );
    _isLoading = false;

    if (result['success'] == true && result['user'] != null) {
      _user = result['user'] as UserModel;
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] ?? "Ro'yxatdan o'tishda xatolik yuz berdi";
      notifyListeners();
      return false;
    }
  }

  // Parolni tiklash
  Future<Map<String, dynamic>> forgotPasswordSendCode(String email) async {
    return await _authService.forgotPasswordSendCode(email);
  }

  Future<Map<String, dynamic>> forgotPasswordVerifyCode(String email, String code) async {
    return await _authService.forgotPasswordVerifyCode(email, code);
  }

  Future<bool> forgotPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.forgotPasswordReset(
      email: email,
      code: code,
      newPassword: newPassword,
    );
    _isLoading = false;

    if (result['success'] == true) {
      if (result['user'] != null) {
        _user = result['user'] as UserModel;
      }
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] ?? "Parolni yangilashda xatolik yuz berdi";
      notifyListeners();
      return false;
    }
  }

  // Telegram Auth
  Future<String?> createTelegramSession() async {
    return await _authService.createTelegramSession();
  }

  Future<Map<String, dynamic>> checkTelegramStatus(String sessionId) async {
    final res = await _authService.checkTelegramStatus(sessionId);
    if (res['status'] == 'authorized' && res['user'] != null) {
      _user = res['user'] as UserModel;
      notifyListeners();
    }
    return res;
  }

  Future<bool> simulateTelegramLogin({
    required String sessionId,
    required String name,
    String? username,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.simulateTelegramLogin(
      sessionId: sessionId,
      name: name,
      username: username,
      phone: phone,
    );
    _isLoading = false;

    if (result['success'] == true && result['user'] != null) {
      _user = result['user'] as UserModel;
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] ?? "Telegram orqali kirishda xatolik";
      notifyListeners();
      return false;
    }
  }

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.loginWithGoogle();
    _isLoading = false;

    if (result['success'] == true && result['user'] != null) {
      _user = result['user'] as UserModel;
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] ?? "Google orqali kirishda xatolik yuz berdi";
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    required String name,
    String? bio,
    String? telegram,
    String? instagram,
    String? tiktok,
    String? youtube,
    String? discord,
  }) async {
    _isLoading = true;
    notifyListeners();

    final updated = await _apiService.updateProfile(
      name: name,
      bio: bio,
      telegram: telegram,
      instagram: instagram,
      tiktok: tiktok,
      youtube: youtube,
      discord: discord,
    );

    _isLoading = false;
    if (updated != null) {
      _user = updated;
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  Future<bool> uploadAvatar(File imageFile) async {
    _isLoading = true;
    notifyListeners();

    final updated = await _apiService.uploadAvatarFromDevice(imageFile);
    _isLoading = false;

    if (updated != null) {
      _user = updated;
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  Future<bool> uploadBanner(File imageFile) async {
    _isLoading = true;
    notifyListeners();

    final updated = await _apiService.uploadBannerFromDevice(imageFile);
    _isLoading = false;

    if (updated != null) {
      _user = updated;
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }
}
