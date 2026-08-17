import fs from 'fs';

// 1. Fix login_screen.dart
let loginFile = fs.readFileSync('ilova/lib/screens/auth/login_screen.dart', 'utf8');

const googleLoginLogic = `
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

  Future<void> _loginWithTelegram() async {`;

loginFile = loginFile.replace('Future<void> _loginWithTelegram() async {', googleLoginLogic);

const telegramButtonLogin = `
                  // Telegram Login Button
                  OutlinedButton.icon(
                    onPressed: auth.isLoading ? null : _loginWithTelegram,
                    icon: const Icon(Icons.telegram, color: Color(0xFF0088CC), size: 24),
                    label: const Text(
                      'Telegram bilan kirish',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF323648)),
                      backgroundColor: const Color(0xFF1E202B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
`;

const googleButtonLogin = `
                  // Google Login Button
                  OutlinedButton.icon(
                    onPressed: auth.isLoading ? null : _loginWithGoogle,
                    icon: const GoogleLogo(size: 22),
                    label: const Text(
                      'Google bilan kirish',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF323648)),
                      backgroundColor: const Color(0xFF1E202B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ${telegramButtonLogin}
`;

// It currently has OutlinedButton.icon with _loginWithGoogle but wait...
// In my previous patch I failed to replace it because of the regex. So it currently has:
// // Google Login Button
// OutlinedButton.icon(...)
// Let's replace the whole Google Login Button block with BOTH.

loginFile = loginFile.replace(/\/\/ Google Login Button[\s\S]*?OutlinedButton\.icon\([\s\S]*?\}\),\s*\),\s*\),/m, googleButtonLogin.trim() + ',');

fs.writeFileSync('ilova/lib/screens/auth/login_screen.dart', loginFile);


// 2. Fix register_screen.dart
let regFile = fs.readFileSync('ilova/lib/screens/auth/register_screen.dart', 'utf8');

const googleRegLogic = `
  Future<void> _registerWithGoogle() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithGoogle(); // google registers/logs in the same way via backend
    
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

  Future<void> _registerWithTelegram() async {`;

if (!regFile.includes('_registerWithGoogle')) {
    regFile = regFile.replace('Future<void> _registerWithTelegram() async {', googleRegLogic);
}

const telegramButtonReg = `
                  // Telegram ro'yxatdan o'tish
                  OutlinedButton.icon(
                    onPressed: auth.isLoading ? null : _registerWithTelegram,
                    icon: const Icon(Icons.telegram, color: Color(0xFF0088CC), size: 24),
                    label: const Text(
                      'Telegram bilan davom etish',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF323648)),
                      backgroundColor: const Color(0xFF1E202B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
`;

const googleButtonReg = `
                  // Google ro'yxatdan o'tish
                  OutlinedButton.icon(
                    onPressed: auth.isLoading ? null : _registerWithGoogle,
                    icon: const GoogleLogo(size: 20),
                    label: const Text(
                      'Google bilan davom etish',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF323648)),
                      backgroundColor: const Color(0xFF1E202B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ${telegramButtonReg}
`;

regFile = regFile.replace(/\/\/ Google ro'yxatdan o'tish[\s\S]*?OutlinedButton\.icon\([\s\S]*?\}\),\s*\),\s*\),/m, googleButtonReg.trim() + ',');
fs.writeFileSync('ilova/lib/screens/auth/register_screen.dart', regFile);

console.log("Patched both screens with Google & Telegram buttons");
