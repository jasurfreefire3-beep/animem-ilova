import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';
import 'notification_service.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  final NotificationService _notificationService = NotificationService();
  bool _isConnected = false;

  // Socket.io bilan bog'lanish
  void connect() {
    if (_isConnected && _socket != null) return;

    try {
      _socket = IO.io(
        ApiConfig.wsUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .build(),
      );

      _socket!.connect();

      // Bog'lanish muvaffaqiyatli bo'lganda
      _socket!.onConnect((_) {
        print('WebSocket bilan bog\'landi');
        _isConnected = true;
      });

      // Bog'lanish uzilganda
      _socket!.onDisconnect((_) {
        print('WebSocket bilan bog\'lanish uzildi');
        _isConnected = false;
      });

      // Xatolik yuz berganda
      _socket!.onError((error) {
        print('WebSocket xatoligi: $error');
      });

      // Yangi anime qo'shilganda
      _socket!.on('new_anime', (data) {
        print('Yangi anime qo\'shildi: $data');
        if (data != null && data['title'] != null) {
          _notificationService.showNewAnimeNotification(data['title']);
        }
      });

      // Yangi epizod qo'shilganda
      _socket!.on('new_episode', (data) {
        print('Yangi epizod qo\'shildi: $data');
        if (data != null && data['anime_title'] != null && data['episode_number'] != null) {
          _notificationService.showNewEpisodeNotification(
            data['anime_title'],
            data['episode_number'],
          );
        }
      });

    } catch (e) {
      print('WebSocket bog\'lanish xatoligi: $e');
    }
  }

  // Bog'lanishni uzish
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
      print('WebSocket bog\'lanishi uzildi');
    }
  }

  // Bog'langanligini tekshirish
  bool get isConnected => _isConnected;
}