import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/toast_utils.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<void> _loginWithGoogle() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.loginWithGoogle();

    if (mounted) {
      if (success) {
        ToastUtils.showSuccess(context, "Google orqali muvaffaqiyatli kirdingiz!");
        Navigator.pop(context);
      } else {
        ToastUtils.showError(context, authProvider.errorMessage ?? "Google orqali kirishda xatolik");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hisobga Kirish"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Google Sign-In tugmasi (ichida logo bilan)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: authProvider.isLoading ? null : _loginWithGoogle,
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Google logosi tugma ichida
                      Image.asset(
                        'assets/images/logo.png',
                        height: 32,
                        width: 32,
                        errorBuilder: (_, __, ___) => const Icon(Icons.account_circle, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                  label: authProvider.isLoading
                      ? const Text("Kirilmoqda...")
                      : const Text("Google orqali kirish", style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Info text
              const Text(
                "Faqat Google hisobi orqali kirish mumkin",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 48),

              // Ro'yxatdan o'tishga havola
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Hisobingiz yo'qmi? ",
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      "Ro'yxatdan o'tish",
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
    );
  }
}
