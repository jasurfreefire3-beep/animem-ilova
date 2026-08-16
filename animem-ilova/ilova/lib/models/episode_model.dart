class EpisodeModel {
  final dynamic id;
  final dynamic animeId;
  final int episodeNumber;
  final String title;
  final String videoUrl;
  final String? posterUrl;
  final int views;
  final String? createdAt;

  EpisodeModel({
    required this.id,
    required this.animeId,
    required this.episodeNumber,
    required this.title,
    required this.videoUrl,
    this.posterUrl,
    this.views = 0,
    this.createdAt,
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
    return EpisodeModel(
      id: json['id'],
      animeId: json['anime_id'],
      episodeNumber: json['episode_number'] is int
          ? json['episode_number']
          : int.tryParse('${json['episode_number']}') ?? 1,
      title: json['title'] ?? '${json['episode_number']}-qism',
      videoUrl: json['video_url'] ?? '',
      posterUrl: json['poster_url'],
      views: json['views'] is int ? json['views'] : int.tryParse('${json['views']}') ?? 0,
      createdAt: json['created_at'],
    );
  }
}
