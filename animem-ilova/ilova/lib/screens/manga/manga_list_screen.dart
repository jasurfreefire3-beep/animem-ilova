import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../config/api_config.dart';
import '../../../config/app_theme.dart';
import '../../../models/manga_model.dart';
import '../../../providers/anime_provider.dart';
import 'manga_detail_screen.dart';

class MangaListScreen extends StatelessWidget {
  const MangaListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final animeProvider = Provider.of<AnimeProvider>(context);
    final mangas = animeProvider.mangas;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mangalar & Manhvalar"),
      ),
      body: mangas.isEmpty
          ? const Center(
              child: Text(
                "Hozircha mangalar mavjud emas",
                style: TextStyle(color: AppTheme.textMuted),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.55,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
              ),
              itemCount: mangas.length,
              itemBuilder: (context, index) {
                final manga = mangas[index];
                final coverUrl = ApiConfig.fullUrl(manga.coverUrl);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MangaDetailScreen(manga: manga),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: coverUrl,
                          width: double.infinity,
                          height: 155,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            height: 155,
                            color: AppTheme.surfaceLight,
                            child: const Icon(Icons.menu_book, color: AppTheme.textMuted),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        manga.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
