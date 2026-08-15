import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../config/api_config.dart';
import '../../../config/app_theme.dart';
import '../../../models/anime_model.dart';
import '../../../models/episode_model.dart';
import '../../../services/storage_service.dart';
import '../../../utils/toast_utils.dart';

class VideoPlayerScreen extends StatefulWidget {
  final AnimeModel anime;
  final List<EpisodeModel> episodes;
  final int initialEpisodeIndex;

  const VideoPlayerScreen({
    Key? key,
    required this.anime,
    required this.episodes,
    this.initialEpisodeIndex = 0,
  }) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late int _currentEpisodeIndex;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentEpisodeIndex = widget.initialEpisodeIndex;
    _initializePlayer();
  }

  EpisodeModel get currentEpisode {
    if (widget.episodes.isNotEmpty && _currentEpisodeIndex < widget.episodes.length) {
      return widget.episodes[_currentEpisodeIndex];
    }
    // Agar epizodlar yo'q bo'lsa, anime videoUrl'ini olamiz
    return EpisodeModel(
      id: 0,
      animeId: widget.anime.id,
      episodeNumber: 1,
      title: widget.anime.title,
      videoUrl: widget.anime.videoUrl,
    );
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _disposePlayer();

    final videoUrl = currentEpisode.videoUrl;
    if (videoUrl.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Ushbu qism uchun video manzili topilmadi";
      });
      return;
    }

    try {
      final parsedUri = Uri.parse(ApiConfig.fullUrl(videoUrl));
      _videoPlayerController = VideoPlayerController.networkUrl(parsedUri);

      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: true,
        playbackSpeeds: const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.primary,
          handleColor: AppTheme.primary,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppTheme.error, size: 42),
                const SizedBox(height: 12),
                Text(
                  "Videoni yuklashda xatolik yuz berdi",
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _initializePlayer,
                  child: const Text("Qayta urinish"),
                ),
              ],
            ),
          );
        },
      );

      // Tinglovchi: Tarixga saqlab borish
      _videoPlayerController!.addListener(() {
        if (_videoPlayerController != null &&
            _videoPlayerController!.value.isInitialized) {
          final position = _videoPlayerController!.value.position.inSeconds;
          if (position > 5) {
            StorageService.saveWatchHistory(
              animeId: widget.anime.id,
              title: widget.anime.title,
              imageUrl: widget.anime.imageUrl,
              episodeNumber: currentEpisode.episodeNumber,
              positionSeconds: position,
            );
          }
        }
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Video o'ynatgichni ishga tushirishda xatolik: $e";
      });
    }
  }

  void _disposePlayer() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _chewieController = null;
    _videoPlayerController = null;
  }

  void _changeEpisode(int index) {
    if (index >= 0 && index < widget.episodes.length) {
      setState(() {
        _currentEpisodeIndex = index;
      });
      _initializePlayer();
    }
  }

  @override
  void dispose() {
    _disposePlayer();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "${widget.anime.title} - ${currentEpisode.episodeNumber}-qism",
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          // Video Player Box
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        )
                  : _chewieController != null &&
                          _chewieController!.videoPlayerController.value.isInitialized
                      ? Chewie(controller: _chewieController!)
                      : const SizedBox.shrink(),
            ),
          ),

          // Qismlar va tafsilotlar
          Expanded(
            child: Container(
              color: AppTheme.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${currentEpisode.episodeNumber}-qism: ${currentEpisode.title}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.anime.title,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),

                        // Keyingi qism tugmasi
                        if (_currentEpisodeIndex < widget.episodes.length - 1)
                          ElevatedButton.icon(
                            onPressed: () => _changeEpisode(_currentEpisodeIndex + 1),
                            icon: const Icon(Icons.skip_next, size: 18),
                            label: const Text("Keyingi", style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(color: AppTheme.surfaceBorder, height: 1),

                  // Epizodlar ro'yxati sarlavhasi
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      "Barcha qismlar (${widget.episodes.length})",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Epizodlar Grid / Ro'yxati
                  Expanded(
                    child: widget.episodes.isEmpty
                        ? const Center(
                            child: Text(
                              "Boshqa qismlar mavjud emas",
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.6,
                            ),
                            itemCount: widget.episodes.length,
                            itemBuilder: (context, index) {
                              final isCurrent = index == _currentEpisodeIndex;
                              final ep = widget.episodes[index];

                              return GestureDetector(
                                onTap: () => _changeEpisode(index),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isCurrent ? AppTheme.primary : AppTheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isCurrent
                                          ? AppTheme.primary
                                          : AppTheme.surfaceBorder,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "${ep.episodeNumber}",
                                      style: TextStyle(
                                        color: isCurrent ? Colors.white : AppTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
