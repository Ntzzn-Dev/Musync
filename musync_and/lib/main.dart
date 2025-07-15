import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musync_and/services/databasehelper.dart';
import 'package:musync_and/services/fetch_songs.dart';
import 'package:http/http.dart' as http;
import 'package:musync_and/services/playlists.dart';
import 'package:musync_and/widgets/list_content.dart';
import 'package:musync_and/widgets/player.dart';
import 'package:musync_and/widgets/popup.dart';
import 'package:musync_and/widgets/popup_add.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_service/audio_service.dart';
import 'themes.dart';
import 'services/audio_player_base.dart';

MyAudioHandler _audioHandler = MyAudioHandler();

enum ModeOrderEnum { titleAZ, titleZA, dataAZ, dataZA }

extension ModeEnumExt on ModeOrderEnum {
  ModeOrderEnum next() {
    final nextIndex = (index + 1) % ModeOrderEnum.values.length;
    return ModeOrderEnum.values[nextIndex];
  }

  ModeOrderEnum convert(int i) {
    return ModeOrderEnum.values[i - 1];
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.nathandv.musync_and',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
    ),
  );
  //await DatabaseHelper().deleteDatabaseFile();
  runApp(MyApp());
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
      home: MusicPage(audioHandler: _audioHandler),
    );
  }
}

class MusicPage extends StatefulWidget {
  final MyAudioHandler audioHandler;

  const MusicPage({super.key, required this.audioHandler});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  final TextEditingController _ipController = TextEditingController();
  String pcIp = '';
  ValueNotifier<bool> toRandom = ValueNotifier(false);
  ValueNotifier<int> toLoop = ValueNotifier(0);
  double bottomPosition = 0;
  int abaSelect = 0;
  int idplAtual = -1;

  var modeAtual = ModeOrderEnum.titleAZ;

  List<MediaItem> songsAll = [];
  List<MediaItem> songsNow = [];
  List<Playlists> pls = [];

  void _toggleBottom() {
    setState(() {
      bottomPosition = bottomPosition == 0 ? -100 : 0;
    });
  }

  @override
  void initState() {
    super.initState();
    _savePreferences();
    _initFetchSongs();
    _loadLastUse();
    _loadIp();
  }

  Future<void> _initFetchSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final dirStrings = prefs.getStringList('directorys') ?? [];

    final fetchedSongs = await FetchSongs.execute(paths: dirStrings);

    setState(() {
      songsAll = fetchedSongs;
      songsNow = songsAll;
    });

