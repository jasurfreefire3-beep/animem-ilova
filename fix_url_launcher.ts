import fs from 'fs';

let login = fs.readFileSync('ilova/lib/screens/auth/login_screen.dart', 'utf8');
let reg = fs.readFileSync('ilova/lib/screens/auth/register_screen.dart', 'utf8');

// Ensure launchMode is externalApplication or platformDefault and handle exception
const newGoogleLogin = `
  Future<void> _loginWithGoogle() async {
    final url = Uri.parse('https://animem.uz/api/auth/google/mobile-login');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      try {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      } catch (e2) {
        if (mounted) {
          ToastUtils.showError(context, 'Brauzerni ochib bo\\'lmadi: $e2');
        }
      }
    }
  }
`;

const newGoogleReg = `
  Future<void> _registerWithGoogle() async {
    final url = Uri.parse('https://animem.uz/api/auth/google/mobile-login');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      try {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      } catch (e2) {
        if (mounted) {
          ToastUtils.showError(context, 'Brauzerni ochib bo\\'lmadi: $e2');
        }
      }
    }
  }
`;

login = login.replace(/Future<void> _loginWithGoogle\(\) async \{[\s\S]*?\}/, newGoogleLogin.trim());
reg = reg.replace(/Future<void> _registerWithGoogle\(\) async \{[\s\S]*?\}/, newGoogleReg.trim());

fs.writeFileSync('ilova/lib/screens/auth/login_screen.dart', login);
fs.writeFileSync('ilova/lib/screens/auth/register_screen.dart', reg);

console.log('Fixed launchUrl handling');
