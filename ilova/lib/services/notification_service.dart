import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Bildirishnomalarni ishga tushirish
  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
  }

  // Bildirishnomalarga ruxsat so'rash
  Future<bool> requestPermissions() async {
    // Android uchun ruxsat so'rash
    final androidStatus = await Permission.notification.request();
    
    // iOS uchun ruxsat so'rash
    final iosStatus = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    return androidStatus.isGranted || (iosStatus ?? false);
  }

  // Yangi anime qo'shilganda bildirishnoma
  Future<void> showNewAnimeNotification(String animeName) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'anime_updates',
      'Anime Yangiliklari',
      channelDescription: 'Yangi animelar qo\'shilganda bildirishnomalar',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      0,
      '🎬 Yangi Anime!',
      '$animeName Animem.uz\'ga qo\'shildi!',
      platformChannelSpecifics,
    );
  }

  // Yangi epizod qo'shilganda bildirishnoma
  Future<void> showNewEpisodeNotification(
      String animeName, int episodeNumber) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'episode_updates',
      'Epizod Yangiliklari',
      channelDescription: 'Yangi epizodlar qo\'shilganda bildirishnomalar',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      1,
      '📺 Yangi Epizod!',
      '$animeName - $episodeNumber-qism chiqdi!',
      platformChannelSpecifics,
    );
  }

  // Bildirishnoma bosilganda
  void _onNotificationTap(NotificationResponse response) {
    // Bildirishnoma bosilganda qilinadigan amallar
    // Masalan, aniqlangan anime sahifasiga o'tish
    print('Bildirishnoma bosildi: ${response.payload}');
  }

  // Barcha bildirishnomalarni o'chirish
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}