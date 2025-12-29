import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:musync_and/services/audio_player_base.dart';
import 'package:musync_and/services/media_atual.dart';
import 'package:musync_and/widgets/sound_control.dart';
import 'package:musync_and/widgets/player.dart';
import 'package:musync_and/themes.dart';

class ControlPage extends StatefulWidget {
  final MusyncAudioHandler audioHandler;
  const ControlPage({super.key, required this.audioHandler});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  final ekoConnected = MusyncAudioHandler.eko?.conected.value ?? false;
  bool changingTrack = false;
  Stream<String> _timeStream() async* {
    yield* Stream.periodic(const Duration(seconds: 1), (_) {
      return DateFormat('HH:mm').format(DateTime.now());
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget buildSliderMusic() {
    if (ekoConnected) {
      return ValueListenableBuilder<MediaAtual>(
        valueListenable: MusyncAudioHandler.mediaAtual,
        builder: (context, value, child) {
          return ValueListenableBuilder<Duration>(
            valueListenable: value.position,
            builder: (context, pos, child) {
              return _buildSlider(pos, media: value);
            },
          );
        },
      );
    } else {
      return StreamBuilder<Duration>(
        stream: widget.audioHandler.positionStream,
        builder: (context, snapshot) {
          final position = snapshot.data ?? Duration.zero;
          final total = widget.audioHandler.duration ?? Duration.zero;

          return _buildSlider(position, total: total);
        },
      );
    }
  }

  Widget _buildSlider(Duration position, {Duration? total, MediaAtual? media}) {
    final Duration durationTotal = media?.total ?? total ?? Duration.zero;

    final int maxMs = durationTotal.inMilliseconds;
    final int posMs = position.inMilliseconds.clamp(0, maxMs);

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            min: 0,
            max: maxMs.toDouble(),
            value: posMs.toDouble(),
            onChanged: (value) {
              final target = Duration(milliseconds: value.toInt());
              if (ekoConnected) {
                media?.seek(target);
              } else {
                widget.audioHandler.seek(target);
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Player.formatDuration(position, false),
                style: const TextStyle(fontFamily: 'Default-Thin'),
              ),
              Text(
                Player.formatDuration(durationTotal, false),
                style: const TextStyle(fontFamily: 'Default-Thin'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildPlayPauseButton() {
    if (ekoConnected) {
      return ValueListenableBuilder<MediaAtual>(
        valueListenable: MusyncAudioHandler.mediaAtual,
        builder: (context, mediaAtual, child) {
          return ValueListenableBuilder<bool>(
            valueListenable: mediaAtual.isPlaying,
            builder: (context, isPlaying, child) {
              return _buildButton(
                Icon(
                  isPlaying ? Icons.pause_outlined : Icons.play_arrow_outlined,
                  size: 45,
                ),
                () {
                  mediaAtual.sendPauseAndPlay(!isPlaying);
                },
                1,
              );
            },
          );
        },
      );
    }

    return StreamBuilder<bool>(
      stream: widget.audioHandler.playingStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        return _buildButton(
          Icon(
            isPlaying ? Icons.pause_outlined : Icons.play_arrow_outlined,
            size: 45,
          ),
          () {
            isPlaying
                ? widget.audioHandler.pause()
                : widget.audioHandler.play();
          },
          1,
        );
      },
    );
  }

  Widget buildAudioHandlerButtons(String type) {
    switch (type) {
      case 'next':
        return ValueListenableBuilder<ModeShuffleEnum>(
          valueListenable: widget.audioHandler.shuffleMode,
          builder: (context, value, child) {
            return _buildButton(
              value != ModeShuffleEnum.shuffleOptional
                  ? Icon(Icons.keyboard_double_arrow_right_sharp, size: 45)
                  : Image.asset(
                    'assets/dice.png',
                    color: baseAppColor,
                    colorBlendMode: BlendMode.srcIn,
                    width: 45,
                  ),
              () async {
                await widget.audioHandler.skipToNext();
              },
              1,
            );
          },
        );
      case 'prev':
        return _buildButton(
          Icon(Icons.keyboard_double_arrow_left_sharp, size: 45),
          () async {
            await widget.audioHandler.skipToPrevious();
          },
          1,
        );
      case 'shuffle':
        return ValueListenableBuilder<ModeShuffleEnum>(
          valueListenable: widget.audioHandler.shuffleMode,
          builder: (context, value, child) {
            return _buildButton(
              value != ModeShuffleEnum.shuffleOptional
                  ? Icon(
                    value == ModeShuffleEnum.shuffleNormal
                        ? Icons.shuffle
                        : Icons.arrow_right_alt_rounded,
                    size: 45,
                  )
                  : Image.asset(
                    'assets/dice.png',
                    color: baseAppColor,
                    colorBlendMode: BlendMode.srcIn,
                    width: 45,
                  ),
              () {
                widget.audioHandler.setShuffleModeEnabled();
              },
              3 / 2,
            );
          },
        );
      case 'repeat':
        return ValueListenableBuilder<ModeLoopEnum>(
          valueListenable: widget.audioHandler.loopMode,
          builder: (context, value, child) {
            return _buildButton(
              Icon(
                value == ModeLoopEnum.off
                    ? Icons.arrow_right_alt_rounded
                    : value == ModeLoopEnum.all
                    ? Icons.repeat_rounded
                    : Icons.repeat_one_rounded,
                size: 45,
              ),
              () {
                widget.audioHandler.setLoopModeEnabled();
              },
              3 / 2,
            );
          },
        );
      case 'next_playlist':
        return _buildButton(
          Icon(Icons.keyboard_double_arrow_right_sharp, size: 45),
          () async {
            await widget.audioHandler.skipPlaylist(true);
          },
          3 / 2,
        );
      case 'prev_playlist':
        return _buildButton(
          Icon(Icons.keyboard_double_arrow_left_sharp, size: 45),
          () async {
            await widget.audioHandler.skipPlaylist(false);
          },
          3 / 2,
        );
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildButton(Widget icon, VoidCallback onPressed, double aspect) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: aspect,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.all(15),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: onPressed,
          child: icon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        color: baseFundoDarkDark,
        child: Stack(
          children: [
            Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    height: 130,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                                  Player.titleText(mediaItem.artist ?? '', 13),
                                ],
                              ),
                            );
                          },
                        ),
                        buildSliderMusic(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildAudioHandlerButtons('prev'),
                    const SizedBox(width: 10),
                    buildPlayPauseButton(),
                    const SizedBox(width: 10),
                    buildAudioHandlerButtons('next'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildAudioHandlerButtons('shuffle'),
                    const SizedBox(width: 10),
                    buildAudioHandlerButtons('repeat'),
                  ],
                ),
                const SizedBox(height: 10),
                SoundControl(ekoConnected: ekoConnected),
                const SizedBox(height: 10),
                ValueListenableBuilder(
                  valueListenable: widget.audioHandler.atualPlaylist,
                  builder: (context, playlist, _) {
                    return SizedBox(
                      height: 130,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Card(
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    alignment: Alignment.center,
                                    child: StreamBuilder<String>(
                                      stream: _timeStream(),
                                      builder: (context, snapshot) {
                                        final time = snapshot.data ?? '--:--';

                                        return Text(
                                          time,
                                          style: const TextStyle(
                                            fontSize: 42,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: "Digital",
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.center,
                                    child: Text(
                                      DateFormat(
                                        "d 'de' MMM 'de' y",
                                        "pt_BR",
                                      ).format(DateTime.now()),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: "Digital",
                                        color: baseAppColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 15),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 0,
                                      ),
                                      child: Column(
                                        children: [
                                          Player.titleText(playlist.tag, 20),
                                          Player.titleText(
                                            playlist.subtitle,
                                            13,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 22.0,
                                          ),
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Positioned(
                                                left: 10,
                                                top: 7,
                                                child: Container(
                                                  width: 40,
                                                  height: 40,
                                                  alignment: Alignment.center,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Color.fromARGB(
                                                          255,
                                                          56,
                                                          45,
                                                          21,
                                                        ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 4,
                                                          right: 4,
                                                        ),
                                                    child: Align(
                                                      alignment:
                                                          Alignment.bottomRight,
                                                      child: Text(
                                                        '${playlist.qntTotal}',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: baseAppColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                width: 32,
                                                height: 32,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: baseAppColor,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Text(
                                                  '${playlist.nowPlaying + 1}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
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
                      ),
                    );
                  },
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildAudioHandlerButtons('prev_playlist'),
                    const SizedBox(width: 10),
                    buildAudioHandlerButtons('next_playlist'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
