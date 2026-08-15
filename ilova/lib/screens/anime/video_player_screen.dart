import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../config/api_config.dart';
import '../../../config/app_theme.dart';
import '../../../models/anime_model.dart';
import '../../../models/episode_model.dart';
import '../../../services/storage_service.dart';

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
  WebViewController? _webViewController;
  
  bool _isLoading = true;
  bool _isIframeMode = false;
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
    return EpisodeModel(
      id: 0,
      animeId: widget.anime.id,
      episodeNumber: 1,
      title: widget.anime.title,
      videoUrl: widget.anime.videoUrl,
    );
  }

  bool _isEmbedOrIframeUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('iframe') ||
        lower.contains('sibnet.ru') ||
        lower.contains('mover.uz') ||
        lower.contains('vk.com') ||
        lower.contains('ok.ru') ||
        lower.contains('myvi') ||
        lower.contains('youtube.com') ||
        lower.contains('youtu.be') ||
        lower.contains('embed') ||
        lower.contains('.html') ||
        lower.contains('player.animem.uz') ||
        (!lower.endsWith('.mp4') && !lower.endsWith('.m3u8') && !lower.contains('.mp4?') && !lower.contains('.m3u8?'));
  }

  String _extractIframeSrc(String raw) {
    if (raw.contains('<iframe') && raw.contains('src=')) {
      final match = RegExp(r'src=["\x27]([^"\x27]+)["\x27]').firstMatch(raw);
      if (match != null && match.group(1) != null) {
        return match.group(1)!;
      }
    }
    return raw;
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isIframeMode = false;
    });

    _disposeControllers();

    String rawVideoUrl = currentEpisode.videoUrl.trim();
    if (rawVideoUrl.isEmpty) {
      rawVideoUrl = widget.anime.videoUrl.trim();
    }

    if (rawVideoUrl.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Ushbu qism uchun video manzili mavjud emas";
      });
      return;
    }

    final videoUrl = _extractIframeSrc(rawVideoUrl);

    // Agar URL iframe yoki veb player bo'lsa
    if (_isEmbedOrIframeUrl(videoUrl)) {
      _setupIframePlayer(videoUrl);
      return;
    }

    // Direct stream (mp4 / m3u8) bilan Cloudflare headerlarini berib ochish
    try {
      final fullUrl = ApiConfig.fullUrl(videoUrl);
      final parsedUri = Uri.parse(fullUrl);

      _videoPlayerController = VideoPlayerController.networkUrl(
        parsedUri,
        httpHeaders: {
          'Referer': 'https://animem.uz/',
          'Origin': 'https://animem.uz',
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36 AnimemUzApp/1.0',
        },
      );

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
                const Text(
                  "Videoni yuklashda xatolik yuz berdi",
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _initializePlayer,
                      child: const Text("Qayta urinish"),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _setupIframePlayer(videoUrl),
                      child: const Text("Veb playerda ochish", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

      _videoPlayerController!.addListener(() {
        if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized) {
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
        _isIframeMode = false;
      });
    } catch (e) {
      // Agar direct playerda xato bo'lsa, avtomatik iframe playerga o'tkazamiz
      _setupIframePlayer(videoUrl);
    }
  }

  void _setupIframePlayer(String url) {
    try {
      String finalUrl = url;
      if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
        finalUrl = ApiConfig.fullUrl(finalUrl);
      }

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..setUserAgent("Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36")
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) setState(() => _isLoading = true);
            },
            onPageFinished: (String url) {
              if (mounted) setState(() => _isLoading = false);
            },
            onWebResourceError: (WebResourceError error) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
          ),
        );

      if (url.contains('<iframe')) {
        final html = '''
          <!DOCTYPE html>
          <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
              body, html { margin: 0; padding: 0; width: 100%; height: 100%; background: #000; overflow: hidden; }
              iframe { width: 100%; height: 100%; border: none; }
            </style>
          </head>
          <body>
            $url
          </body>
          </html>
        ''';
        controller.loadHtmlString(html, baseUrl: 'https://animem.uz/');
      } else {
        controller.loadRequest(
          Uri.parse(finalUrl),
          headers: {
            'Referer': 'https://animem.uz/',
            'Origin': 'https://animem.uz',
          },
        );
      }

      setState(() {
        _webViewController = controller;
        _isIframeMode = true;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Player yuklanmadi: $e";
      });
    }
  }

  void _disposeControllers() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _chewieController = null;
    _videoPlayerController = null;
    _webViewController = null;
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
    _disposeControllers();
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
          style: const TextStyle(fontSize: 15),
        ),
      ),
      body: Column(
        children: [
          // Video Player Box
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: Stack(
                children: [
                  if (_isIframeMode && _webViewController != null)
                    WebViewWidget(controller: _webViewController!)
                  else if (!_isIframeMode &&
                      _chewieController != null &&
                      _chewieController!.videoPlayerController.value.isInitialized)
                    Chewie(controller: _chewieController!)
                  else if (_errorMessage != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: AppTheme.error, size: 36),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (_isLoading)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(color: AppTheme.primary),
                      ),
                    ),
                ],
              ),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${currentEpisode.episodeNumber}-qism: ${currentEpisode.title}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.anime.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
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
