import 'dart:async';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';
import '../models/chat_message_model.dart';
import 'storage_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;

  IO.Socket? _socket;
  final StreamController<List<ChatMessageModel>> _messagesController =
      StreamController<List<ChatMessageModel>>.broadcast();

  Stream<List<ChatMessageModel>> get messagesStream => _messagesController.stream;
  List<ChatMessageModel> _messages = [];

  ChatService._internal();

  void initSocket() {
    if (_socket != null && _socket!.connected) return;

    try {
      _socket = IO.io(
        ApiConfig.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .build(),
      );

      _socket?.onConnect((_) {
        // Socket bog'landi
      });

      _socket?.on('previousMessages', (data) {
        if (data is List) {
          _messages = data.map((json) => ChatMessageModel.fromJson(json)).toList();
          _messagesController.add(_messages);
        }
      });

      _socket?.on('newMessage', (data) {
        if (data is Map<String, dynamic>) {
          final newMsg = ChatMessageModel.fromJson(data);
          // Duplicate tekshirish
          if (!_messages.any((m) => m.id.toString() == newMsg.id.toString())) {
            _messages.add(newMsg);
            _messagesController.add(_messages);
          }
        }
      });

      _socket?.onDisconnect((_) {
        // Socket uzildi
      });
    } catch (e) {
      // Socket xatolik
    }

    // REST orqali dastlabki xabarlarni olib turish (zaxira)
    fetchInitialMessages();
  }

  Future<void> fetchInitialMessages() async {
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
      final response = await dio.get('/api/chat/messages');
      if (response.statusCode == 200 && response.data is List) {
        _messages = (response.data as List)
            .map((json) => ChatMessageModel.fromJson(json))
            .toList();
        _messagesController.add(_messages);
      }
    } catch (_) {}
  }

  Future<bool> sendMessage({
    required String content,
    dynamic replyToId,
    String? replyToName,
    String? replyToContent,
  }) async {
    final user = StorageService.getUser();
    final token = StorageService.getToken();

    if (user == null || content.trim().isEmpty) return false;

    final msgData = {
      'user_id': user.id,
      'user_name': user.name,
      'avatar_url': user.avatarUrl,
      'content': content.trim(),
      'reply_to_id': replyToId,
      'reply_to_name': replyToName,
      'reply_to_content': replyToContent,
    };

    // REST API orqali sinxronlashtirish
    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      await dio.post('/api/chat/messages', data: msgData);
      return true;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
  }
}
