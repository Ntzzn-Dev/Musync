import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musync_and/services/databasehelper.dart';
import 'package:musync_and/services/fetch_songs.dart';
import 'package:http/http.dart' as http;
import 'package:musync_and/services/playlists.dart';
import 'package:musync_and/widgets/letreiro.dart';
import 'package:musync_and/widgets/popup.dart';
import 'package:musync_and/widgets/popup_add.dart';
import 'package:musync_and/widgets/popup_list.dart';
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
  ValueNotifier<int> currentPlayingIndex = ValueNotifier(0);
  double bottomPosition = 0;
  int abaSelect = 0;
  int idPlaylistAtual = -1;

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

  Future<void> reorder(ModeOrderEnum modeAtual, {bool? reordenarFila}) async {
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

    if (reordenarFila != null && reordenarFila) {
      await widget.audioHandler.recreateQueue(songs: songsNow);
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
        {'valor1': 'Duracao', 'valor2': formatDuration(item.duration!, true)},
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

  String formatDuration(Duration d, bool h) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '${h ? '$hours:' : ''}$minutes:$seconds';
  }

  Widget titleText(String text, double fontsize) {
    return Letreiro(
      key: ValueKey(text),
      texto: text,
      blankSpace: 90,
      fullTime: 12,
      timeStoped: 1500,
      fontSize: fontsize,
    );
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
            content(Stream.value(songsNow)), //widget.audioHandler.queue),
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
                    int typeReorder = 1;
                    switch (valores[2]) {
                      case 'Titulo A-Z':
                        typeReorder = 1;
                        break;
                      case 'Titulo Z-A':
                        typeReorder = 2;
                        break;
                      case 'Data A-Z':
                        typeReorder = 3;
                        break;
                      case 'Data Z-A':
                        typeReorder = 4;
                        break;
                      default:
                    }

                    DatabaseHelper().insertPlaylist(
                      valores[0],
                      valores[1],
                      1,
                      typeReorder,
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
                              'opt': 'id',
                              'funct': () async {
                                log(item.id.toString());
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
                                  fieldValues: [item.title, item.subtitle],
                                  onConfirm: (valores) async {
                                    int typeReorder = 1;
                                    switch (valores[2]) {
                                      case 'Titulo A-Z':
                                        typeReorder = 1;
                                        break;
                                      case 'Titulo Z-A':
                                        typeReorder = 2;
                                        break;
                                      case 'Data A-Z':
                                        typeReorder = 3;
                                        break;
                                      case 'Data Z-A':
                                        typeReorder = 4;
                                        break;
                                      default:
                                    }

                                    await DatabaseHelper().updatePlaylist(
                                      item.id,
                                      title: valores[0],
                                      subtitle: valores[1],
                                      orderMode: typeReorder,
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
                      reorder(modeAtual, reordenarFila: false);
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
    return Expanded(
      child: StreamBuilder<List<MediaItem>>(
        stream: medias,
        builder: (context, snapshot) {
          final mediaItems = snapshot.data ?? [];

          return ListView.builder(
            itemCount: mediaItems.length,
            itemBuilder: (context, index) {
              final item = mediaItems[index];

              return ValueListenableBuilder<int>(
                valueListenable: currentPlayingIndex,
                builder: (context, value, child) {
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
                        value == index
                            ? const Color.fromARGB(51, 243, 160, 34)
                            : null,
                    onTap: () async {
                      try {
                        if (abaSelect == 2) {
                          await widget.audioHandler.recreateQueue(
                            songs: songsNow,
                          );
                        }
                        if (abaSelect == 0) {
                          await widget.audioHandler.recreateQueue(
                            songs: songsAll,
                          );
                        }
                        await widget.audioHandler.skipToQueueItem(index);
                        setState(() {
                          currentPlayingIndex.value = index;
                        });
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
              await reorder(modeAtual, reordenarFila: false);
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
              child: Card(
                margin: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Color.fromARGB(255, 255, 255, 255),
                surfaceTintColor: Colors.transparent,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 20,
                  ),
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
                                titleText(mediaItem.title, 16),
                                titleText(mediaItem.artist ?? '', 11),
                              ],
                            ),
                          );
                        },
                      ),
                      StreamBuilder<Duration>(
                        stream: widget.audioHandler.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          final total =
                              widget.audioHandler.duration ?? Duration.zero;

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
                                      widget.audioHandler.seek(
                                        Duration(milliseconds: value.toInt()),
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
                                    Text(formatDuration(position, false)),
                                    Text(formatDuration(total, false)),
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
                          ValueListenableBuilder<bool>(
                            valueListenable: toRandom,
                            builder: (context, value, child) {
                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.all(15),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: const CircleBorder(),
                                ),
                                onPressed: () async {
                                  final newValue = !value;
                                  await widget.audioHandler
                                      .setShuffleModeEnabled(newValue);
                                  toRandom.value = newValue;
                                },
                                child: Icon(
                                  value
                                      ? Icons.shuffle
                                      : Icons.arrow_right_alt_rounded,
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
                              currentPlayingIndex.value =
                                  widget.audioHandler.currentIndex!;
                            },
                            child: Icon(Icons.keyboard_double_arrow_left_sharp),
                          ),
                          const SizedBox(width: 16),
                          StreamBuilder<bool>(
                            stream: widget.audioHandler.playingStream,
                            builder: (context, snapshot) {
                              final isPlaying = snapshot.data ?? false;
                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.all(15),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: const CircleBorder(),
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
                              await widget.audioHandler.skipToNext();
                              currentPlayingIndex.value =
                                  widget.audioHandler.currentIndex!;
                            },
                            child: Icon(
                              Icons.keyboard_double_arrow_right_sharp,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ValueListenableBuilder<int>(
                            valueListenable: toLoop,
                            builder: (context, value, child) {
                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.all(15),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: const CircleBorder(),
                                ),
                                onPressed: () async {
                                  LoopMode newloop = LoopMode.off;
                                  final newValue = value == 2 ? 0 : value + 1;
                                  switch (value) {
                                    case 0:
                                      newloop = LoopMode.all;
                                      break;
                                    case 1:
                                      newloop = LoopMode.one;
                                      break;
                                    case 2:
                                      newloop = LoopMode.off;
                                      break;
                                  }
                                  await widget.audioHandler.setLoopModeEnabled(
                                    newloop,
                                  );
                                  toLoop.value = newValue;
                                },
                                child: Icon(
                                  value == 0
                                      ? Icons.arrow_right_alt_rounded
                                      : value == 1
                                      ? Icons.repeat_rounded
                                      : Icons.repeat_one_rounded,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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
