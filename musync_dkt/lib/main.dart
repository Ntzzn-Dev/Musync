import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musync_dkt/services/audio_player.dart';
import 'package:musync_dkt/services/media_music.dart';
import 'package:musync_dkt/services/server_connect.dart';
import 'package:musync_dkt/widgets/list_content.dart';
import 'package:musync_dkt/widgets/player.dart';
import 'package:musync_dkt/widgets/popup_add.dart';
import 'package:musync_dkt/themes.dart';
import 'package:audiotags/audiotags.dart';
import 'package:window_manager/window_manager.dart';
import 'package:diacritic/diacritic.dart';

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
  final TextEditingController _searchController = TextEditingController();
  ValueNotifier<bool> connected = ValueNotifier(false);
  ValueNotifier<String> musicsPercent = ValueNotifier('0%');
  final FocusNode _focusNode = FocusNode();
  double screenHeight = 0;
  ValueNotifier<bool> showlog = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    startServer(connected, musicsPercent);
    enableQRCode(context, connected);
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
    screenHeight = size.height;
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
    final songs = audPl.songsNow.value;

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

  Widget buildCover() {
    return FutureBuilder<Uint8List?>(
      future: _artFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 150,
            height: 150,
            color: Colors.grey[900],
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
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
              constraints: BoxConstraints(maxHeight: screenHeight * 0.5),
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
    );
  }

  Widget buildLog() {
    return ValueListenableBuilder<List<Map<String, String>>>(
      valueListenable: entradasESaidas,
      builder: (context, logs, _) {
        if (logs.isEmpty) {
          return const Text(
            'LOG vazio',
            style: TextStyle(color: Colors.white54),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('LOG:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: screenHeight * 0.5,
              child: ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final item = logs[index];

                  final isEntrada = item.containsKey('Entrada');
                  final text = item['Entrada'] ?? item['Saida'] ?? '';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _buildColoredText(text, isEntrada),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  //Permite visualização de valores desnecessários para o sistema, mas necessários para diagnóstico visual.
  Widget _buildColoredText(String text, bool isEntrada) {
    const marker = 'DEVE SER APAGADO: ';

    final defaultColor = isEntrada ? Colors.greenAccent : Colors.orangeAccent;

    if (!text.contains(marker)) {
      return Text(text, style: TextStyle(fontSize: 12, color: defaultColor));
    }

    final parts = text.split(marker);

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        children: [
          TextSpan(text: parts[0], style: TextStyle(color: defaultColor)),
          TextSpan(
            text: marker + (parts.length > 1 ? parts[1] : ''),
            style: const TextStyle(color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget mainList() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Stack(
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                Theme.of(
                                  context,
                                ).extension<CustomColors>()!.textForce,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Pesquisa',
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              audPl.songsNow.value =
                                  audPl.songsAtual
                                      .where(
                                        (item) => removeDiacritics(item.title)
                                            .toLowerCase()
                                            .contains(value.toLowerCase()),
                                      )
                                      .toList();
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          _searchController.clear();
                          audPl.songsNow.value = audPl.songsAtual;
                        },
                        icon: Icon(
                          Icons.close,
                          color: Theme.of(context).focusColor,
                        ),
                      ),
                    ],
                  ),

                  Expanded(
                    child: ValueListenableBuilder<List<MediaMusic>>(
                      valueListenable: audPl.songsNow,
                      builder: (context, songsNow, child) {
                        return ListContent(
                          audioHandler: audPl,
                          songsNow: songsNow,
                          modeReorder: ModeOrderEnum.dataAZ,
                          aposClique: (item) async {
                            int indiceCerto = audPl.songsAtual.indexWhere(
                              (t) => t == item,
                            );
                            audPl.setIndex(indiceCerto);
                          },
                        );
                      },
                    ),
                  ),
                ],
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
                    child: ValueListenableBuilder<bool>(
                      valueListenable: showlog,
                      builder: (_, value, a) {
                        if (value) {
                          return buildLog();
                        } else {
                          return buildCover();
                        }
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
              title: ValueListenableBuilder<SetList>(
                valueListenable: audPl.playlistName,
                builder: (context, playlist, child) {
                  return Row(
                    children: [
                      Text(
                        playlist.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          fontFamily: 'Titles',
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        playlist.subtitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w200,
                          fontSize: 10,
                          fontFamily: 'Titles',
                        ),
                      ),
                    ],
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
                  onLongPress: () => {showlog.value = !showlog.value},
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
