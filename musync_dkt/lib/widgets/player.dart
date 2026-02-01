import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:musync_dkt/services/audio_player.dart';
import 'package:musync_dkt/services/media_music.dart';
import 'package:musync_dkt/services/server_connect.dart';
import 'package:musync_dkt/widgets/letreiro.dart';
import 'package:musync_dkt/widgets/sound_control.dart';

class Player extends StatefulWidget {
  final MusyncAudioHandler audPl;

  const Player({super.key, required this.audPl});

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
  Duration total = Duration.zero;
  Duration position = Duration.zero;

  late final StreamSubscription<Duration> _durationSub;
  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<PlayerState> _stateSub;

  void getTotal() async {
    total = await widget.audPl.getDuration() ?? Duration.zero;
  }

  @override
  void initState() {
    super.initState();

    getTotal();

    _durationSub = widget.audPl.onDurationChanged.listen((d) {
      if (mounted) {
        setState(() {
          total = d;
        });
      }
    });

    _positionSub = widget.audPl.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() {
          position = p;
        });
      }
    });

    _stateSub = widget.audPl.onPlayerStateChanged.listen((s) {
      widget.audPl.playstate.value = s;
      sendMessageAnd({
        'action': 'toggle_play',
        'data': s == PlayerState.playing,
      });
    });
  }

  @override
  void dispose() {
    _durationSub.cancel();
    _positionSub.cancel();
    _stateSub.cancel();
    super.dispose();
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
            ValueListenableBuilder<MediaMusic>(
              valueListenable: widget.audPl.musicAtual,
              builder: (context, value, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 0,
                  ),
                  child: Column(
                    children: [
                      Player.titleText(value.title, 18),
                      Player.titleText(value.artist, 13),
                    ],
                  ),
                );
              },
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
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
                    final newPos = Duration(milliseconds: value.toInt());
                    widget.audPl.seek(newPos);
                    setState(() {
                      position = newPos;
                    });

                    sendMessageAnd({
                      'action': 'position',
                      'data': position.inMilliseconds.toDouble(),
                    });
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ValueListenableBuilder<ModeShuffleEnum>(
                  valueListenable: widget.audPl.shuffleMode,
                  builder: (context, value, child) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.all(15),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: const CircleBorder(),
                      ),
                      onPressed: () {
                        widget.audPl.setShuffleModeEnabled();
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
                    widget.audPl.prev();
                  },
                  child: Icon(Icons.keyboard_double_arrow_left_sharp),
                ),
                const SizedBox(width: 16),
                ValueListenableBuilder<PlayerState>(
                  valueListenable: widget.audPl.playstate,
                  builder: (context, value, child) {
                    final isPlaying = value == PlayerState.playing;
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.all(15),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: const CircleBorder(),
                      ),
                      onPressed: () {
                        isPlaying
                            ? widget.audPl.pause()
                            : widget.audPl.resume();
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
                  valueListenable: widget.audPl.shuffleMode,
                  builder: (context, value, child) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.all(15),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: const CircleBorder(),
                      ),
                      onPressed: () async {
                        widget.audPl.next();
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
                  valueListenable: widget.audPl.loopMode,
                  builder: (context, value, child) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.all(15),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: const CircleBorder(),
                      ),
                      onPressed: () async {
                        widget.audPl.setLoopModeEnabled();
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
              child: ValueListenableBuilder<double>(
                valueListenable: widget.audPl.vol,
                builder: (context, vol, child) {
                  return Row(
                    children: [
                      IconButton(
                        onPressed: () => widget.audPl.toggleMute(),
                        icon: Icon(
                          vol <= 0
                              ? Icons.volume_mute_rounded
                              : vol > 0 && vol <= 49
                              ? Icons.volume_down_rounded
                              : Icons.volume_up_rounded,
                          color: Theme.of(context).focusColor,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: SoundControl(audPl: widget.audPl, height: 30),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
