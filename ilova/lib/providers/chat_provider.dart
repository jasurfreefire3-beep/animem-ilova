import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  List<ChatMessageModel> _messages = [];
  ChatMessageModel? _replyingTo;
  bool _isSending = false;

  List<ChatMessageModel> get messages => _messages;
  ChatMessageModel? get replyingTo => _replyingTo;
  bool get isSending => _isSending;

  ChatProvider() {
    _chatService.initSocket();
    _chatService.messagesStream.listen((msgList) {
      _messages = msgList;
      notifyListeners();
    });
  }

  void setReply(ChatMessageModel? message) {
    _replyingTo = message;
    notifyListeners();
  }

  void clearReply() {
    _replyingTo = null;
    notifyListeners();
  }

  Future<bool> sendMessage(String content) async {
    if (content.trim().isEmpty) return false;

    _isSending = true;
    notifyListeners();

    final success = await _chatService.sendMessage(
      content: content,
      replyToId: _replyingTo?.id,
      replyToName: _replyingTo?.userName,
      replyToContent: _replyingTo?.content,
    );

    _isSending = false;
    if (success) {
      _replyingTo = null;
    }
    notifyListeners();
    return success;
  }
}
