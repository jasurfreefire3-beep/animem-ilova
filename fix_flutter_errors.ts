import fs from 'fs';

// 1. Fix auth_provider.dart
let provider = fs.readFileSync('ilova/lib/providers/auth_provider.dart', 'utf8');

const updatedTelegramProvider = `
  Future<bool> loginWithTelegramCode(String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _authService.loginWithTelegramCode(code);
      if (res.containsKey('error')) {
        _errorMessage = res['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (res.containsKey('token') && res.containsKey('user')) {
        final token = res['token'].toString();
        _user = UserModel.fromJson(res['user']);
        await StorageService.saveToken(token);
        await StorageService.saveUser(_user!);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _errorMessage = 'Noma\\'lum xatolik';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
`;

provider = provider.replace(/Future<bool> loginWithTelegramCode\([\s\S]*?\}\s*\}/m, updatedTelegramProvider.trim());
fs.writeFileSync('ilova/lib/providers/auth_provider.dart', provider);

// 2. Fix login_screen.dart missing _loginWithGoogle
let login = fs.readFileSync('ilova/lib/screens/auth/login_screen.dart', 'utf8');
if (!login.includes('Future<void> _loginWithGoogle')) {
  const googleLoginMethod = `
  Future<void> _loginWithGoogle() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithGoogle();
    
    if (!mounted) return;
    
    if (success) {
      ToastUtils.showSuccess(context, 'Google orqali tizimga kirildi!');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } else {
      ToastUtils.showError(context, auth.errorMessage ?? 'Google orqali kirishda xatolik');
    }
  }

  Future<void> _loginWithTelegram()`;
  
  login = login.replace('Future<void> _loginWithTelegram()', googleLoginMethod.trim());
  fs.writeFileSync('ilova/lib/screens/auth/login_screen.dart', login);
}

// 3. Fix register_screen.dart missing _registerWithGoogle
let register = fs.readFileSync('ilova/lib/screens/auth/register_screen.dart', 'utf8');
if (!register.includes('Future<void> _registerWithGoogle')) {
  const googleRegMethod = `
  Future<void> _registerWithGoogle() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithGoogle(); 
    
    if (!mounted) return;
    
    if (success) {
      ToastUtils.showSuccess(context, "Google orqali muvaffaqiyatli ro'yxatdan o'tdingiz!");
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } else {
      ToastUtils.showError(context, auth.errorMessage ?? "Google orqali ro'yxatdan o'tishda xatolik");
    }
  }

  Future<void> _registerWithTelegram()`;

  register = register.replace('Future<void> _registerWithTelegram()', googleRegMethod.trim());
  fs.writeFileSync('ilova/lib/screens/auth/register_screen.dart', register);
}

console.log("Fixed all flutter compilation errors.");
