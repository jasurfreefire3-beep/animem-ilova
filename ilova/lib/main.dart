import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/anime_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/favorites_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/websocket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Status bar va navigatsiya bar ranglarini qora qilish
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Local storage (SharedPreferences) ni ishga tushirish
  await StorageService.init();

  // Bildirishnomalarni ishga tushirish
  await NotificationService().initialize();

  // Bildirishnomalarga ruxsat so'rash
  await NotificationService().requestPermissions();

  // WebSocket bilan bog'lanish (real-vaqtli bildirishnomalar uchun)
  WebSocketService().connect();

  runApp(const AnimemApp());
}

class AnimemApp extends StatelessWidget {
  const AnimemApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AnimeProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'Animem Uz',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainNavigationScreen(),
      ),
    );
  }
}
