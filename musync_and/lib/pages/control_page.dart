import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:musync_and/services/audio_player_base.dart';
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
                SizedBox(
                  height: 130,
                  child: Row(
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
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                                        Icons.keyboard_double_arrow_right_sharp,
                                        size: 45,
                                      )
                                      : Image.asset(
                                        'assets/dice.png',
                                        color: baseAppColor,
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
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                                        color: baseAppColor,
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
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                                padding: EdgeInsetsGeometry.symmetric(
                                  vertical: 15,
                                ),
                                child: Column(
                                  children: [
                                    Padding(
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
                                                        '${playlist['qntTotal']}',
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
                                                  '${playlist['nowPlaying'] + 1}',
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
                            await widget.audioHandler.skipPlaylist(false);
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
                            await widget.audioHandler.skipPlaylist(true);
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
    );
  }
}
