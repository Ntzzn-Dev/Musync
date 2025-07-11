import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musync_and/services/databasehelper.dart';
import 'package:musync_and/services/fetch_songs.dart';
import 'package:http/http.dart' as http;
import 'package:musync_and/services/playlists.dart';
import 'package:musync_and/widgets/letreiro.dart';
import 'package:musync_and/widgets/player.dart';
import 'package:musync_and/widgets/popup.dart';
import 'package:musync_and/widgets/popup_add.dart';
import 'package:musync_and/widgets/popup_list.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_service/audio_service.dart';
import 'themes.dart';
import 'services/audio_player_base.dart';
import 'package:intl/intl.dart';

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
    log(modeAtual.toString());
    switch (modeAtual) {
      case ModeOrderEnum.titleAZ:
        log('veio2');
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

  void showSpec(MediaItem item) {
    showPopupList(
      context,
      item.title,
      [
        {'valor1': 'Nome', 'valor2': item.title},
        {'valor1': 'Album', 'valor2': item.album},
        {'valor1': 'Artista', 'valor2': item.artist},
        {
          'valor1': 'Duracao',
          'valor2': Player.formatDuration(item.duration!, true),
        },
        {'valor1': 'Caminho', 'valor2': item.extras?['path']},
        {
          'valor1': 'Data',
          'valor2': DateFormat(
            'HH:mm:ss dd/MM/yyyy',
          ).format(DateTime.parse(item.extras?['lastModified'])),
        },
      ],
      [
        {'name': 'Dado', 'flex': 1, 'centralize': true, 'bold': true},
        {'name': 'Valor', 'flex': 3, 'centralize': true, 'bold': false},
      ],
    );
  }

  Future<void> deletarMusica(MediaItem item) async {
    final file = File(item.extras?['path']);
    if (await file.exists()) {
      try {
        setState(() {
          songsNow.remove(item);
        });
        await widget.audioHandler.recreateQueue(songs: songsNow);
        //await file.delete(); ---------------------------------------------------------------------------------------------------> DEIXAR PARA RETIRAR QUANDO CONFIGURAÇÕES ESTIVER PRONTO
        log('Arquivo deletado: ${item.title}');
      } catch (e) {
        log('Erro ao deletar: $e');
      }
    } else {
      log('Arquivo não encontrado');
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

  List<Map<String, dynamic>> moreOptions(BuildContext context, MediaItem item) {
    return [
      {
        'opt': 'Apagar Audio',
        'funct': () {
          deletarMusica(item);
          Navigator.of(context).pop();
        },
      },
      {
        'opt': 'Informações',
        'funct': () {
          showSpec(item);
        },
      },
      {
        'opt': 'Adicionar a Playlist',
        'funct': () async {
          DatabaseHelper().addToPlaylist(
            1,
            await Playlists.generateHashs(item.extras?['path']),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adicionado a playlist: ')),
          );
        },
      },
    ];
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
            content(Stream.value(songsNow)),
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
                    title: Text(item.title),
                    subtitle: Text(item.subtitle),
                    trailing: SizedBox(
                      width: 52,
                      height: 52,
                      child: IconButton(
                        icon: const Icon(Icons.more_vert_rounded),
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
                    },
                  );
                },
              ),
            ),
          ],
        );
      case 2:
        return Column(children: [content(Stream.value(songsNow))]);
      default:
        return SizedBox.shrink();
    }
  }

  Widget content(Stream<List<MediaItem>> medias) {
    final ItemScrollController _itemScrollController = ItemScrollController();
    final ItemPositionsListener _itemPositionsListener =
        ItemPositionsListener.create();

    return Expanded(
      child: StreamBuilder<List<MediaItem>>(
        stream: medias,
        builder: (context, snapshot) {
          final mediaItems = snapshot.data ?? [];

          void _scrollToCenter(int index) {
            if (index >= 0 && index < mediaItems.length) {
              _itemScrollController.scrollTo(
                index: index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: 0.25,
              );
            }
          }

          return ValueListenableBuilder<int?>(
            valueListenable: widget.audioHandler.currentIndexNotifier,
            builder: (context, currentIndex, _) {
              if (currentIndex != null &&
                  currentIndex >= 0 &&
                  currentIndex < mediaItems.length) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToCenter(currentIndex);
                });
              }
              return ScrollablePositionedList.builder(
                itemCount: mediaItems.length,
                itemScrollController: _itemScrollController,
                itemPositionsListener: _itemPositionsListener,
                itemBuilder: (context, index) {
                  final item = mediaItems[index];
                  return ListTile(
                    contentPadding: EdgeInsets.only(left: 16, right: 8),
                    title: Text(item.title),
                    subtitle: Text(item.artist ?? "Artista desconhecido"),
                    trailing: SizedBox(
                      width: 52,
                      height: 52,
                      child: IconButton(
                        icon: const Icon(Icons.more_vert_rounded),
                        iconSize: 24,
                        padding: EdgeInsets.zero,
                        onPressed:
                            () => showPopup(
                              context,
                              item.title,
                              moreOptions(context, item),
                            ),
                      ),
                    ),
                    tileColor:
                        currentIndex == index
                            ? const Color.fromARGB(51, 243, 160, 34)
                            : null,
                    onTap: () async {
                      try {
                        await widget.audioHandler.recreateQueue(
                          songs: songsNow,
                        );
                        await widget.audioHandler.skipToQueueItem(index);
                      } catch (e) {
                        log('Erro ao tocar música: $e');
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
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
                        decoration:
                            abaSelect == 0
                                ? const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color.fromARGB(255, 243, 160, 34),
                                      width: 3,
                                    ),
                                  ),
                                )
                                : null,
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
                        decoration:
                            abaSelect == 1
                                ? const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color.fromARGB(255, 243, 160, 34),
                                      width: 3,
                                    ),
                                  ),
                                )
                                : null,
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
