class CommentReplyModel {
  final dynamic id;
  final dynamic userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final String createdAt;

  CommentReplyModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.createdAt,
  });

  factory CommentReplyModel.fromJson(Map<String, dynamic> json) {
    return CommentReplyModel(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'] ?? 'Foydalanuvchi',
      userAvatar: json['user_avatar'] ?? json['avatar_url'],
      content: json['content'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class CommentModel {
  final dynamic id;
  final dynamic animeId;
  final dynamic mangaId;
  final dynamic userId;
  final String userName;
  final String? userAvatar;
  final String content;
  int likes;
  int dislikes;
  bool isLiked;
  bool isDisliked;
  final List<CommentReplyModel> replies;
  final String createdAt;

  CommentModel({
    required this.id,
    this.animeId,
    this.mangaId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    this.likes = 0,
    this.dislikes = 0,
    this.isLiked = false,
    this.isDisliked = false,
    this.replies = const [],
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json, {dynamic currentUserId}) {
    List<CommentReplyModel> parsedReplies = [];
    if (json['replies'] != null && json['replies'] is List) {
      parsedReplies = (json['replies'] as List)
          .map((r) => CommentReplyModel.fromJson(r))
          .toList();
    }

    bool userLiked = false;
    bool userDisliked = false;
    if (currentUserId != null) {
      if (json['liked_users'] is List) {
        userLiked = (json['liked_users'] as List).contains(currentUserId) ||
            (json['liked_users'] as List).contains(currentUserId.toString());
      }
      if (json['disliked_users'] is List) {
        userDisliked = (json['disliked_users'] as List).contains(currentUserId) ||
            (json['disliked_users'] as List).contains(currentUserId.toString());
      }
    }

    return CommentModel(
      id: json['id'],
      animeId: json['anime_id'],
      mangaId: json['manga_id'],
      userId: json['user_id'],
      userName: json['user_name'] ?? 'Foydalanuvchi',
      userAvatar: json['user_avatar'] ?? json['avatar_url'],
      content: json['content'] ?? '',
      likes: json['likes'] is int ? json['likes'] : int.tryParse('${json['likes']}') ?? 0,
      dislikes: json['dislikes'] is int ? json['dislikes'] : int.tryParse('${json['dislikes']}') ?? 0,
      isLiked: userLiked,
      isDisliked: userDisliked,
      replies: parsedReplies,
      createdAt: json['created_at'] ?? '',
    );
  }
}
