import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/api_config.dart';
import '../../../config/app_theme.dart';
import '../../../models/anime_model.dart';
import '../../anime/anime_detail_screen.dart';

class AnimeCard extends StatelessWidget {
  final AnimeModel anime;
  final double width;
  final double height;
  final bool showRating;

  const AnimeCard({
    Key? key,
    required this.anime,
    this.width = 135,
    this.height = 195,
    this.showRating = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fullImageUrl = ApiConfig.fullUrl(anime.imageUrl);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnimeDetailScreen(anime: anime),
          ),
        );
      },
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster rasm
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: fullImageUrl,
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: width,
                      height: height,
                      color: AppTheme.surfaceLight,
                      child: const Center(
                        child: Icon(Icons.movie, color: AppTheme.textMuted, size: 30),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: width,
                      height: height,
                      color: AppTheme.surfaceLight,
                      child: const Icon(Icons.broken_image, color: AppTheme.textMuted),
                    ),
                  ),
                ),

                // Qismlar soni nishoni
                if (anime.qismlarSoni > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white24, width: 0.5),
                      ),
                      child: Text(
                        '${anime.qismlarSoni} qism',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Reyting
                if (showRating && anime.rating > 0)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: AppTheme.ratingGold, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            anime.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Sarlavha
            Text(
              anime.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
