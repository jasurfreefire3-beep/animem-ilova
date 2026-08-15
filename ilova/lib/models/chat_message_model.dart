class ChatMessageModel {
  final dynamic id;
  final dynamic userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final dynamic replyToId;
  final String? replyToName;
  final String? replyToContent;
  final String createdAt;

  ChatMessageModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    this.replyToId,
    this.replyToName,
    this.replyToContent,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'] ?? 'Foydalanuvchi',
      userAvatar: json['user_avatar'] ?? json['avatar_url'],
      content: json['content'] ?? '',
      replyToId: json['reply_to_id'],
      replyToName: json['reply_to_name'],
      replyToContent: json['reply_to_content'],
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'content': content,
      'reply_to_id': replyToId,
      'reply_to_name': replyToName,
      'reply_to_content': replyToContent,
      'created_at': createdAt,
    };
  }
}
