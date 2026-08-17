import fs from 'fs';

let authService = fs.readFileSync('ilova/lib/services/auth_service.dart', 'utf8');

const tokenMethod = `
  Future<Map<String, dynamic>> loginWithToken(String token) async {
    try {
      final response = await _dio.get(
        '/api/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data != null) {
        final rawUser = response.data['user'] ?? response.data;
        if (rawUser is Map<String, dynamic>) {
          final user = UserModel.fromJson(rawUser);
          await StorageService.saveToken(token);
          await StorageService.saveUser(user);
          return {'success': true, 'user': user};
        }
      }
      return {'success': false, 'message': 'Foydalanuvchi ma\\'lumotlarini yuklab bo\\'lmadi'};
    } catch (e) {
      return {'success': false, 'message': 'Xatolik yuz berdi'};
    }
  }
`;

if (!authService.includes('loginWithToken')) {
    authService = authService.replace('Future<Map<String, dynamic>> loginWithGoogle()', tokenMethod.trim() + '\n\n  Future<Map<String, dynamic>> loginWithGoogle()');
    fs.writeFileSync('ilova/lib/services/auth_service.dart', authService);
}

let authProvider = fs.readFileSync('ilova/lib/providers/auth_provider.dart', 'utf8');
const tokenProvider = `
  Future<bool> loginWithToken(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.loginWithToken(token);
    _isLoading = false;
    
    if (result['success'] == true && result['user'] != null) {
      _user = result['user'] as UserModel;
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] ?? "Xatolik yuz berdi";
      notifyListeners();
      return false;
    }
  }
`;

if (!authProvider.includes('loginWithToken')) {
    authProvider = authProvider.replace('Future<bool> loginWithGoogle()', tokenProvider.trim() + '\n\n  Future<bool> loginWithGoogle()');
    fs.writeFileSync('ilova/lib/providers/auth_provider.dart', authProvider);
}
console.log('Provider and Service patched');
