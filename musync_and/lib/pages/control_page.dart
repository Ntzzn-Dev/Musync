import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:musync_and/helpers/control_helper.dart';
import 'package:musync_and/helpers/menu_helper.dart';
import 'package:musync_and/services/audio_player.dart';
import 'package:musync_and/helpers/audio_player_helper.dart';
import 'package:musync_and/services/ekosystem.dart';
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
  Stream<String> _timeStream() async* {
    yield* Stream.periodic(const Duration(seconds: 1), (_) {
      return DateFormat('HH:mm').format(DateTime.now());
    });
  }

  bool swapBtns = false;

  @override
  void initState() {
    super.initState();
    swapBtns = eko.conected.value ? true : false;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget buildExtraPlayerButtons(ExtraButtonTypes type) {
    switch (type) {
      case ExtraButtonTypes.nextBtn:
        if (swapBtns) {
          return buildButton(
            Icon(Icons.favorite, size: 45),
            () async {
              await mscAudPl.skipPlaylist(true);
              setState(() {});
            },
            2 / 2,
            1,
          );
        } else {
          return buildButton(
            Icon(Icons.keyboard_double_arrow_right_sharp, size: 45),
            () async {
              await mscAudPl.skipPlaylist(true);
              setState(() {});
            },
            2 / 2,
            1,
          );
        }
      case ExtraButtonTypes.prevBtn:
        if (swapBtns) {
          return buildButton(
            Icon(Icons.track_changes_rounded, size: 45),
            () async {
              await mscAudPl.skipPlaylist(false);
              setState(() {});
            },
            2 / 2,
            1,
          );
        } else {
          return buildButton(
            Icon(Icons.keyboard_double_arrow_left_sharp, size: 45),
            () async {
              await mscAudPl.skipPlaylist(false);
              setState(() {});
            },
            2 / 2,
            1,
          );
        }
      case ExtraButtonTypes.modal:
        return buildButton(
          Icon(Icons.swap_horiz_rounded, size: 45),
          () async {
            if (!eko.conected.value) {
              setState(() {
                swapBtns = !swapBtns;
              });
            } else {
              showSnack('Indisponível enquanto conectado ao desktop', context);
            }
            //mscAudPl.returnToCheckpoint();
          },
          2 / 2,
          1,
        );
    }
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
                    buildAudioHandlerButtons(ButtonTypes.prev),
                    const SizedBox(width: 10),
                    buildPlayPauseButton(),
                    const SizedBox(width: 10),
                    buildAudioHandlerButtons(ButtonTypes.next),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildAudioHandlerButtons(ButtonTypes.shuffle),
                    const SizedBox(width: 10),
                    buildAudioHandlerButtons(ButtonTypes.repeat),
                  ],
                ),
                const SizedBox(height: 10),
                SoundControl(),
                const SizedBox(height: 10),
                ValueListenableBuilder(
                  valueListenable: mscAudPl.actlist.atualPlaylist,
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
                                          Player.titleText(playlist.title, 20),
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
                                                        '${mscAudPl.actlist.getLengthMusicListAtual()}',
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
                                                  '${widget.audioHandler.currentIndex.value + 1}',
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
                    buildExtraPlayerButtons(ExtraButtonTypes.prevBtn),
                    const SizedBox(width: 10),
                    buildExtraPlayerButtons(ExtraButtonTypes.modal),
                    const SizedBox(width: 10),
                    buildExtraPlayerButtons(ExtraButtonTypes.nextBtn),
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
