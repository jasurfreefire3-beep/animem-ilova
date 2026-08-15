import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/api_config.dart';
import '../../../config/app_theme.dart';
import '../../../models/manga_model.dart';
import 'manga_reader_screen.dart';

class MangaDetailScreen extends StatelessWidget {
  final MangaModel manga;

  const MangaDetailScreen({Key? key, required this.manga}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final coverUrl = ApiConfig.fullUrl(manga.coverUrl);

    return Scaffold(
      appBar: AppBar(
        title: Text(manga.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: coverUrl,
                    width: 120,
                    height: 175,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 120,
                      height: 175,
                      color: AppTheme.surfaceLight,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        manga.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Muallif: ${manga.author ?? 'Noma\'lum'}",
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Holati: ${manga.holati}",
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Boblar soni: ${manga.chaptersCount}",
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // O'qish tugmasi
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MangaReaderScreen(
                        mangaId: manga.id,
                        mangaTitle: manga.title,
                        chapterNumber: 1,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chrome_reader_mode),
                label: const Text("1-bobdan o'qish"),
              ),
            ),
            const SizedBox(height: 24),

            // Tavsif
            const Text(
              "Manga haqida",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              manga.description,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Boblar ro'yxati
            Text(
              "Barcha boblar (${manga.chaptersCount})",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: manga.chaptersCount > 0 ? manga.chaptersCount : 1,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final chapterNum = index + 1;
                return ListTile(
                  tileColor: AppTheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppTheme.surfaceBorder),
                  ),
                  leading: const Icon(Icons.book, color: AppTheme.primary),
                  title: Text(
                    "$chapterNum-bob",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MangaReaderScreen(
                          mangaId: manga.id,
                          mangaTitle: manga.title,
                          chapterNumber: chapterNum,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
