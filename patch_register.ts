import fs from 'fs';

let content = fs.readFileSync('ilova/lib/screens/auth/register_screen.dart', 'utf8');

// 1. Add url_launcher import
if (!content.includes('package:url_launcher/url_launcher.dart')) {
    content = content.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport 'package:url_launcher/url_launcher.dart';"
    );
}

// 2. Replace _registerWithGoogle with Telegram logic
const telegramLogic = `
  Future<void> _registerWithTelegram() async {
    final url = Uri.parse('https://t.me/Animem_register_bot?start=app');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      _showTelegramCodeDialog();
    } else {
      ToastUtils.showError(context, 'Telegram ochilmadi');
    }
  }

  void _showTelegramCodeDialog() {
    final codeController = TextEditingController();
    bool isLoading = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1B22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Telegram Kod', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Telegram botdan kelgan 6 xonali kodni kiriting:',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: codeController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFF23252F),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(ctx),
                child: const Text('Bekor qilish', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isLoading ? null : () async {
                  final code = codeController.text.trim();
                  if (code.length != 6) {
                    ToastUtils.showError(context, 'Kodni to\\'liq kiriting');
                    return;
                  }
                  
                  setState(() => isLoading = true);
                  final auth = context.read<AuthProvider>();
                  final success = await auth.loginWithTelegramCode(code);
                  
                  if (!mounted) return;
                  setState(() => isLoading = false);
                  
                  if (success) {
                    Navigator.pop(ctx);
                    ToastUtils.showSuccess(context, 'Muvaffaqiyatli kirdingiz!');
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                      (route) => false,
                    );
                  } else {
                    ToastUtils.showError(context, auth.errorMessage ?? 'Kod noto\\'g\\'ri');
                  }
                },
                child: isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                    : const Text('Tasdiqlash'),
              ),
            ],
          );
        }
      ),
    );
  }
`;

content = content.replace(/\/\/ Google orqali ro'yxatdan o'tish[\s\S]*?\}\s*\}\s*@override/g, telegramLogic.trim() + '\n\n  @override');

// 3. Replace Google button with Telegram button
const telegramButton = `
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

content = content.replace(/\/\/ Google ro'yxatdan o'tish[\s\S]*?OutlinedButton\.icon\([\s\S]*?\}\),\s*\),\s*\),/m, telegramButton.trim() + ',');

fs.writeFileSync('ilova/lib/screens/auth/register_screen.dart', content);
