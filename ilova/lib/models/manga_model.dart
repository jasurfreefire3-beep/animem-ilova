class MangaModel {
  final dynamic id;
  final String title;
  final String description;
  final String coverUrl;
  final String? bannerUrl;
  final String? author;
  final String? artist;
  final String janrlar;
  final String? type;
  final String holati;
  final int? releasedYear;
  final double rating;
  final int korishlar;
  final int chaptersCount;
  final String createdAt;

  MangaModel({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    this.bannerUrl,
    this.author,
    this.artist,
    this.janrlar = '',
    this.type = 'Manga',
    this.holati = 'Davom etmoqda',
    this.releasedYear,
    this.rating = 0.0,
    this.korishlar = 0,
    this.chaptersCount = 0,
    required this.createdAt,
  });

  factory MangaModel.fromJson(Map<String, dynamic> json) {
    double parsedRating = 0.0;
    if (json['rating'] != null) {
      if (json['rating'] is num) {
        parsedRating = (json['rating'] as num).toDouble();
      } else if (json['rating'] is String) {
        parsedRating = double.tryParse(json['rating']) ?? 0.0;
      }
    }

    return MangaModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      coverUrl: json['cover_url'] ?? '',
      bannerUrl: json['banner_url'],
      author: json['author'],
      artist: json['artist'],
      janrlar: json['janrlar'] ?? '',
      type: json['type'] ?? 'Manga',
      holati: json['holati'] ?? 'Davom etmoqda',
      releasedYear: json['released_year'] is int
          ? json['released_year']
          : int.tryParse('${json['released_year']}'),
      rating: parsedRating,
      korishlar: json['korishlar'] is int ? json['korishlar'] : int.tryParse('${json['korishlar']}') ?? 0,
      chaptersCount: json['chapters_count'] is int
          ? json['chapters_count']
          : int.tryParse('${json['chapters_count']}') ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }

  List<String> get genreList {
    if (janrlar.isEmpty) return [];
    return janrlar.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }
}

class MangaChapterModel {
  final dynamic id;
  final dynamic mangaId;
  final int chapterNumber;
  final String? title;
  final List<String> pages;
  final int views;
  final String? createdAt;

  MangaChapterModel({
    required this.id,
    required this.mangaId,
    required this.chapterNumber,
    this.title,
    required this.pages,
    this.views = 0,
    this.createdAt,
  });

  factory MangaChapterModel.fromJson(Map<String, dynamic> json) {
    List<String> pagesList = [];
    if (json['pages'] != null) {
      if (json['pages'] is List) {
        pagesList = (json['pages'] as List).map((e) => e.toString()).toList();
      } else if (json['pages'] is String) {
        try {
          pagesList = json['pages'].toString().split(',').map((e) => e.trim()).toList();
        } catch (_) {}
      }
    }

    return MangaChapterModel(
      id: json['id'],
      mangaId: json['manga_id'],
      chapterNumber: json['chapter_number'] is int
          ? json['chapter_number']
          : int.tryParse('${json['chapter_number']}') ?? 1,
      title: json['title'] ?? '${json['chapter_number']}-bob',
      pages: pagesList,
      views: json['views'] is int ? json['views'] : int.tryParse('${json['views']}') ?? 0,
      createdAt: json['created_at'],
    );
  }
}
