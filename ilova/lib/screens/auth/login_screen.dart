import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/toast_utils.dart';
import '../../widgets/google_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;

  @override
  void dispose() { _email.dispose(); _code.dispose(); super.dispose(); }

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (!email.contains('@')) return ToastUtils.showError(context, 'Yaroqli email manzilini kiriting');
    final result = await context.read<AuthProvider>().sendEmailLoginCode(email);
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() => _codeSent = true);
      ToastUtils.showSuccess(context, result['message'] ?? 'Kod yuborildi');
    } else { ToastUtils.showError(context, result['message'] ?? 'Kodni yuborib bo\'lmadi'); }
  }

  Future<void> _verifyCode() async {
    if (_code.text.trim().length != 6) return ToastUtils.showError(context, '6 xonali kodni kiriting');
    final success = await context.read<AuthProvider>().verifyEmailLoginCode(_email.text, _code.text);
    if (mounted && !success) ToastUtils.showError(context, context.read<AuthProvider>().errorMessage ?? 'Kod xato');
  }

  Future<void> _loginWithGoogle() async {
    final success = await context.read<AuthProvider>().loginWithGoogle();
    if (mounted && !success) ToastUtils.showError(context, context.read<AuthProvider>().errorMessage ?? 'Google orqali kirishda xatolik');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Image.asset('assets/images/app_icon.png', height: 92, errorBuilder: (_, __, ___) => const Icon(Icons.movie_filter_rounded, size: 72, color: AppTheme.primary)),
        const SizedBox(height: 20),
        const Text('Animem Uz', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(_codeSent ? 'Emailingizga yuborilgan 6 xonali kodni kiriting' : 'Davom etish uchun hisobingizga kiring', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 32),
        TextField(controller: _email, keyboardType: TextInputType.emailAddress, enabled: !_codeSent && !auth.isLoading, decoration: const InputDecoration(labelText: 'Email manzili', prefixIcon: Icon(Icons.email_outlined))),
        if (_codeSent) ...[const SizedBox(height: 16), TextField(controller: _code, keyboardType: TextInputType.number, maxLength: 6, enabled: !auth.isLoading, decoration: const InputDecoration(labelText: 'Kirish kodi', prefixIcon: Icon(Icons.password_rounded)))],
        const SizedBox(height: 12),
        ElevatedButton(onPressed: auth.isLoading ? null : (_codeSent ? _verifyCode : _sendCode), child: Text(auth.isLoading ? 'Kutilmoqda...' : (_codeSent ? 'Ilovaga kirish' : 'Emailga kod yuborish'))),
        if (_codeSent) TextButton(onPressed: auth.isLoading ? null : _sendCode, child: const Text('Kodni qayta yuborish')),
        const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('yoki', style: TextStyle(color: AppTheme.textMuted))), Expanded(child: Divider())])),
        OutlinedButton.icon(
          onPressed: auth.isLoading ? null : _loginWithGoogle,
          icon: const GoogleLogo(size: 22),
          label: const Text('Google bilan kirish', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white24),
            backgroundColor: const Color(0xFF1E2028),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Email orqali kirish uchun akkaunt avval saytda yaratilgan bo‘lishi kerak. Google orqali kirish yangi akkauntni avtomatik yaratadi.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      ])),
    ))));
  }
}
