import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/toast_utils.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ro'yxatdan O'tish"),
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
                  onPressed: authProvider.isLoading ? null : _registerWithGoogle,
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
                      ? const Text("Ro'yxatdan o'tilmoqda...")
                      : const Text("Google orqali ro'yxatdan o'tish", style: TextStyle(fontSize: 16)),
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
                "Faqat Google hisobi orqali ro'yxatdan o'tish mumkin",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 48),

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
    );
  }
}
