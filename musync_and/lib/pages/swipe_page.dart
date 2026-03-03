import 'dart:developer';
import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';
import 'package:audiotags/audiotags.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musync_and/helpers/audio_player_helper.dart';
import 'package:musync_and/services/playlists.dart';
import 'package:musync_and/themes.dart';
import 'package:musync_and/widgets/player.dart';

class SwipePage extends StatefulWidget {
  final List<MediaItem> songsToPlaylist;
  final Playlists? playlistInicial;
  final void Function(MediaItem, int)? onAccept;
  final void Function(MediaItem, int)? onDeny;
  const SwipePage({
    super.key,
    required this.songsToPlaylist,
    this.playlistInicial,
    this.onAccept,
    this.onDeny,
  });

  @override
  State<SwipePage> createState() => _SwipePageState();
}

class _SwipePageState extends State<SwipePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<Offset>? _animation;
  Offset position = Offset.zero;
  double angle = 0;
  bool isAnimating = false;
  final Map<String, Uint8List?> _artCache = {};
  List<MediaItem> songs = [];

  @override
  void initState() {
    super.initState();
    songs = List.from(widget.songsToPlaylist);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _controller.addListener(() {
      if (_animation == null) return;

      setState(() {
        position = _animation!.value;
        angle = position.dx * 0.0008;
      });
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        songs.removeAt(0);
        _preloadNextArts();
        resetCard();

        mscAudPl.executeMusicBlank(songs.first);
      }
    });

    mscAudPl.executeMusicBlank(songs.first);

    _preloadNextArts();
  }

  void resetCard() {
    _controller.reset();
    position = Offset.zero;
    angle = 0;
    isAnimating = false;
    setState(() {});
  }

  void animateCard(double screenWidth, bool toRight, MediaItem msc) {
    final end = Offset(
      toRight ? screenWidth * 1.5 : -screenWidth * 1.5,
      position.dy,
    );

    _animation = Tween<Offset>(
      begin: position,
      end: end,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    isAnimating = true;
    _controller.forward().then((_) {
      final id = widget.playlistInicial?.id ?? -1;
      if (toRight) {
        widget.onAccept?.call(msc, id);
      } else {
        widget.onDeny?.call(msc, id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    if (songs.isEmpty) {
      return const Scaffold(body: Center(child: Text("Sem mais pessoas")));
    }

    return Scaffold(
      body: Stack(
        children: [
          // Próximo card
          if (songs.length > 1) Positioned.fill(child: buildCard(songs[1])),

          // Card principal
          Positioned.fill(
            child: GestureDetector(
              onPanUpdate: (details) {
                if (isAnimating) return;

                setState(() {
                  position += details.delta;
                  angle = position.dx / screenSize.width * 0.5;
                });
              },
              onPanEnd: (_) {
                if (isAnimating) return;

                if (position.dx > 120) {
                  animateCard(screenSize.width, true, songs.first);
                } else if (position.dx < -120) {
                  animateCard(screenSize.width, false, songs.first);
                } else {
                  resetCard();
                }
              },
              child: Transform.translate(
                offset: position,
                child: Transform.rotate(
                  angle: angle,
                  child: buildCard(songs.first),
                ),
              ),
            ),
          ),
          Positioned(
            top: 35,
            left: 35,
            right: 35,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: baseElementDark,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Playlist atual:",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.playlistInicial?.title ?? 'Playlist',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: baseAppColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.search_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: '${songs.first.id}-deny',
                  backgroundColor: baseFundoDark,
                  onPressed: () {
                    animateCard(screenSize.width, false, songs.first);
                  },
                  child: const Icon(Icons.close, color: Colors.redAccent),
                ),

                StreamBuilder<PlayerState>(
                  stream: mscAudPl.playerStateStream,
                  builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final isPlaying = playerState?.playing ?? false;
                    final isCompleted =
                        playerState?.processingState ==
                        ProcessingState.completed;

                    return FloatingActionButton(
                      heroTag: '${songs.first.id}-play',
                      backgroundColor: baseFundoDark,
                      onPressed: () {
                        if (isPlaying) {
                          mscAudPl.pause();
                        } else {
                          mscAudPl.play();
                        }
                      },
                      child: Icon(
                        (isPlaying && !isCompleted)
                            ? Icons.pause_outlined
                            : Icons.play_arrow_outlined,
                        color: baseAppColor,
                      ),
                    );
                  },
                ),

                FloatingActionButton(
                  heroTag: '${songs.first.id}-accept',
                  backgroundColor: baseFundoDark,
                  onPressed: () {
                    animateCard(screenSize.width, true, songs.first);
                  },
                  child: const Icon(Icons.check, color: Colors.greenAccent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCard(MediaItem msc) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: baseFundoDarkDark,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildArt(msc, screenWidth),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                msc.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              msc.artist ?? "Artista desconhecido",
              style: TextStyle(fontSize: 18, color: Colors.grey.shade400),
            ),

            const SizedBox(height: 12),

            if (msc.duration != null)
              Text(
                Player.formatDuration(msc.duration!, false),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                  fontFamily: 'Default-Thin',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildArt(MediaItem msc, double screenWidth) {
    final path = msc.extras?['path'];
    final bytes = path != null ? _artCache[path] : null;

    final imageWidth = screenWidth - 20; // 10px margem esquerda + direita

    if (bytes == null) {
      return Container(
        width: imageWidth,
        height: imageWidth,
        color: Colors.grey.shade800,
        child: const Icon(Icons.music_note, size: 100, color: Colors.white70),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.memory(
        bytes,
        width: imageWidth,
        height: imageWidth,
        fit: BoxFit.cover,
      ),
    );
  }

  void _preloadNextArts() {
    for (int i = 0; i < 3; i++) {
      if (i >= songs.length) break;

      final path = songs[i].extras?['path'];
      if (path != null) {
        _loadArt(path);
      }
    }
  }

  Future<void> _loadArt(String path) async {
    if (_artCache.containsKey(path)) return;

    try {
      final tag = await AudioTags.read(path);

      if (tag == null || tag.pictures.isEmpty) {
        _artCache[path] = null;
      } else {
        _artCache[path] = tag.pictures.first.bytes;
      }
    } catch (e, s) {
      log('ERRO ao ler tags Exception: $e Stack: $s');
      _artCache[path] = null;
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
