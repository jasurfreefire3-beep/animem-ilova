import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../../models/anime_model.dart';
import '../../../providers/anime_provider.dart';
import '../anime/anime_list_screen.dart';
import '../manga/manga_list_screen.dart';
import '../schedule/schedule_screen.dart';
import '../top100/top100_screen.dart';
import 'widgets/anime_card.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final animeProvider = Provider.of<AnimeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo.jpeg',
          height: 34,
          errorBuilder: (_, __, ___) => const Text(
            "ANIMEM.UZ",
            style: TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, size: 26),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnimeListScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        backgroundColor: AppTheme.surface,
        onRefresh: () async {
          await animeProvider.loadInitialData();
        },
        child: animeProvider.isLoading && animeProvider.animes.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Asosiy Karusel Banner
                    BannerCarousel(banners: animeProvider.banners),
                    const SizedBox(height: 16),

                    // Tezkor Tugmalar (Jadval, Top 100, Mangalar)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _QuickButton(
                            icon: Icons.calendar_month_rounded,
                            label: "Jadval",
                            color: const Color(0xFF3B82F6),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ScheduleScreen()),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          _QuickButton(
                            icon: Icons.emoji_events_rounded,
                            label: "Top 100",
                            color: const Color(0xFFF59E0B),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const Top100Screen()),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          _QuickButton(
                            icon: Icons.menu_book_rounded,
                            label: "Mangalar",
                            color: const Color(0xFF10B981),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const MangaListScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tavsiya etilgan animelar
                    if (animeProvider.recommended.isNotEmpty) ...[
                      SectionHeader(
                        title: "Tavsiya etamiz",
                        onSeeAll: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AnimeListScreen()),
                          );
                        },
                      ),
                      SizedBox(
                        height: 250,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: animeProvider.recommended.length,
                          itemBuilder: (context, index) {
                            return AnimeCard(
                              anime: animeProvider.recommended[index],
                            );
                          },
                        ),
                      ),
                    ],

                    // So'nggi yangilangan animelar
                    SectionHeader(
                      title: "So'nggi animelar",
                      onSeeAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AnimeListScreen()),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.55,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: animeProvider.animes.take(12).length,
                        itemBuilder: (context, index) {
                          return AnimeCard(
                            anime: animeProvider.animes[index],
                            width: double.infinity,
                            height: 155,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