    widget.audioHandler.initSongs(songs: songsAll);
  }

  Future<void> reorder(ModeOrderEnum modeAtual) async {
    switch (modeAtual) {
      case ModeOrderEnum.titleAZ:
        final ordenadas = [...songsNow]
          ..sort((a, b) => a.title.trim().compareTo(b.title.trim()));
        setState(() {
          songsNow = ordenadas;
        });
        break;
      case ModeOrderEnum.titleZA:
        final ordenadas = [...songsNow]
          ..sort((a, b) => b.title.trim().compareTo(a.title.trim()));
        setState(() {
          songsNow = ordenadas;
        });
        break;
      case ModeOrderEnum.dataAZ:
        setState(() {
          songsNow.sort((a, b) {
            try {
              final rawA = a.extras?['lastModified'];
              final rawB = b.extras?['lastModified'];

              final dateA = rawA is String ? DateTime.tryParse(rawA) : null;
              final dateB = rawB is String ? DateTime.tryParse(rawB) : null;

              if (dateA == null || dateB == null) {
                return 0;
              }
              return dateA.compareTo(dateB);
            } catch (e) {
              log('Erro durante sort por data: $e');
              return 0;
            }
          });
        });

        break;
      case ModeOrderEnum.dataZA:
        setState(() {
          songsNow.sort((a, b) {
            try {
              final rawA = a.extras?['lastModified'];
              final rawB = b.extras?['lastModified'];

              final dateA = rawA is String ? DateTime.tryParse(rawA) : null;
              final dateB = rawB is String ? DateTime.tryParse(rawB) : null;

              if (dateA == null || dateB == null) {
                return 0;
              }
              return dateB.compareTo(dateA);
            } catch (e) {
              log('Erro durante sort por data: $e');
              return 0;
            }
          });
        });

        break;
    }
  }

  Future<void> _sendFileToPC(File file) async {
    if (pcIp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Defina o IP do PC primeiro.')),
      );
      return;
    }

    final url = Uri.parse('http://$pcIp:8080/upload');

    try {
      var request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      var response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Arquivo enviado!')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Erro ao enviar arquivo')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _loadIp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      pcIp = prefs.getString('pc_ip') ?? '';
      _ipController.text = pcIp;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('random_act', toRandom.value);
    prefs.setInt('loop_act', toLoop.value);
    prefs.setStringList('directorys', [
      '/storage/emulated/0/snaptube/download/SnapTube Audio',
    ]);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    toRandom.value = prefs.getBool('random_act') ?? false;
    toLoop.value = prefs.getInt('loop_act') ?? 0;
  }

  void _loadLastUse() async {
    _loadPreferences();

    widget.audioHandler.setShuffleModeEnabled(toRandom.value);

    final intToLoopMode = {0: LoopMode.off, 1: LoopMode.one, 2: LoopMode.all};

    LoopMode selectedMode = intToLoopMode[toLoop.value] ?? LoopMode.off;

    widget.audioHandler.setLoopModeEnabled(selectedMode);
  }

  dynamic convertReorder(dynamic value) {
    int? reorderFromString(String str) =>
        {'Titulo A-Z': 1, 'Titulo Z-A': 2, 'Data A-Z': 3, 'Data Z-A': 4}[str];

    String? reorderFromInt(int val) =>
        {1: 'Titulo A-Z', 2: 'Titulo Z-A', 3: 'Data A-Z', 4: 'Data Z-A'}[val];

    if (value is int) return reorderFromInt(value);
    if (value is String) return reorderFromString(value);
    return null;
  }

  Widget pageSelect(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        labelText: 'IP do PC',
                        hintText: 'ex: 192.xxx.x.x',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('pc_ip', _ipController.text.trim());
                      setState(() {
                        pcIp = _ipController.text.trim();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('IP salvo!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            ListContent(audioHandler: widget.audioHandler, songsNow: songsNow),
          ],
        );
      case 1:
        return Column(
          children: [
            ElevatedButton(
              onPressed: () {
                showPopupAdd(
                  context,
                  'Adicionar Playlist',
                  [
                    {'value': 'Título', 'type': 'necessary'},
                    {'value': 'Subtitulo', 'type': 'text'},
                    {
                      'value': 'Modo de organização',
                      'type': 'dropdown',
                      'opts': [
                        'Titulo A-Z',
                        'Titulo Z-A',
                        'Data A-Z',
                        'Data Z-A',
                      ],
                    },
                  ],
                  onConfirm: (valores) async {
                    DatabaseHelper().insertPlaylist(
                      valores[0],
                      valores[1],
                      1,
                      convertReorder(valores[2]),
                    );

                    final plss = await DatabaseHelper().loadPlaylists();

                    setState(() {
                      pls = plss;
                    });
                  },
                );
              },
              child: Text('+'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: pls.length,
                itemBuilder: (context, index) {
                  final item = pls[index];
                  // ADD BUTTON DE RETOMADA, SALVANDO MUSICA E PLAYSLIST LAST
                  return ListTile(
                    contentPadding: EdgeInsets.only(left: 16, right: 8),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        color:
                            Theme.of(
                              context,
                            ).extension<CustomColors>()!.textForce,
                      ),
                    ),
                    subtitle: Text(
                      item.subtitle,
                      style: TextStyle(
                        color:
                            Theme.of(
                              context,
                            ).extension<CustomColors>()!.subtextForce,
                      ),
                    ),
                    trailing: SizedBox(
                      width: 52,
                      height: 52,
                      child: IconButton(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color:
                              Theme.of(
                                context,
                              ).extension<CustomColors>()!.textForce,
                        ),
                        iconSize: 24,
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          await showPopup(context, item.title, [
                            {
                              'opt': 'Apagar Playlist',
                              'funct': () async {
                                if (await showPopupAdd(
                                  context,
                                  'Deletar playlist?',
                                  [],
                                )) {
                                  await DatabaseHelper().removePlaylist(
                                    item.id,
                                  );

                                  pls = await DatabaseHelper().loadPlaylists();

                                  setState(() {});

                                  Navigator.of(context).pop();
                                }
                              },
                            },
                            {
                              'opt': 'Editar Playlist',
                              'funct': () async {
                                await showPopupAdd(
                                  context,
                                  'Editar Playlist',
                                  [
                                    {'value': 'Título', 'type': 'necessary'},
                                    {'value': 'Subtitulo', 'type': 'text'},
                                    {
                                      'value': 'Modo de organização',
                                      'type': 'dropdown',
                                      'opts': [
                                        'Titulo A-Z',
                                        'Titulo Z-A',
                                        'Data A-Z',
                                        'Data Z-A',
                                      ],
                                    },
                                  ],
                                  fieldValues: [
                                    item.title,
                                    item.subtitle,
                                    convertReorder(item.orderMode),
                                  ],
                                  onConfirm: (valores) async {
                                    await DatabaseHelper().updatePlaylist(
                                      item.id,
                                      title: valores[0],
                                      subtitle: valores[1],
                                      orderMode: convertReorder(valores[2]),
                                    );

                                    pls =
                                        await DatabaseHelper().loadPlaylists();

                                    setState(() {});

                                    await ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text('Playlist Atualizada'),
                                      ),
                                    );
                                  },
                                );
                                Navigator.of(context).pop();
                              },
                            },
                          ]);
                        },
                      ),
                    ),
                    onTap: () async {
                      abaSelect = 2;
                      modeAtual = modeAtual.convert(item.orderMode);
                      final newsongs = await item.findMusics(songsAll);
                      if (newsongs != null) {
                        setState(() {
                          songsNow = newsongs;
                        });
                      }
                      reorder(modeAtual);
                      idplAtual = item.id;
                    },
                  );
                },
              ),
            ),
          ],
        );
      case 2:
        return Column(
          children: [
            ListContent(audioHandler: widget.audioHandler, songsNow: songsNow),
          ],
        );
      default:
        return SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Musync'),
        actions: [
          ElevatedButton(
            onPressed: () async {
              modeAtual = modeAtual.next();
              await reorder(modeAtual);
              log('$abaSelect $idplAtual');
              if (abaSelect == 2 && idplAtual != -1) {
                //saveOrder();
              }
            },
            child: Icon(Icons.reorder_outlined),
          ),
          SizedBox(width: 9),
          ElevatedButton(onPressed: () async {}, child: Icon(Icons.settings)),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          abaSelect = 0;
                        });
                        songsNow = songsAll;
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          border: Border(
                            bottom: BorderSide(
                              color:
                                  abaSelect == 0
                                      ? Color.fromARGB(255, 243, 160, 34)
                                      : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          'Todas',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        pls = await DatabaseHelper().loadPlaylists();
                        setState(() {
                          abaSelect = 1;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          border: Border(
                            bottom: BorderSide(
                              color:
                                  abaSelect == 1
                                      ? Color.fromARGB(255, 243, 160, 34)
                                      : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          'Playlists',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(child: pageSelect(abaSelect)),
            ],
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            bottom: bottomPosition,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: _toggleBottom,
              child: Player(audioHandler: widget.audioHandler),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.audioHandler.stop();
    super.dispose();
  }
}
