class ApiConfig {
  // Asosiy server manzili (Sayt va Ilova bir xil backendda ishlaydi)
  static const String baseUrl = 'https://animem.uz';
  
  // Socket.IO manzili (Real-vaqtli chat uchun)
  static const String socketUrl = 'https://animem.uz';
  
  // WebSocket manzili (Bildirishnomalar uchun)
  static const String wsUrl = 'https://animem.uz';

  // API Yo'llari
  static const String animes = '/api/animes';
  static const String mangas = '/api/mangas';
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String googleAuth = '/api/auth/google';
  static const String sendCode = '/api/auth/send-code';
  static const String verifyCode = '/api/auth/verify-code';
  static const String registerVerified = '/api/auth/register-verified';
  static const String forgotSendCode = '/api/auth/forgot-password-send-code';
  static const String forgotVerifyCode = '/api/auth/forgot-password-verify-code';
  static const String forgotReset = '/api/auth/forgot-password-reset';
  static const String telegramSession = '/api/auth/telegram/session';
  static const String telegramStatus = '/api/auth/telegram/status';
  static const String telegramSimulate = '/api/auth/telegram/simulate';
  static const String me = '/api/auth/me';
  static const String userProfile = '/api/user/profile';
  static const String userAvatar = '/api/user/avatar';
  static const String userFavorites = '/api/user/favorites';
  static const String chatMessages = '/api/chat/messages';
  static const String recentComments = '/api/comments/recent';
  static const String notifications = '/api/notifications';

  // Yordamchi metod: To'liq URL yasash
  static String fullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('/')) {
      return '$baseUrl$path';
    }
    return '$baseUrl/$path';
  }
}
