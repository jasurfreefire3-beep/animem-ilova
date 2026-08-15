class AnimeModel {
  final dynamic id;
  final String title;
  final String description;
  final String imageUrl;
  final String bannerUrl;
  final double rating;
  final int ratingCount;
  final String holati;
  final int? yil;
  final String studiyasi;
  final int qismlarSoni;
  final String janrlar;
  final String? tags;
  final String videoUrl;
  final bool tavsiya;
  final bool isBanner;
  final bool isAdult;
  final int korishlar;
  final String createdAt;

  AnimeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.bannerUrl,
    required this.rating,
    this.ratingCount = 0,
    this.holati = 'Davom etmoqda',
    this.yil,
    this.studiyasi = '',
    this.qismlarSoni = 0,
    this.janrlar = '',
    this.tags,
    this.videoUrl = '',
    this.tavsiya = false,
    this.isBanner = false,
    this.isAdult = false,
    this.korishlar = 0,
    required this.createdAt,
  });

  factory AnimeModel.fromJson(Map<String, dynamic> json) {
    double parsedRating = 0.0;
    if (json['rating'] != null) {
      if (json['rating'] is num) {
        parsedRating = (json['rating'] as num).toDouble();
      } else if (json['rating'] is String) {
        parsedRating = double.tryParse(json['rating']) ?? 0.0;
      }
    }

    return AnimeModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      bannerUrl: json['banner_url'] ?? json['image_url'] ?? '',
      rating: parsedRating,
      ratingCount: json['rating_count'] is int ? json['rating_count'] : 0,
      holati: json['holati'] ?? 'Davom etmoqda',
      yil: json['yil'] is int ? json['yil'] : int.tryParse('${json['yil']}'),
      studiyasi: json['studiyasi'] ?? '',
      qismlarSoni: json['qismlar_soni'] is int ? json['qismlar_soni'] : int.tryParse('${json['qismlar_soni']}') ?? 0,
      janrlar: json['janrlar'] ?? '',
      tags: json['tags'],
      videoUrl: json['video_url'] ?? '',
      tavsiya: json['tavsiya'] == true || json['tavsiya'] == 1,
      isBanner: json['is_banner'] == true || json['is_banner'] == 1,
      isAdult: json['is_adult'] == true || json['is_adult'] == 1,
      korishlar: json['korishlar'] is int ? json['korishlar'] : int.tryParse('${json['korishlar']}') ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }

  List<String> get genreList {
    if (janrlar.isEmpty) return [];
    return janrlar.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  String get slug {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r"[oO]['’`‘]"), 'o')
        .replaceAll(RegExp(r"[gG]['’`‘]"), 'g')
        .replaceAll(RegExp(r"[^a-z0-9\u0400-\u04FF]+", caseSensitive: false), '-')
        .replaceAll(RegExp(r"^-+|-+$"), '');
  }
}
