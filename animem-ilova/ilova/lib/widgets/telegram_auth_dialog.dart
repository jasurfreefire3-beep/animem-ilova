import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../utils/toast_utils.dart';
import 'telegram_logo.dart';

class TelegramAuthDialog extends StatefulWidget {
  const TelegramAuthDialog({Key? key}) : super(key: key);

  @override
  State<TelegramAuthDialog> createState() => _TelegramAuthDialogState();
}

class _TelegramAuthDialogState extends State<TelegramAuthDialog> {
  String? _sessionId;
  bool _isLoading = true;
  Timer? _pollTimer;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool _showQuickLogin = false;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final sid = await auth.createTelegramSession();
    
    if (mounted) {
      if (sid != null) {
        setState(() {
          _sessionId = sid;
          _isLoading = false;
        });
        _startPolling(sid);
      } else {
        setState(() {
          _sessionId = 'mobile_${DateTime.now().millisecondsSinceEpoch}';
          _isLoading = false;
        });
      }
    }
  }

  void _startPolling(String sid) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final res = await auth.checkTelegramStatus(sid);
      if (res['status'] == 'authorized') {
        timer.cancel();
        if (mounted) {
          ToastUtils.showSuccess(context, "Telegram orqali muvaffaqiyatli kirdingiz!");
          Navigator.pop(context, true);
        }
      }
    });
  }

  Future<void> _openTelegramBot() async {
    if (_sessionId == null) return;
    final botUrl = "https://t.me/Animem_register_bot?start=auth_$_sessionId";
    final uri = Uri.parse(botUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      ToastUtils.showInfo(context, "Botga ulanish: $botUrl");
    }
  }

  Future<void> _submitQuickLogin() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ToastUtils.showError(context, "Ismingizni kiriting");
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.simulateTelegramLogin(
      sessionId: _sessionId ?? 'tg_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      username: _usernameController.text.trim().isNotEmpty ? _usernameController.text.trim() : null,
    );
    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        _pollTimer?.cancel();
        ToastUtils.showSuccess(context, "Telegram orqali kirdingiz!");
        Navigator.pop(context, true);
      } else {
        ToastUtils.showError(context, auth.errorMessage ?? "Kirishda xatolik");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24),
                Row(
                  children: const [
                    TelegramLogo(size: 24),
                    SizedBox(width: 8),
                    Text(
                      "Telegram orqali kirish",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: Color(0xFF2AABEE)),
              )
            else if (!_showQuickLogin) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.telegram, size: 48, color: Color(0xFF2AABEE)),
                    const SizedBox(height: 8),
                    const Text(
                      "Rasmiy bot orqali tasdiqlash",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Quyidagi tugmani bosing va botda 'Boshlash' (Start) tugmasini bosing. Tizim avtomatik sizni hisobingizga kiritadi.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Botni ochish tugmasi
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _openTelegramBot,
                  icon: const TelegramLogo(size: 18),
                  label: const Text(
                    "Telegram Botni Ochish",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2AABEE),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Tezkor kirish
              TextButton(
                onPressed: () => setState(() => _showQuickLogin = true),
                child: const Text(
                  "Tezkor ma'lumotlar bilan kirish",
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ),
            ] else ...[
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Ismingiz",
                  hintText: "Ali Valiyev",
                  prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Telegram Username (ixtiyoriy)",
                  hintText: "@username",
                  prefixIcon: Icon(Icons.alternate_email, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitQuickLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2AABEE),
                  ),
                  child: const Text("Hisobga kirish", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _showQuickLogin = false),
                child: const Text(
                  "Bot orqali ochishga qaytish",
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
