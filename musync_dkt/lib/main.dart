import 'dart:developer';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musync_dkt/Services/audio_player.dart';
import 'package:musync_dkt/Services/media_music.dart';
import 'package:musync_dkt/Services/server_connect.dart';
import 'package:musync_dkt/Widgets/list_content.dart';
import 'package:musync_dkt/Widgets/player.dart';
import 'package:musync_dkt/Widgets/popup_add.dart';
import 'package:musync_dkt/themes.dart';

final MusyncAudioHandler player = MusyncAudioHandler();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Musync',
      theme: lighttheme(),
      darkTheme: darktheme(),
      themeMode: ThemeMode.system,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ValueNotifier<bool> connected = ValueNotifier(false);
  ValueNotifier<String> musicsPercent = ValueNotifier('0%');
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    startServer(connected, musicsPercent);
    _focusNode.requestFocus();
    player.setVolume(50);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleBottom() {
    bottomPosition.value = bottomPosition.value == -135 ? 0 : -135;
  }

  ValueNotifier<double> bottomPosition = ValueNotifier(0);

  bool? isLandscape;

  void checkOrientation(Size size) {
    bool landscape = size.width > size.height;
    if (isLandscape != landscape) {
      isLandscape = landscape;
      if (landscape) {
        print("Mudou para horizontal!");
      } else {
        print("Mudou para vertical!");
      }
    }
  }

  Future<Uint8List?> extractCoverWithProcess(String mp3Path) async {
    try {
      final args = [
        '-i',
        mp3Path,
        '-an',
        '-vcodec',
        'mjpeg',
        '-f',
        'image2pipe',
        'pipe:1',
      ];

      final process = await Process.run(
        'ffmpeg',
        args,
        stdoutEncoding: null,
        stderrEncoding: null,
      );

      if (process.exitCode != 0) {
        final errorOutput = String.fromCharCodes(process.stderr as List<int>);
        print('Erro FFmpeg: $errorOutput');
        return null;
      }

      final outputBytes = process.stdout as List<int>;
      if (outputBytes.isEmpty) {
        print('Nenhuma capa encontrada no MP3.');
        return null;
      }

      return Uint8List.fromList(outputBytes);
    } catch (e) {
      print('Erro ao executar FFmpeg: $e');
      return null;
    }
  }

  Future<Uint8List?>? coverFuture;

  Widget mainList(bool isLandscape) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Stack(
            children: [
              ValueListenableBuilder<List<MediaMusic>>(
                valueListenable: player.songsAtual,
                builder: (context, value, child) {
                  return ListContent(
                    audioHandler: player,
                    songsNow: player.songsAtual.value,
                    modeReorder: ModeOrderEnum.dataAZ,
                    aposClique: (item) async {
                      int indiceCerto = player.songsAtual.value.indexWhere(
                        (t) => t == item,
                      );
                      player.setIndex(indiceCerto);
                    },
                  );
                },
              ),
              if (!isLandscape) mainPlayer(),
            ],
          ),
        ),
        if (isLandscape)
          Expanded(
            flex: 1,
            child: Container(
              color: Color(0xFF1B1A1A),
              child: Stack(
                children: [
                  Positioned(
                    top: 20,
                    right: 50,
                    left: 50,
                    child: ValueListenableBuilder<int>(
                      valueListenable: player.currentIndex,
                      builder: (context, index, _) {
                        final songs = player.songsAtual.value;

                        if (songs.isEmpty ||
                            index < 0 ||
                            index >= songs.length) {
                          return const SizedBox.shrink();
                        }

                        final songPath = songs[index].path;
                        log(songPath);

                        coverFuture = extractCoverWithProcess(songPath);
                        return FutureBuilder<Uint8List?>(
                          future: coverFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[900],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            }

                            if (!snapshot.hasData || snapshot.data == null) {
                              return Image.memory(
                                songs[index].artUri,
                                fit: BoxFit.contain,
                              );
                            } else {
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                  mainPlayer(),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget mainPlayer() {
    return ValueListenableBuilder<double>(
      valueListenable: bottomPosition,
      builder: (context, value, child) {
        return AnimatedPositioned(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          bottom: value,
          left: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              _toggleBottom();
            },
            child: Player(player: player),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Size size = Size(constraints.maxWidth, constraints.maxHeight);
        checkOrientation(size);

        return KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.space) {
                if (player.playstate.value == PlayerState.playing) {
                  player.pause();
                } else {
                  player.resume();
                }
              }
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Músicas Recebidas'),
              actions: [
                ValueListenableBuilder<String>(
                  valueListenable: musicsPercent,
                  builder: (context, value, child) {
                    final qnts = RegExp(
                      r'^\s*(\d+)\s*/\s*(\d+)\s*$',
                    ).firstMatch(musicsLoaded)?.group(2);

                    return Tooltip(
                      message: 'Músicas carregadas: $musicsLoaded',
                      child: Row(
                        children: [
                          Icon(Icons.music_note_outlined),
                          Text(value == '100.0%' ? qnts ?? '' : value),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 9),
                ValueListenableBuilder<bool>(
                  valueListenable: connected,
                  builder: (context, value, child) {
                    if (value) {
                      return GestureDetector(
                        onTap: () async {
                          if (await showPopupAdd(
                            context,
                            'Conectado ao smartphone\nDeseja deconectar?',
                            [],
                          )) {
                            socket.close();
                          }
                        },
                        child: Icon(Icons.connected_tv),
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
                const SizedBox(width: 9),
                ElevatedButton(
                  onPressed: () => enableQRCode(context, connected),
                  child: Icon(Icons.qr_code_rounded),
                ),
              ],
            ),
            body: mainList(isLandscape ?? true),
          ),
        );
      },
    );
  }
}
