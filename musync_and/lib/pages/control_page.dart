import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musync_and/services/audio_player_base.dart';
import 'package:musync_and/services/sound_control.dart';
import 'package:musync_and/widgets/player.dart';

class ControlPage extends StatefulWidget {
  final MusyncAudioHandler audioHandler;
  const ControlPage({super.key, required this.audioHandler});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Container(
          color: const Color.fromARGB(255, 8, 8, 10),
          child: Stack(
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          child: Padding(
                            padding: EdgeInsetsGeometry.symmetric(vertical: 15),
                            child: Column(
                              children: [
                                StreamBuilder<MediaItem?>(
                                  stream: widget.audioHandler.mediaItem,
                                  builder: (context, snapshot) {
                                    final mediaItem = snapshot.data;

                                    if (mediaItem == null) {
                                      return const Text("...");
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 0,
                                      ),
                                      child: Column(
                                        children: [
                                          Player.titleText(mediaItem.title, 20),
                                          Player.titleText(
                                            mediaItem.artist ?? '',
                                            13,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                StreamBuilder<Duration>(
                                  stream: widget.audioHandler.positionStream,
                                  builder: (context, snapshot) {
                                    final position =
                                        snapshot.data ?? Duration.zero;
                                    final total =
                                        widget.audioHandler.duration ??
                                        Duration.zero;

                                    return Column(
                                      children: [
                                        SliderTheme(
                                          data: SliderTheme.of(
                                            context,
                                          ).copyWith(
                                            trackHeight: 2,
                                            thumbShape:
                                                const RoundSliderThumbShape(
                                                  enabledThumbRadius: 6,
                                                ),
                                            overlayShape:
                                                const RoundSliderOverlayShape(
                                                  overlayRadius: 12,
                                                ),
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 0,
                                            ),
                                            child: Slider(
                                              min: 0,
                                              max:
                                                  total.inMilliseconds
                                                      .toDouble(),
                                              value:
                                                  position.inMilliseconds
                                                      .clamp(
                                                        0,
                                                        total.inMilliseconds,
                                                      )
                                                      .toDouble(),
                                              onChanged: (value) {
                                                widget.audioHandler.seek(
                                                  Duration(
                                                    milliseconds: value.toInt(),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 22.0,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                Player.formatDuration(
                                                  position,
                                                  false,
                                                ),
                                              ),
                                              Text(
                                                Player.formatDuration(
                                                  total,
                                                  false,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () async {
                              await widget.audioHandler.skipToPrevious();
                            },
                            child: Icon(
                              Icons.keyboard_double_arrow_left_sharp,
                              size: 45,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      StreamBuilder<bool>(
                        stream: widget.audioHandler.playingStream,
                        builder: (context, snapshot) {
                          final isPlaying = snapshot.data ?? false;
                          return Expanded(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.all(15),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () {
                                  isPlaying
                                      ? widget.audioHandler.pause()
                                      : widget.audioHandler.play();
                                },
                                child: Icon(
                                  isPlaying
                                      ? Icons.pause_outlined
                                      : Icons.play_arrow_outlined,
                                  size: 45,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      ValueListenableBuilder<ModeShuffleEnum>(
                        valueListenable: widget.audioHandler.shuffleMode,
                        builder: (context, value, child) {
                          return Expanded(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.all(15),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () async {
                                  await widget.audioHandler.skipToNext();
                                },
                                child:
                                    value != ModeShuffleEnum.shuffleOptional
                                        ? Icon(
                                          Icons
                                              .keyboard_double_arrow_right_sharp,
                                          size: 45,
                                        )
                                        : Image.asset(
                                          'assets/dice.png',
                                          color: Color.fromARGB(
                                            255,
                                            243,
                                            160,
                                            34,
                                          ),
                                          colorBlendMode: BlendMode.srcIn,
                                          width: 45,
                                        ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ValueListenableBuilder<ModeShuffleEnum>(
                        valueListenable: widget.audioHandler.shuffleMode,
                        builder: (context, value, child) {
                          return Expanded(
                            child: AspectRatio(
                              aspectRatio: 3 / 2,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.all(15),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () {
                                  widget.audioHandler.setShuffleModeEnabled();
                                },
                                child:
                                    value != ModeShuffleEnum.shuffleOptional
                                        ? Icon(
                                          value == ModeShuffleEnum.shuffleNormal
                                              ? Icons.shuffle
                                              : Icons.arrow_right_alt_rounded,
                                          size: 45,
                                        )
                                        : Image.asset(
                                          'assets/dice.png',
                                          color: Color.fromARGB(
                                            255,
                                            243,
                                            160,
                                            34,
                                          ),
                                          colorBlendMode: BlendMode.srcIn,
                                          width: 45,
                                        ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      ValueListenableBuilder<ModeLoopEnum>(
                        valueListenable: widget.audioHandler.loopMode,
                        builder: (context, value, child) {
                          return Expanded(
                            child: AspectRatio(
                              aspectRatio: 3 / 2,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.all(15),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () async {
                                  widget.audioHandler.setLoopModeEnabled();
                                },
                                child: Icon(
                                  value == ModeLoopEnum.off
                                      ? Icons.arrow_right_alt_rounded
                                      : value == ModeLoopEnum.all
                                      ? Icons.repeat_rounded
                                      : Icons.repeat_one_rounded,
                                  size: 45,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SoundControl(),
                  const SizedBox(height: 10),
                  ValueListenableBuilder(
                    valueListenable: widget.audioHandler.atualPlaylist,
                    builder: (context, playlist, _) {
                      return Row(
                        children: [
                          Expanded(
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              child: Padding(
                                padding: EdgeInsetsGeometry.symmetric(
                                  vertical: 15,
                                ),
                                child: Column(
                                  children: [
                                    StreamBuilder<MediaItem?>(
                                      stream: widget.audioHandler.mediaItem,
                                      builder: (context, snapshot) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 0,
                                          ),
                                          child: Column(
                                            children: [
                                              Player.titleText(
                                                playlist['title'],
                                                20,
                                              ),
                                              Player.titleText(
                                                playlist['subtitle'],
                                                13,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    Column(
                                      children: [
                                        SliderTheme(
                                          data: SliderTheme.of(
                                            context,
                                          ).copyWith(
                                            trackHeight: 2,
                                            thumbShape:
                                                const RoundSliderThumbShape(
                                                  enabledThumbRadius: 6,
                                                ),
                                            overlayShape:
                                                const RoundSliderOverlayShape(
                                                  overlayRadius: 12,
                                                ),
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 0,
                                            ),
                                            child: Slider(
                                              min: 1,
                                              max:
                                                  playlist['qntTotal']
                                                      .toDouble(),
                                              value:
                                                  playlist['nowPlaying']
                                                      .toDouble() +
                                                  1,
                                              onChanged: (value) {},
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 22.0,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${playlist['nowPlaying'] + 1}',
                                              ),
                                              Text('${playlist['qntTotal']}'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 3 / 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () async {
                              await widget.audioHandler
                                  .skipToPreviousPlaylist();
                            },
                            child: Icon(
                              Icons.keyboard_double_arrow_left_sharp,
                              size: 45,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 3 / 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () async {
                              await widget.audioHandler.skipToNextPlaylist();
                            },
                            child: Icon(
                              Icons.keyboard_double_arrow_right_sharp,
                              size: 45,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
