import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/toast_utils.dart';
import '../../widgets/google_logo.dart';
import '../main_navigation_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _codeSent = false;
  bool _codeVerified = false;
  bool _isSendingCode = false;
  bool _isVerifyingCode = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  int _resendTimer = 0;
  Timer? _timer;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _code.dispose();
    _password.dispose();
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

  // 1. Emailga kod yuborish
  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      return ToastUtils.showError(context, 'Yaroqli email manzilini kiriting');
    }

    setState(() => _isSendingCode = true);
    final auth = context.read<AuthProvider>();
    final result = await auth.sendVerificationCode(email);
    setState(() => _isSendingCode = false);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() => _codeSent = true);
      _startTimer();
      ToastUtils.showSuccess(context, result['message'] ?? 'Tasdiqlash kodi emailingizga yuborildi!');
    } else {
      ToastUtils.showError(context, result['message'] ?? 'Kodni yuborib bo\'lmadi');
    }
  }

  // 2. Kodni tekshirish
  Future<void> _verifyCode() async {
    final email = _email.text.trim();
    final code = _code.text.trim();

    if (code.length != 6) {
      return ToastUtils.showError(context, '6 xonali tasdiqlash kodini kiriting');
    }

    setState(() => _isVerifyingCode = true);
    final auth = context.read<AuthProvider>();
    final result = await auth.verifyCode(email, code);
    setState(() => _isVerifyingCode = false);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() => _codeVerified = true);
      ToastUtils.showSuccess(context, 'Email muvaffaqiyatli tasdiqlandi!');
    } else {
      ToastUtils.showError(context, result['message'] ?? 'Tasdiqlash kodi xato');
    }
  }

  // 3. To'liq ro'yxatdan o'tish
  Future<void> _register() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final code = _code.text.trim();
    final password = _password.text;
    final confirmPassword = _confirmPassword.text;

    if (name.isEmpty) {
      return ToastUtils.showError(context, 'Ismingizni kiriting');
    }
    if (password.length < 6) {
      return ToastUtils.showError(context, 'Parol kamida 6 ta belgidan iborat bo\'lishi kerak');
    }
    if (password != confirmPassword) {
      return ToastUtils.showError(context, 'Parollar bir-biriga mos kelmadi');
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.registerVerified(
      name: name,
      email: email,
      password: password,
      code: code,
    );

    if (!mounted) return;

    if (success) {
      ToastUtils.showSuccess(context, 'Muvaffaqiyatli ro\'yxatdan o\'tdingiz!');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } else {
      ToastUtils.showError(context, auth.errorMessage ?? 'Ro\'yxatdan o\'tishda xatolik');
    }
  }

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
                    ToastUtils.showError(context, 'Kodni to\'liq kiriting');
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
                    ToastUtils.showError(context, auth.errorMessage ?? 'Kod noto\'g\'ri');
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F1015),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1015),
        elevation: 0,
        title: const Text("Ro'yxatdan o'tish", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  // Logo
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.25),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.movie_filter_rounded,
                            size: 54,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Animem Uz',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Yangi hisob yaratish',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // Google ro'yxatdan o'tish
                  OutlinedButton.icon(
                    onPressed: auth.isLoading ? null : _registerWithGoogle,
                    icon: const GoogleLogo(size: 20),
                    label: const Text(
                      'Google bilan davom etish',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF323648)),
                      backgroundColor: const Color(0xFF1E202B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      children: const [
                        Expanded(child: Divider(color: Color(0xFF2A2D3A))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('yoki email orqali', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        ),
                        Expanded(child: Divider(color: Color(0xFF2A2D3A))),
                      ],
                    ),
                  ),

                  // 1-qadam: Email kiritish
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

                  // 2-qadam: Kod yuborilgan bo'lsa va hali tasdiqlanmagan bo'lsa
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

                  // 3-qadam: Kod tasdiqlangandan so'ng Ism va Parol kiritish
                  if (_codeVerified) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: _name,
                      enabled: !auth.isLoading,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Ismingiz yoki Taxallus',
                        labelStyle: const TextStyle(color: AppTheme.textMuted),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.textMuted),
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
                      controller: _password,
                      obscureText: _obscurePassword,
                      enabled: !auth.isLoading,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Parol (kamida 6 ta belgi)',
                        labelStyle: const TextStyle(color: AppTheme.textMuted),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textMuted),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppTheme.textMuted,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
                        labelText: 'Parolni tasdiqlang',
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

                    // Ro'yxatdan o'tishni yakunlash tugmasi
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _register,
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
                                "Ro'yxatdan o'tishni yakunlash",
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
                                _codeSent ? "Kodni tasdiqlash" : "Tasdiqlash kodini olish",
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Kirish havolasi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Allaqachon hisobingiz bormi? ",
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
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
                            fontSize: 14,
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
      ),
    );
  }
}

