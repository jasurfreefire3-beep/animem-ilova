import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../../models/anime_model.dart';
import '../../../providers/anime_provider.dart';
import '../home/widgets/anime_card.dart';

class AnimeListScreen extends StatefulWidget {
  const AnimeListScreen({Key? key}) : super(key: key);

  @override
  State<AnimeListScreen> createState() => _AnimeListScreenState();
}

class _AnimeListScreenState extends State<AnimeListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _genres = [
    'Barchasi',
    'Jangari',
    'Sarguzasht',
    'Komediya',
    'Drama',
    'Fantastika',
    'Dahshatli',
    'Romantika',
    'Ilmiy-fantastika',
    'Kundalik hayot',
    'G\'ayritabiiy',
  ];

  @override
  Widget build(BuildContext context) {
    final animeProvider = Provider.of<AnimeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Animelar Katalogi"),
      ),
      body: Column(
        children: [
          // Qidiruv maydoni
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => animeProvider.searchAnimes(val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Anime nomi bo'yicha qidiruv...",
                prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          animeProvider.searchAnimes('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Janrlar filtri
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _genres.length,
              itemBuilder: (context, index) {
                final genre = _genres[index];
                final isSelected = genre == animeProvider.selectedGenre;

                return GestureDetector(
                  onTap: () => animeProvider.setGenre(genre),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : AppTheme.surfaceBorder,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        genre,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Anime Grid
          Expanded(
            child: animeProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : animeProvider.animes.isEmpty
                    ? const Center(
                        child: Text(
                          "Hech qanday anime topilmadi",
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
                        itemCount: animeProvider.animes.length,
                        itemBuilder: (context, index) {
                          final anime = animeProvider.animes[index];
                          return AnimeCard(
                            anime: anime,
                            width: double.infinity,
                            height: 155,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
