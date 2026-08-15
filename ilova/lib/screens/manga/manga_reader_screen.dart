import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/api_config.dart';
import '../../../config/app_theme.dart';
import '../../../models/manga_model.dart';
import '../../../services/api_service.dart';

class MangaReaderScreen extends StatefulWidget {
  final dynamic mangaId;
  final String mangaTitle;
  final int chapterNumber;

  const MangaReaderScreen({
    Key? key,
    required this.mangaId,
    required this.mangaTitle,
    required this.chapterNumber,
  }) : super(key: key);

  @override
  State<MangaReaderScreen> createState() => _MangaReaderScreenState();
}

class _MangaReaderScreenState extends State<MangaReaderScreen> {
  final ApiService _apiService = ApiService();
  MangaChapterModel? _chapter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChapter();
  }

  Future<void> _loadChapter() async {
    final ch = await _apiService.getMangaChapter(widget.mangaId, widget.chapterNumber);
    if (mounted) {
      setState(() {
        _chapter = ch;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        title: Text(
          "${widget.mangaTitle} - ${widget.chapterNumber}-bob",
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _chapter == null || _chapter!.pages.isEmpty
              ? const Center(
                  child: Text(
                    "Sahifalar topilmadi",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  itemCount: _chapter!.pages.length,
                  itemBuilder: (context, index) {
                    final pageUrl = ApiConfig.fullUrl(_chapter!.pages[index]);
                    return CachedNetworkImage(
                      imageUrl: pageUrl,
                      fit: BoxFit.fitWidth,
                      placeholder: (context, url) => Container(
                        height: 300,
                        color: Colors.black12,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: Colors.black26,
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.white38),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
