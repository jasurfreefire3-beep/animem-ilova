import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../config/api_config.dart';
import '../../../config/app_theme.dart';
import '../../../providers/anime_provider.dart';
import '../anime/anime_detail_screen.dart';

class Top100Screen extends StatelessWidget {
  const Top100Screen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final animeProvider = Provider.of<AnimeProvider>(context);
    final top100 = animeProvider.top100;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: AppTheme.ratingGold, size: 24),
            SizedBox(width: 8),
            Text("Top 100 Animelar"),
          ],
        ),
      ),
      body: top100.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: top100.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final anime = top100[index];
                final rank = index + 1;
                final posterUrl = ApiConfig.fullUrl(anime.imageUrl);

                Color rankBadgeColor = AppTheme.surfaceLight;
                if (rank == 1) rankBadgeColor = const Color(0xFFFFD700); // Gold
                if (rank == 2) rankBadgeColor = const Color(0xFFC0C0C0); // Silver
                if (rank == 3) rankBadgeColor = const Color(0xFFCD7F32); // Bronze

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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        // Rank Number Badge
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: rank <= 3 ? rankBadgeColor : AppTheme.surfaceLight,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              "$rank",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: rank <= 3 ? Colors.black : Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Poster
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: posterUrl,
                            width: 55,
                            height: 80,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              width: 55,
                              height: 80,
                              color: AppTheme.surfaceLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title and Stats
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                anime.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: AppTheme.ratingGold, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    anime.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "${anime.yil ?? 2024} yil",
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppTheme.textMuted,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
