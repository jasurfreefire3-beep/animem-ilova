import fs from 'fs';

// 1. Update login_screen.dart for Telegram mobile login redirect
let login = fs.readFileSync('ilova/lib/screens/auth/login_screen.dart', 'utf8');
const newTelegramLogin = `
  Future<void> _loginWithTelegram() async {
    // Saytdagi kabi Telegram orqali kirish sahifasini brauzerda ochamiz
    final url = Uri.parse('https://animem.uz/api/auth/telegram/mobile-login');
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
login = login.replace(/Future<void> _loginWithTelegram\(\) async \{[\s\S]*?\}/, newTelegramLogin.trim());
fs.writeFileSync('ilova/lib/screens/auth/login_screen.dart', login);

// 2. Update register_screen.dart for Telegram mobile login redirect
let reg = fs.readFileSync('ilova/lib/screens/auth/register_screen.dart', 'utf8');
const newTelegramReg = `
  Future<void> _registerWithTelegram() async {
    final url = Uri.parse('https://animem.uz/api/auth/telegram/mobile-login');
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
reg = reg.replace(/Future<void> _registerWithTelegram\(\) async \{[\s\S]*?\}/, newTelegramReg.trim());
fs.writeFileSync('ilova/lib/screens/auth/register_screen.dart', reg);

// 3. Add backend endpoint in server.ts if not exists
let server = fs.readFileSync('server.ts', 'utf8');
const telegramServerEndpoint = `
// Telegram mobile login redirect (xuddi saytdagidek yoki bot orqali)
app.get("/api/auth/telegram/mobile-login", (req, res) => {
  // Bu yerda foydalanuvchini Telegram botga yoki saytdagi telegram login sahifasiga yo'naltiramiz
  res.redirect("https://t.me/Animem_register_bot?start=app");
});
`;

if (!server.includes('/api/auth/telegram/mobile-login')) {
  server = server.replace('app.post("/api/auth/google"', telegramServerEndpoint.trim() + '\n\napp.post("/api/auth/google"');
  fs.writeFileSync('server.ts', server);
}

console.log('Telegram web-style login configured for mobile app');
