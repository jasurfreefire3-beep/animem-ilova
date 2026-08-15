import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../config/api_config.dart';
import '../../../config/app_theme.dart';
import '../../../models/anime_model.dart';
import '../../../models/episode_model.dart';
import '../../../providers/favorites_provider.dart';
import '../../../services/api_service.dart';
import '../../../utils/toast_utils.dart';
import 'video_player_screen.dart';
import 'widgets/comment_sheet.dart';
import 'widgets/rating_dialog.dart';

class AnimeDetailScreen extends StatefulWidget {
  final AnimeModel anime;

  const AnimeDetailScreen({Key? key, required this.anime}) : super(key: key);

  @override
  State<AnimeDetailScreen> createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends State<AnimeDetailScreen> {
  final ApiService _apiService = ApiService();
  List<EpisodeModel> _episodes = [];
  bool _isLoadingEpisodes = true;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
  }

  Future<void> _loadEpisodes() async {
    List<EpisodeModel> list = [];
    try {
      list = await _apiService.getAnimeEpisodes(widget.anime.id);
    } catch (_) {}

    final totalCount = widget.anime.qismlarSoni > 0 ? widget.anime.qismlarSoni : (list.isNotEmpty ? list.length : 1);
    final List<EpisodeModel> merged = [];

    for (int i = 1; i <= totalCount; i++) {
      EpisodeModel? found;
      for (final ep in list) {
        if (ep.episodeNumber == i) {
          found = ep;
          break;
        }
      }

      String vUrl = found?.videoUrl ?? '';
      if (vUrl.isEmpty && i == 1) {
        vUrl = widget.anime.videoUrl;
      }

      merged.add(
        EpisodeModel(
          id: found?.id ?? i,
          animeId: widget.anime.id,
          episodeNumber: i,
          title: (found != null && found.title.isNotEmpty) ? found.title : '$i-qism',
          videoUrl: vUrl,
          posterUrl: found?.posterUrl,
          views: found?.views ?? 0,
          createdAt: found?.createdAt,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _episodes = merged;
        _isLoadingEpisodes = false;
      });
    }
  }

  void _openPlayer([int episodeIndex = 0]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          anime: widget.anime,
          episodes: _episodes,
          initialEpisodeIndex: episodeIndex,
        ),
      ),
    );
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentSheet(animeId: widget.anime.id),
    );
  }

  void _openRating() async {
    final result = await showDialog(
      context: context,
      builder: (_) => RatingDialog(
        animeId: widget.anime.id,
        animeTitle: widget.anime.title,
        currentRating: widget.anime.rating,
      ),
    );
    if (result == true) {
      // Reload anime if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    final favProvider = Provider.of<FavoritesProvider>(context);
    final isFav = favProvider.isFavorite(widget.anime.id);
    final bannerUrl = ApiConfig.fullUrl(
      widget.anime.bannerUrl.isNotEmpty ? widget.anime.bannerUrl : widget.anime.imageUrl,
    );
    final posterUrl = ApiConfig.fullUrl(widget.anime.imageUrl);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsible Banner App Bar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: bannerUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: AppTheme.surfaceLight),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          AppTheme.background.withOpacity(0.8),
                          AppTheme.background,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isFav ? Icons.bookmark : Icons.bookmark_border,
                  color: isFav ? AppTheme.primary : Colors.white,
                ),
                onPressed: () {
                  favProvider.toggleFavorite(widget.anime);
                  ToastUtils.showInfo(
                    context,
                    isFav ? "Sevimlilardan olib tashlandi" : "Sevimlilarga qo'shildi",
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  ToastUtils.showInfo(context, "Havola nusxalandi: https://animem.uz/anime/${widget.anime.slug}");
                },
              ),
            ],
          ),

          // Anime Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster & Title Info Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: posterUrl,
                          width: 110,
                          height: 160,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 110,
                            height: 160,
                            color: AppTheme.surfaceLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.anime.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Reyting
                            Row(
                              children: [
                                const Icon(Icons.star, color: AppTheme.ratingGold, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  widget.anime.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "(${widget.anime.ratingCount} baho)",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Meta info
                            Text(
                              "${widget.anime.holati} • ${widget.anime.yil ?? 2024} yil",
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            if (widget.anime.studiyasi.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                "Studiya: ${widget.anime.studiyasi}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              "Qismlar: ${widget.anime.qismlarSoni > 0 ? widget.anime.qismlarSoni : 'Noma\'lum'}",
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Janrlar ro'yxati
                  if (widget.anime.genreList.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.anime.genreList.map((genre) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.surfaceBorder),
                          ),
                          child: Text(
                            genre,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 20),

                  // Tomosha qilish / Play Tugmasi
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _openPlayer(0),
                      icon: const Icon(Icons.play_arrow_rounded, size: 28),
                      label: const Text(
                        "Tomosha qilish",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Action Buttons Row (Baholash, Fikrlar)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openRating,
                          icon: const Icon(Icons.star_outline, color: AppTheme.ratingGold, size: 18),
                          label: const Text(
                            "Baholash",
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.surfaceBorder),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openComments,
                          icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.primary, size: 18),
                          label: const Text(
                            "Fikrlar",
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.surfaceBorder),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tavsif (Description)
                  const Text(
                    "Anime haqida",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.anime.description,
                    maxLines: _isDescriptionExpanded ? null : 4,
                    overflow: _isDescriptionExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  if (widget.anime.description.length > 150)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isDescriptionExpanded = !_isDescriptionExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _isDescriptionExpanded ? "Kamroq ko'rsatish" : "Ko'proq o'qish...",
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Qismlar (Episodes)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Qismlar (${_episodes.length})",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _isLoadingEpisodes
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(color: AppTheme.primary),
                          ),
                        )
                      : _episodes.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  "1-qism tez orada yuklanadi",
                                  style: TextStyle(color: AppTheme.textMuted),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _episodes.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final ep = _episodes[index];
                                return ListTile(
                                  tileColor: AppTheme.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: const BorderSide(color: AppTheme.surfaceBorder),
                                  ),
                                  leading: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "${ep.episodeNumber}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    ep.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.play_circle_fill,
                                    color: AppTheme.primary,
                                    size: 28,
                                  ),
                                  onTap: () => _openPlayer(index),
                                );
                              },
                            ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
