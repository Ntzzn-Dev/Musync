import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musync_and/helpers/audio_player_helper.dart';
import 'package:musync_and/helpers/enum_helpers.dart';
import 'package:musync_and/services/audio_player.dart';
import 'package:musync_and/services/ekosystem.dart';
import 'package:musync_and/services/media_atual.dart';
import 'package:musync_and/themes.dart';
import 'package:musync_and/widgets/letreiro.dart';
import 'package:musync_and/widgets/sound_control.dart';

class Player extends StatefulWidget {
  const Player({super.key});

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
  @override
  void initState() {
    super.initState();
    musyncMediaUpdateNotifier.addListener(_onMediaChanged);
  }

  @override
  void dispose() {
    musyncMediaUpdateNotifier.removeListener(_onMediaChanged);
    super.dispose();
  }

  void _onMediaChanged() {
    final item = musyncMediaUpdateNotifier.lastUpdate;

    MusyncAudioHandler.mediaAtual.value = MediaAtual.fromMediaItem(item);
  }

  Widget buildShuffleButton() {
    return ValueListenableBuilder<ModeShuffleEnum>(
      valueListenable: mscAudPl.shuffleMode,
      builder: (context, shuffleMode, child) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: Size.zero,
            padding: EdgeInsets.all(15),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: const CircleBorder(),
          ),
          onPressed: () {
            mscAudPl.setShuffleModeEnabled();
          },
          child:
              shuffleMode != ModeShuffleEnum.shuffleOptional
                  ? Icon(
                    shuffleMode == ModeShuffleEnum.shuffleNormal
                        ? Icons.shuffle
                        : Icons.arrow_right_alt_rounded,
                  )
                  : Image.asset(
                    'assets/dice.png',
                    color: const Color.fromARGB(255, 243, 160, 34),
                    colorBlendMode: BlendMode.srcIn,
                    width: 18,
                  ),
        );
      },
    );
  }

  Widget buildLoopButton() {
    return ValueListenableBuilder<ModeLoopEnum>(
      valueListenable: mscAudPl.loopMode,
      builder: (context, value, child) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: Size.zero,
            padding: EdgeInsets.all(15),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: const CircleBorder(),
          ),
          onPressed: () async {
            mscAudPl.setLoopModeEnabled();
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
    );
  }

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
              stream: mscAudPl.mediaItem,
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
            eko.conected.value
                ? ValueListenableBuilder<MediaAtual>(
                  valueListenable: MusyncAudioHandler.mediaAtual,
                  builder: (context, value, child) {
                    return ValueListenableBuilder<Duration>(
                      valueListenable: value.position,
                      builder: (context, pos, child) {
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
                              child: Slider(
                                min: 0,
                                max: value.total.inMilliseconds.toDouble(),
                                value:
                                    pos.inMilliseconds
                                        .clamp(0, value.total.inMilliseconds)
                                        .toDouble(),
                                onChanged: (v) {
                                  value.seek(Duration(milliseconds: v.toInt()));
                                },
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
                                    Player.formatDuration(pos, false),
                                    style: TextStyle(
                                      fontFamily: 'Default-Thin',
                                    ),
                                  ),
                                  Text(
                                    'CONECTADO AO DESKTOP',
                                    style: TextStyle(
                                      fontFamily: 'Default-Thin',
                                      color: baseAppColor,
                                    ),
                                  ),
                                  Text(
                                    Player.formatDuration(value.total, false),
                                    style: TextStyle(
                                      fontFamily: 'Default-Thin',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                )
                : StreamBuilder<Duration>(
                  stream: mscAudPl.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final total = mscAudPl.duration ?? Duration.zero;

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
                                mscAudPl.seek(
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
                              Text(
                                Player.formatDuration(position, false),
                                style: TextStyle(fontFamily: 'Default-Thin'),
                              ),
                              Text(
                                Player.formatDuration(total, false),
                                style: TextStyle(fontFamily: 'Default-Thin'),
                              ),
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
                buildShuffleButton(),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.all(15),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: const CircleBorder(),
                  ),
                  onPressed: () async {
                    await mscAudPl.skipToPrevious();
                  },
                  child: Icon(Icons.keyboard_double_arrow_left_sharp),
                ),
                const SizedBox(width: 16),
                eko.conected.value
                    ? ValueListenableBuilder<MediaAtual>(
                      valueListenable: MusyncAudioHandler.mediaAtual,
                      builder: (context, value, child) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: value.isPlaying,
                          builder: (context, playing, child) {
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: EdgeInsets.all(15),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: const CircleBorder(),
                              ),
                              onPressed: () {
                                value.sendPauseAndPlay(!playing);
                              },
                              child: Icon(
                                playing
                                    ? Icons.pause_outlined
                                    : Icons.play_arrow_outlined,
                              ),
                            );
                          },
                        );
                      },
                    )
                    : StreamBuilder<bool>(
                      stream: mscAudPl.playingStream,
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
                            isPlaying ? mscAudPl.pause() : mscAudPl.play();
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
                  valueListenable: mscAudPl.shuffleMode,
                  builder: (context, value, child) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.all(15),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: const CircleBorder(),
                      ),
                      onPressed: () async {
                        await mscAudPl.skipToNext();
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
                buildLoopButton(),
              ],
            ),
            if (eko.conected.value) ...[
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SoundControl(height: 30),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
