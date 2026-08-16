import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/toast_utils.dart';
import 'login_screen.dart';
import 'telegram_auth_screen.dart';

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

  Future<void> _registerWithGoogle() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.loginWithGoogle();

    if (mounted) {
      if (success) {
        ToastUtils.showSuccess(context, "Google orqali muvaffaqiyatli ro'yxatdan o'tdingiz!");
        Navigator.pop(context);
      } else {
        ToastUtils.showError(context, auth.errorMessage ?? "Google orqali ro'yxatdan o'tishda xatolik");
      }
    }
  }

  Future<void> _registerWithTelegram() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TelegramAuthScreen()),
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
                const SizedBox(height: 20),

                // Ijtimoiy tarmoqlar orqali ro'yxatdan o'tish
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppTheme.surfaceBorder)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text("yoki", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ),
                    Expanded(child: Divider(color: AppTheme.surfaceBorder)),
                  ],
                ),
                const SizedBox(height: 20),

                // Google va Telegram tugmalari
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Google tugmasi
                    Container(
                      height: 50,
                      width: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.surfaceBorder),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton.icon(
                        onPressed: _registerWithGoogle,
                        icon: const Icon(Icons.account_circle, color: Colors.white),
                        label: const Text("Google", style: TextStyle(color: Colors.white)),
                      ),
                    ),

                    // Telegram tugmasi
                    Container(
                      height: 50,
                      width: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.surfaceBorder),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton.icon(
                        onPressed: _registerWithTelegram,
                        icon: const Icon(Icons.send, color: Colors.blue),
                        label: const Text("Telegram", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
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
