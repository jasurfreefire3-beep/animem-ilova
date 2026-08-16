import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/toast_utils.dart';
import '../main_navigation_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({Key? key, this.initialEmail}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _codeSent = false;
  bool _codeVerified = false;
  bool _isSendingCode = false;
  bool _isVerifyingCode = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  int _resendTimer = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _email.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendTimer = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        _timer?.cancel();
      }
    });
  }

  // 1. Kod yuborish
  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      return ToastUtils.showError(context, 'Yaroqli email manzilini kiriting');
    }

    setState(() => _isSendingCode = true);
    final auth = context.read<AuthProvider>();
    final result = await auth.forgotPasswordSendCode(email);
    setState(() => _isSendingCode = false);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() => _codeSent = true);
      _startTimer();
      ToastUtils.showSuccess(context, result['message'] ?? 'Parolni tiklash kodi emailingizga yuborildi!');
    } else {
      ToastUtils.showError(context, result['message'] ?? 'Kodni yuborib bo\'lmadi');
    }
  }

  // 2. Kodni tekshirish
  Future<void> _verifyCode() async {
    final email = _email.text.trim();
    final code = _code.text.trim();

    if (code.length != 6) {
      return ToastUtils.showError(context, '6 xonali kodni kiriting');
    }

    setState(() => _isVerifyingCode = true);
    final auth = context.read<AuthProvider>();
    final result = await auth.forgotPasswordVerifyCode(email, code);
    setState(() => _isVerifyingCode = false);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() => _codeVerified = true);
      ToastUtils.showSuccess(context, 'Kod tasdiqlandi! Yangi parolni kiriting');
    } else {
      ToastUtils.showError(context, result['message'] ?? 'Kod noto\'g\'ri');
    }
  }

  // 3. Yangi parol saqlash
  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    final code = _code.text.trim();
    final newPass = _newPassword.text;
    final confirmPass = _confirmPassword.text;

    if (newPass.length < 6) {
      return ToastUtils.showError(context, 'Parol kamida 6 ta belgidan iborat bo\'lishi kerak');
    }
    if (newPass != confirmPass) {
      return ToastUtils.showError(context, 'Parollar bir-biriga mos kelmadi');
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.forgotPasswordReset(
      email: email,
      code: code,
      newPassword: newPass,
    );

    if (!mounted) return;

    if (success) {
      ToastUtils.showSuccess(context, 'Parol muvaffaqiyatli yangilandi va tizimga kirildi!');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } else {
      ToastUtils.showError(context, auth.errorMessage ?? 'Parolni yangilashda xatolik');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F1015),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1015),
        elevation: 0,
        title: const Text('Parolni tiklash', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_reset_rounded, size: 36, color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Parolni unutdingizmi?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Akkauntingizga ulangan emailni kiriting. Biz sizga parolni tiklash kodini yuboramiz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  // Email kiritish
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_codeVerified && !auth.isLoading && !_isSendingCode,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email manzili',
                      labelStyle: const TextStyle(color: AppTheme.textMuted),
                      prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.textMuted),
                      suffixIcon: _codeVerified
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : (!_codeSent
                              ? TextButton(
                                  onPressed: _isSendingCode ? null : _sendCode,
                                  child: _isSendingCode
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                                      : const Text('Kod olish', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                )
                              : null),
                      filled: true,
                      fillColor: const Color(0xFF181A22),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2B2E3D)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2B2E3D)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                      ),
                    ),
                  ),

                  // Kod kiritish qismi
                  if (_codeSent && !_codeVerified) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: _code,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: const TextStyle(color: Colors.white, letterSpacing: 3, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Emailga borgan 6 xonali kod',
                        labelStyle: const TextStyle(color: AppTheme.textMuted),
                        prefixIcon: const Icon(Icons.shield_outlined, color: AppTheme.textMuted),
                        counterText: '',
                        suffixIcon: TextButton(
                          onPressed: _isVerifyingCode ? null : _verifyCode,
                          child: _isVerifyingCode
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                              : const Text('Tasdiqlash', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF181A22),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2B2E3D)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2B2E3D)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _resendTimer > 0 || _isSendingCode ? null : _sendCode,
                        child: Text(
                          _resendTimer > 0 ? "Kodni qayta yuborish (${_resendTimer}s)" : "Kodni qayta yuborish",
                          style: TextStyle(
                            color: _resendTimer > 0 ? AppTheme.textMuted : AppTheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Yangi parol kiritish qismi
                  if (_codeVerified) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: _newPassword,
                      obscureText: _obscureNewPassword,
                      enabled: !auth.isLoading,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Yangi parol (kamida 6 ta belgi)',
                        labelStyle: const TextStyle(color: AppTheme.textMuted),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textMuted),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppTheme.textMuted,
                          ),
                          onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF181A22),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2B2E3D)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2B2E3D)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _confirmPassword,
                      obscureText: _obscureConfirmPassword,
                      enabled: !auth.isLoading,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Yangi parolni tasdiqlang',
                        labelStyle: const TextStyle(color: AppTheme.textMuted),
                        prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppTheme.textMuted),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppTheme.textMuted,
                          ),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF181A22),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2B2E3D)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2B2E3D)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Text(
                                'Parolni yangilash',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],

                  if (!_codeVerified) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSendingCode
                            ? null
                            : (_codeSent ? _verifyCode : _sendCode),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSendingCode || _isVerifyingCode
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                _codeSent ? 'Kodni tasdiqlash' : 'Tiklash kodini olish',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
