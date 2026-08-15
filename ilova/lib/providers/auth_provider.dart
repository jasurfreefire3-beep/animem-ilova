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

    final loggedInUser = await _authService.login(email, password);
    _isLoading = false;

    if (loggedInUser != null) {
      _user = loggedInUser;
      notifyListeners();
      return true;
    } else {
      _errorMessage = "Email yoki parol noto'g'ri";
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final registeredUser = await _authService.register(name, email, password);
    _isLoading = false;

    if (registeredUser != null) {
      _user = registeredUser;
      notifyListeners();
      return true;
    } else {
      _errorMessage = "Ro'yxatdan o'tishda xatolik yuz berdi";
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final googleUser = await _authService.loginWithGoogle();
    _isLoading = false;

    if (googleUser != null) {
      _user = googleUser;
      notifyListeners();
      return true;
    } else {
      _errorMessage = "Google orqali kirish bekor qilindi";
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
