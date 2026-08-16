import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../../models/anime_model.dart';
import '../../../providers/anime_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../home/widgets/anime_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final favProvider = Provider.of<FavoritesProvider>(context);
    final animeProvider = Provider.of<AnimeProvider>(context);

    final favAnimes = animeProvider.animes.where((anime) {
      return favProvider.isFavorite(anime.id);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sevimlilar"),
      ),
      body: favAnimes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 64, color: AppTheme.textMuted),
                  SizedBox(height: 12),
                  Text(
                    "Sevimlilar ro'yxati bo'sh",
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                  ),
                ],
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
              itemCount: favAnimes.length,
              itemBuilder: (context, index) {
                final anime = favAnimes[index];
                return AnimeCard(
                  anime: anime,
                  width: double.infinity,
                  height: 155,
                );
              },
            ),
    );
  }
}
