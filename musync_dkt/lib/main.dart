import 'dart:developer';
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
import 'package:audiotags/audiotags.dart';
import 'package:window_manager/window_manager.dart';

final MusyncAudioHandler audPl = MusyncAudioHandler();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
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
    audPl.setVolume(50);

    audPl.currentIndex.addListener(_onCurrentIndexChanged);
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

  bool isLandscape = false;

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

  Future<Uint8List?>? _artFuture;
  String? _currentPath;

  void _onCurrentIndexChanged() {
    final index = audPl.currentIndex.value;
    final songs = audPl.songsAtual.value;

    if (songs.isEmpty || index < 0) return;

    final songPath = songs[index].path;

    if (_currentPath != songPath) {
      _currentPath = songPath;
      setState(() {
        _artFuture = getTags(songPath);
      });
    }
  }

  Future<Uint8List?> getTags(String path) async {
    try {
      final tag = await AudioTags.read(path);

      if (tag == null) {
        return null;
      }

      if (tag.pictures.isEmpty) {
        return null;
      }

      final bytes = tag.pictures.first.bytes;
      return bytes;
    } catch (e, s) {
      log('ERRO ao ler tags Exception: $e Stack: $s');
      return null;
    }
  }

  Widget buildPlayer() {
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
            child: Player(audPl: audPl),
          ),
        );
      },
    );
  }

  Widget mainList() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Stack(
            children: [
              ValueListenableBuilder<List<MediaMusic>>(
                valueListenable: audPl.songsAtual,
                builder: (context, value, child) {
                  return ListContent(
                    audioHandler: audPl,
                    songsNow: audPl.songsAtual.value,
                    modeReorder: ModeOrderEnum.dataAZ,
                    aposClique: (item) async {
                      int indiceCerto = audPl.songsAtual.value.indexWhere(
                        (t) => t == item,
                      );
                      audPl.setIndex(indiceCerto);
                    },
                  );
                },
              ),
              if (!isLandscape) buildPlayer(),
            ],
          ),
        ),
        if (isLandscape)
          Expanded(
            flex: 1,
            child: Container(
              color: Color(0xFF242424),
              child: Stack(
                children: [
                  Positioned(
                    top: 20,
                    right: 50,
                    left: 50,
                    child: FutureBuilder<Uint8List?>(
                      future: _artFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            width: 150,
                            height: 150,
                            color: Colors.grey[900],
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          log('Erro carregando arte: ${snapshot.error}');
                          return Container(
                            width: 150,
                            height: 150,
                            color: Colors.grey[850],
                            child: const Icon(
                              Icons.broken_image,
                              size: 60,
                              color: Colors.white54,
                            ),
                          );
                        }

                        if (!snapshot.hasData ||
                            snapshot.data == null ||
                            snapshot.data!.isEmpty) {
                          return Container(
                            width: 150,
                            height: 150,
                            color: Colors.grey[850],
                            child: const Icon(
                              Icons.music_note,
                              size: 60,
                              color: Colors.white38,
                            ),
                          );
                        }

                        return Align(
                          alignment: Alignment.topCenter,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 350),
                              child: Image.memory(
                                snapshot.data!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  log('ERRO no Image.memory: $error');
                                  return Container(
                                    width: 150,
                                    height: 150,
                                    color: Colors.grey[850],
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 60,
                                      color: Colors.white54,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  buildPlayer(),
                ],
              ),
            ),
          ),
      ],
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
                if (audPl.playstate.value == PlayerState.playing) {
                  audPl.pause();
                } else {
                  audPl.resume();
                }
              }
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: ValueListenableBuilder<String>(
                valueListenable: audPl.playlistName,
                builder: (context, name, child) {
                  return Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      fontFamily: 'Titles',
                    ),
                  );
                },
              ),
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
            body: mainList(),
          ),
        );
      },
    );
  }
}
