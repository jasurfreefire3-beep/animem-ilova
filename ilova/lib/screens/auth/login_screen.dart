import 'package:flutter/material.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/toast_utils.dart';
import '../../widgets/google_logo.dart';
import '../main_navigation_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;

  

  Future<void> _loginWithEmailPassword() async {
    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || !email.contains('@')) {
      return ToastUtils.showError(context, 'Yaroqli email manzilini kiriting');
    }
    if (password.isEmpty) {
      return ToastUtils.showError(context, 'Parolni kiriting');
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.login(email, password);
    if (!mounted) return;

    if (success) {
      ToastUtils.showSuccess(context, 'Xush kelibsiz!');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } else {
      ToastUtils.showError(context, auth.errorMessage ?? 'Email yoki parol noto\'g\'ri');
    }
  }

  
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) async {
      if (uri.scheme == 'animem' && uri.host == 'auth') {
        final token = uri.queryParameters['token'];
        if (token != null) {
          final auth = context.read<AuthProvider>();
          final success = await auth.loginWithToken(token);
          if (mounted && success) {
            ToastUtils.showSuccess(context, 'Google orqali tizimga kirildi!');
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
              (route) => false,
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _loginWithGoogle() async {
    final url = Uri.parse('https://animem.uz/api/auth/google/mobile-login');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      try {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      } catch (e2) {
        if (mounted) {
          ToastUtils.showError(context, 'Brauzerni ochib bo\'lmadi: $e2');
        }
      }
    }
  } else {
      ToastUtils.showError(context, 'Brauzerni ochib bo\'lmadi');
    }
  }

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
          ToastUtils.showError(context, 'Brauzerni ochib bo\'lmadi: $e2');
        }
      }
    }
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.25),
                            blurRadius: 20,
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
                            size: 64,
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
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Davom etish uchun hisobingizga kiring',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Email input
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !auth.isLoading,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email manzili',
                      labelStyle: const TextStyle(color: AppTheme.textMuted),
                      prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.textMuted),
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
                  const SizedBox(height: 16),

                  // Password input
                  TextField(
                    controller: _password,
                    obscureText: _obscurePassword,
                    enabled: !auth.isLoading,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Parol',
                      labelStyle: const TextStyle(color: AppTheme.textMuted),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppTheme.textMuted,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
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
                  const SizedBox(height: 8),

                  // Forgot Password link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ForgotPasswordScreen(
                              initialEmail: _email.text.trim(),
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        "Parolni unutdingizmi?",
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Login Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _loginWithEmailPassword,
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
                              'Kirish',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),

                  // Divider "yoki"
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      children: const [
                        Expanded(child: Divider(color: Color(0xFF2A2D3A))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('yoki', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        ),
                        Expanded(child: Divider(color: Color(0xFF2A2D3A))),
                      ],
                    ),
                  ),

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

                  const SizedBox(height: 24),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Hisobingiz yo'qmi? ",
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          "Ro'yxatdan o'tish",
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
