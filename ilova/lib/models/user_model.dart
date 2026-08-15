class UserModel {
  final dynamic id;
  final String name;
  final String role;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? bannerUrl;
  final String? bio;
  final String? telegram;
  final String? instagram;
  final String? tiktok;
  final String? youtube;
  final String? discord;
  final String? facebook;
  final String? vk;
  final List<dynamic>? favorites;
  final int? commentsCount;
  final String? createdAt;
  final String? lastSeen;

  UserModel({
    required this.id,
    required this.name,
    this.role = 'user',
    this.email,
    this.phone,
    this.avatarUrl,
    this.bannerUrl,
    this.bio,
    this.telegram,
    this.instagram,
    this.tiktok,
    this.youtube,
    this.discord,
    this.facebook,
    this.vk,
    this.favorites,
    this.commentsCount,
    this.createdAt,
    this.lastSeen,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<dynamic> favs = [];
    if (json['favorites'] != null) {
      if (json['favorites'] is List) {
        favs = json['favorites'];
      } else if (json['favorites'] is String) {
        // agar JSON string ko'rinishida kelsa
        try {
          favs = [];
        } catch (_) {}
      }
    }

    return UserModel(
      id: json['id'],
      name: json['name'] ?? 'Foydalanuvchi',
      role: json['role'] ?? 'user',
      email: json['email'],
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      bannerUrl: json['banner_url'],
      bio: json['bio'],
      telegram: json['telegram'],
      instagram: json['instagram'],
      tiktok: json['tiktok'],
      youtube: json['youtube'],
      discord: json['discord'],
      facebook: json['facebook'],
      vk: json['vk'],
      favorites: favs,
      commentsCount: json['comments_count'] is int ? json['comments_count'] : 0,
      createdAt: json['created_at'],
      lastSeen: json['last_seen'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'banner_url': bannerUrl,
      'bio': bio,
      'telegram': telegram,
      'instagram': instagram,
      'tiktok': tiktok,
      'youtube': youtube,
      'discord': discord,
      'facebook': facebook,
      'vk': vk,
      'favorites': favorites,
      'comments_count': commentsCount,
      'created_at': createdAt,
      'last_seen': lastSeen,
    };
  }

  UserModel copyWith({
    String? name,
    String? avatarUrl,
    String? bannerUrl,
    String? bio,
    String? telegram,
    String? instagram,
    String? tiktok,
    String? youtube,
    String? discord,
    List<dynamic>? favorites,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      role: role,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      bio: bio ?? this.bio,
      telegram: telegram ?? this.telegram,
      instagram: instagram ?? this.instagram,
      tiktok: tiktok ?? this.tiktok,
      youtube: youtube ?? this.youtube,
      discord: discord ?? this.discord,
      facebook: facebook,
      vk: vk,
      favorites: favorites ?? this.favorites,
      commentsCount: commentsCount,
      createdAt: createdAt,
      lastSeen: lastSeen,
    );
  }
}
