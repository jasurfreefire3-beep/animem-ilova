import fs from 'fs';

// Update login_screen.dart to use the new Telegram image icon
let login = fs.readFileSync('ilova/lib/screens/auth/login_screen.dart', 'utf8');

const newTelegramButtonLogin = `
                  // Telegram Login Button
                  OutlinedButton.icon(
                    onPressed: auth.isLoading ? null : _loginWithTelegram,
                    icon: Image.asset('assets/images/telegram_icon.png', width: 22, height: 22, errorBuilder: (_,__,___) => const Icon(Icons.telegram, color: Color(0xFF0088CC), size: 24)),
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

// Replace old telegram button in login_screen.dart
login = login.replace(/OutlinedButton\.icon\([\s\S]*?_loginWithTelegram[\s\S]*?\);\n\s*\}/m, newTelegramButtonLogin.trim());
fs.writeFileSync('ilova/lib/screens/auth/login_screen.dart', login);

// Update register_screen.dart to use the new Telegram image icon
let reg = fs.readFileSync('ilova/lib/screens/auth/register_screen.dart', 'utf8');

const newTelegramButtonReg = `
                  // Telegram ro'yxatdan o'tish
                  OutlinedButton.icon(
                    onPressed: auth.isLoading ? null : _registerWithTelegram,
                    icon: Image.asset('assets/images/telegram_icon.png', width: 22, height: 22, errorBuilder: (_,__,___) => const Icon(Icons.telegram, color: Color(0xFF0088CC), size: 24)),
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

reg = reg.replace(/OutlinedButton\.icon\([\s\S]*?_registerWithTelegram[\s\S]*?\);\n\s*\}/m, newTelegramButtonReg.trim());
fs.writeFileSync('ilova/lib/screens/auth/register_screen.dart', reg);

console.log('Telegram buttons updated with custom icon asset');
