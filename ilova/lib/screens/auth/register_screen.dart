import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/toast_utils.dart';
import '../../../widgets/google_logo.dart';
import '../../../widgets/telegram_logo.dart';
import '../../../widgets/telegram_auth_dialog.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool _obscurePassword = true;
  bool _isCodeSent = false;
  bool _isLoading = false;
  int _timerSeconds = 60;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timerSeconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  // Step 1: Send verification code via Resend
  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await auth.sendVerificationCode(_emailController.text.trim());
    setState(() => _isLoading = false);

    if (mounted) {
      if (res['success'] == true) {
        ToastUtils.showSuccess(context, res['message'] ?? "Tasdiqlash kodi emailga yuborildi!");
        setState(() => _isCodeSent = true);
        _startTimer();
      } else {
        ToastUtils.showError(context, res['message'] ?? "Kodni yuborishda xatolik");
      }
    }
  }

  // Step 2: Complete registration with verified OTP code
  Future<void> _verifyAndRegister() async {
    final code = _codeController.text.trim();
    if (code.length < 4) {
      ToastUtils.showError(context, "Tasdiqlash kodini to'liq kiriting");
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.registerVerified(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      code: code,
    );
    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ToastUtils.showSuccess(context, "Ro'yxatdan muvaffaqiyatli o'tdingiz!");
        Navigator.pop(context);
      } else {
        ToastUtils.showError(context, auth.errorMessage ?? "Ro'yxatdan o'tishda xatolik");
      }
    }
  }

  Future<void> _googleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.loginWithGoogle();

    if (mounted) {
      if (success) {
        ToastUtils.showSuccess(context, "Google orqali kirdingiz!");
        Navigator.pop(context);
      } else if (authProvider.errorMessage != null) {
        ToastUtils.showError(context, authProvider.errorMessage!);
      }
    }
  }

  void _openTelegramAuth() async {
    final result = await showDialog(
      context: context,
      builder: (_) => const TelegramAuthDialog(),
    );
    if (result == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCodeSent ? "Emailni Tasdiqlash" : "Ro'yxatdan O'tish"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 50,
                    errorBuilder: (_, __, ___) => const Text(
                      "ANIMEM.UZ",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                if (!_isCodeSent) ...[
                  // Ism
                  const Text(
                    "Ismingiz",
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    validator: (val) => val == null || val.trim().isEmpty ? "Ism kiritilishi shart" : null,
                    decoration: const InputDecoration(
                      hintText: "Jasurbek",
                      prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  const Text(
                    "Email manzili",
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    validator: (val) => val == null || !val.contains('@') ? "To'g'ri email kiriting" : null,
                    decoration: const InputDecoration(
                      hintText: "example@mail.com",
                      prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Parol
                  const Text(
                    "Parol",
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    validator: (val) => val == null || val.length < 6 ? "Parol kamida 6 belgidan iborat bo'lsin" : null,
                    decoration: InputDecoration(
                      hintText: "••••••••",
                      prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppTheme.textMuted,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ro'yxatdan o'tish tugmasi
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendCode,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text("Davom etish (Kod olish)"),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Yoki ajratgich
                  Row(
                    children: const [
                      Expanded(child: Divider(color: AppTheme.surfaceBorder)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text("yoki", style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                      ),
                      Expanded(child: Divider(color: AppTheme.surfaceBorder)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Google orqali kirish
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _googleLogin,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.surfaceBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          GoogleLogo(size: 20),
                          SizedBox(width: 12),
                          Text(
                            "Google orqali ro'yxatdan o'tish",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Telegram orqali kirish
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _openTelegramAuth,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.surfaceBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          TelegramLogo(size: 20),
                          SizedBox(width: 12),
                          Text(
                            "Telegram orqali ulanish",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Step 2: Code Verification
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.mark_email_read_outlined, size: 40, color: AppTheme.primary),
                        const SizedBox(height: 8),
                        Text(
                          _emailController.text.trim(),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "manziliga 6 xonali tasdiqlash kodi yuborildi. Kodni quyida kiriting.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "Tasdiqlash kodi",
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 6, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: "123456",
                      prefixIcon: Icon(Icons.security, color: AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _isCodeSent = false),
                        child: const Text("Emailni o'zgartirish", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      ),
                      TextButton(
                        onPressed: _timerSeconds > 0 || _isLoading ? null : _sendCode,
                        child: Text(
                          _timerSeconds > 0 ? "Qayta yuborish (${_timerSeconds}s)" : "Kodni qayta yuborish",
                          style: TextStyle(
                            color: _timerSeconds > 0 ? AppTheme.textMuted : AppTheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyAndRegister,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text("Tasdiqlash va Kirish"),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Kirishga havola
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Allaqachon hisobingiz bormi? ",
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        "Kirish",
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
