import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../utils/toast_utils.dart';

class ForgotPasswordDialog extends StatefulWidget {
  final String? initialEmail;
  const ForgotPasswordDialog({Key? key, this.initialEmail}) : super(key: key);

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  int _step = 1; // 1: Email kiritish, 2: Kod va yangi parol
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ToastUtils.showError(context, "Iltimos, to'g'ri email manzil kiriting");
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await auth.forgotPasswordSendCode(email);
    setState(() => _isLoading = false);

    if (mounted) {
      if (res['success'] == true) {
        ToastUtils.showSuccess(context, res['message'] ?? "Kod emailga yuborildi!");
        setState(() => _step = 2);
      } else {
        ToastUtils.showError(context, res['message'] ?? "Xatolik yuz berdi");
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final newPassword = _passwordController.text;

    if (code.length < 4) {
      ToastUtils.showError(context, "Tasdiqlash kodini to'liq kiriting");
      return;
    }
    if (newPassword.length < 6) {
      ToastUtils.showError(context, "Yangi parol kamida 6 belgidan iborat bo'lsin");
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.forgotPasswordReset(
      email: email,
      code: code,
      newPassword: newPassword,
    );
    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ToastUtils.showSuccess(context, "Parol muvaffaqiyatli o'zgartirildi!");
        Navigator.pop(context, true);
      } else {
        ToastUtils.showError(context, auth.errorMessage ?? "Parolni tiklashda xatolik");
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Parolni Tiklash",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _step == 1
                  ? "Email manzilingizni kiriting. Biz sizga tasdiqlash kodini yuboramiz."
                  : "Emailingizga yuborilgan 6 xonali kod va yangi parolingizni kiriting.",
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),

            if (_step == 1) ...[
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "example@mail.com",
                  prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendCode,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Kodni yuborish"),
                ),
              ),
            ] else ...[
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, letterSpacing: 4, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: "123456",
                  prefixIcon: Icon(Icons.security, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Yangi parol (kamida 6 belgi)",
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
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _step = 1),
                    child: const Text("Emailni o'zgartirish", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _sendCode,
                    child: const Text("Kodni qayta yuborish", style: TextStyle(color: AppTheme.primary, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Parolni yangilash"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
