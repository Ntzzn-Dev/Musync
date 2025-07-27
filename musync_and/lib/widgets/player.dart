import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musync_and/services/audio_player_base.dart';
import 'package:musync_and/widgets/letreiro.dart';

class Player extends StatefulWidget {
  final MyAudioHandler audioHandler;

  const Player({super.key, required this.audioHandler});

  static String formatDuration(Duration d, bool h) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '${h ? '$hours:' : ''}$minutes:$seconds';
  }

  static Widget titleText(String text, double fontsize) {
    return Letreiro(
      key: ValueKey(text),
      texto: text,
      blankSpace: 90,
      fullTime: 12,
      timeStoped: 1500,
      fontSize: fontsize,
    );
  }

  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  ValueNotifier<ModeShuffleEnum> toRandom = ValueNotifier(
    ModeShuffleEnum.shuffleOff,
  );
  ValueNotifier<ModeLoopEnum> toLoop = ValueNotifier(ModeLoopEnum.off);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
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
                      Player.titleText(mediaItem.title, 16),
                      Player.titleText(mediaItem.artist ?? '', 11),
                    ],
                  ),
                );
              },
            ),
            StreamBuilder<Duration>(
              stream: widget.audioHandler.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final total = widget.audioHandler.duration ?? Duration.zero;

                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 0),
                        child: Slider(
                          min: 0,
                          max: total.inMilliseconds.toDouble(),
                          value:
                              position.inMilliseconds
                                  .clamp(0, total.inMilliseconds)
                                  .toDouble(),
                          onChanged: (value) {
                            widget.audioHandler.seek(
                              Duration(milliseconds: value.toInt()),
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(Player.formatDuration(position, false)),
                          Text(Player.formatDuration(total, false)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ValueListenableBuilder<ModeShuffleEnum>(
                  valueListenable: toRandom,
                  builder: (context, value, child) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.all(15),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: const CircleBorder(),
                      ),
                      onPressed: () {
                        widget.audioHandler.setShuffleModeEnabled();
                        toRandom.value = value.next();
                      },
                      child:
                          value != ModeShuffleEnum.shuffleOptional
                              ? Icon(
                                value == ModeShuffleEnum.shuffleNormal
                                    ? Icons.shuffle
                                    : Icons.arrow_right_alt_rounded,
                              )
                              : Image.asset(
                                'assets/dice.png',
                                color: Color.fromARGB(255, 243, 160, 34),
                                colorBlendMode: BlendMode.srcIn,
                                width: 18,
                              ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.all(15),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: const CircleBorder(),
                  ),
                  onPressed: () async {
                    await widget.audioHandler.skipToPrevious();
                  },
                  child: Icon(Icons.keyboard_double_arrow_left_sharp),
                ),
                const SizedBox(width: 16),
                StreamBuilder<bool>(
                  stream: widget.audioHandler.playingStream,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data ?? false;
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.all(15),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: const CircleBorder(),
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
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                ValueListenableBuilder<ModeShuffleEnum>(
                  valueListenable: toRandom,
                  builder: (context, value, child) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.all(15),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: const CircleBorder(),
                      ),
                      onPressed: () async {
                        await widget.audioHandler.skipToNext();
                      },
                      child:
                          value != ModeShuffleEnum.shuffleOptional
                              ? Icon(Icons.keyboard_double_arrow_right_sharp)
                              : Image.asset(
                                'assets/dice.png',
                                color: Color.fromARGB(255, 243, 160, 34),
                                colorBlendMode: BlendMode.srcIn,
                                width: 18,
                              ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                ValueListenableBuilder<ModeLoopEnum>(
                  valueListenable: toLoop,
                  builder: (context, value, child) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.all(15),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: const CircleBorder(),
                      ),
                      onPressed: () async {
                        widget.audioHandler.setLoopModeEnabled();
                        toLoop.value = value.next();
                      },
                      child: Icon(
                        value == ModeLoopEnum.off
                            ? Icons.arrow_right_alt_rounded
                            : value == ModeLoopEnum.all
                            ? Icons.repeat_rounded
                            : Icons.repeat_one_rounded,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
