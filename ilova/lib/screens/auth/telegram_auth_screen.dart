import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/toast_utils.dart';
import '../../../services/auth_service.dart';

class TelegramAuthScreen extends StatefulWidget {
  const TelegramAuthScreen({Key? key}) : super(key: key);

  @override
  State<TelegramAuthScreen> createState() => _TelegramAuthScreenState();
}

class _TelegramAuthScreenState extends State<TelegramAuthScreen> {
  final AuthService _authService = AuthService();
  String? _sessionId;
  String _status = 'pending';
  Timer? _statusCheckTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTelegramAuth();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _startTelegramAuth() async {
    setState(() => _isLoading = true);
    
    // Sessiya yaratish
    final sessionResult = await _authService.createTelegramSession();
    if (sessionResult != null) {
      setState(() {
        _sessionId = sessionResult;
        _isLoading = false;
      });
      
      // Sessiya holatini kuzatish
      _startStatusCheck();
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ToastUtils.showError(context, "Telegram sessiyasini yaratib bo'lmadi");
        Navigator.pop(context);
      }
    }
  }

  Future<void> _openTelegramBot() async {
    const telegramBotUrl = 'https://t.me/Animem_register_bot';
    final uri = Uri.parse(telegramBotUrl);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ToastUtils.showError(context, "Telegram botni ochib bo'lmadi");
      }
    }
  }

  void _startStatusCheck() {
    if (_sessionId == null) return;
    
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final statusResult = await _authService.checkTelegramStatus(_sessionId!);
      
      if (statusResult['status'] == 'authorized') {
        timer.cancel();
        if (mounted) {
          ToastUtils.showSuccess(context, "Telegram orqali muvaffaqiyatli kirdingiz!");
          Navigator.pop(context, true);
        }
      } else if (statusResult['status'] == 'expired') {
        timer.cancel();
        if (mounted) {
          ToastUtils.showError(context, "Sessiya muddati tugadi");
          Navigator.pop(context);
        }
      } else if (statusResult['status'] == 'error') {
        timer.cancel();
        if (mounted) {
          ToastUtils.showError(context, statusResult['message'] ?? "Xatolik yuz berdi");
          Navigator.pop(context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Telegram orqali kirish"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Telegram logosi
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  size: 60,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 32),

              // Sarlavha
              const Text(
                "Telegram Bot orqali kirish",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Sessiya ID
              if (_sessionId != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Sessiya ID:",
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _sessionId!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Holat
              _buildStatusWidget(),
              const SizedBox(height: 32),

              // Yo'riqnoma
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Qanday qilib kirish mumkin:",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStep("1. @Animem_register_bot botga boring"),
                    _buildStep("2. /start buyrug'ini yuboring"),
                    _buildStep("3. Sessiya ID sini kiriting"),
                    _buildStep("4. Tizim avtomatik ravishda kiradi"),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Botni ochish tugmasi
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _openTelegramBot,
                  icon: const Icon(Icons.telegram, color: Colors.white),
                  label: const Text("Botni ochish"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bekor qilish tugmasi
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Bekor qilish"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusWidget() {
    if (_isLoading) {
      return const Column(
        children: [
          CircularProgressIndicator(color: AppTheme.primary),
          SizedBox(height: 16),
          Text(
            "Sessiya yaratilmoqda...",
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      );
    }

    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (_status) {
      case 'pending':
        statusText = "Kutilmoqda...";
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'authorized':
        statusText = "Muvaffaqiyatli!";
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'expired':
        statusText = "Muddati tugadi";
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        statusText = "Kutilmoqda...";
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(statusIcon, color: statusColor),
          const SizedBox(width: 12),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "• ",
            style: TextStyle(color: AppTheme.primary, fontSize: 16),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}