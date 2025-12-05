import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musync_and/services/audio_player_base.dart';
import 'package:musync_and/services/media_atual.dart';
import 'package:musync_and/widgets/player.dart';
import 'package:musync_and/widgets/sound_control.dart';

class EkoPlayer extends StatefulWidget {
  final MusyncAudioHandler audioHandler;

  const EkoPlayer({super.key, required this.audioHandler});

  @override
  State<EkoPlayer> createState() => _EkoPlayerState();
}

class _EkoPlayerState extends State<EkoPlayer> {
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


  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      surfaceTintColor: const Color.fromARGB(0, 255, 1, 1),
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

            ValueListenableBuilder<MediaAtual>(
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
                          padding: const EdgeInsets.symmetric(horizontal: 22.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                Player.formatDuration(pos, false),
                                style: TextStyle(fontFamily: 'Default-Thin'),
                              ),
                              Text(
                                Player.formatDuration(value.total, false),
                                style: TextStyle(fontFamily: 'Default-Thin'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ValueListenableBuilder<ModeShuffleEnum>(
                  valueListenable: widget.audioHandler.shuffleMode,
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
                ValueListenableBuilder<MediaAtual>(
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
                ),
                const SizedBox(width: 16),
                ValueListenableBuilder<ModeShuffleEnum>(
                  valueListenable: widget.audioHandler.shuffleMode,
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
                  valueListenable: widget.audioHandler.loopMode,
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
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SoundControl(ekoConnected: true, height: 30),
            ),
          ],
        ),
      ),
    );
  }
}
