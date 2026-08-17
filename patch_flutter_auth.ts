import fs from 'fs';

let authService = fs.readFileSync('ilova/lib/services/auth_service.dart', 'utf8');

const tgCodeService = `
  Future<Map<String, dynamic>> loginWithTelegramCode(String code) async {
    try {
      final response = await _dio.post('/api/auth/telegram/code', data: {
        'code': code,
      });
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return {'error': e.response!.data['error'] ?? 'Noma\\'lum xatolik'};
      }
      return {'error': 'Tarmoq xatosi'};
    } catch (e) {
      return {'error': 'Xatolik yuz berdi'};
    }
  }
`;

authService = authService.replace('Future<String?> createTelegramSession() async {', tgCodeService + '\n  Future<String?> createTelegramSession() async {');
fs.writeFileSync('ilova/lib/services/auth_service.dart', authService);


let authProvider = fs.readFileSync('ilova/lib/providers/auth_provider.dart', 'utf8');

const tgCodeProvider = `
  Future<bool> loginWithTelegramCode(String code) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final res = await _authService.loginWithTelegramCode(code);
      if (res.containsKey('error')) {
        _errorMessage = res['error'];
        _setLoading(false);
        return false;
      }

      if (res.containsKey('token') && res.containsKey('user')) {
        _token = res['token'];
        _user = UserModel.fromJson(res['user']);
        await _authService.saveToken(_token!);
        await _authService.saveUser(_user!);
        _setLoading(false);
        notifyListeners();
        return true;
      }
      
      _errorMessage = 'Noma\\'lum xatolik';
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }
`;

authProvider = authProvider.replace('Future<String?> createTelegramSession() async {', tgCodeProvider + '\n  Future<String?> createTelegramSession() async {');
fs.writeFileSync('ilova/lib/providers/auth_provider.dart', authProvider);

console.log("Flutter auth patched");
