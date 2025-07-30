import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:musync_and/pages/download_page.dart';
import 'package:musync_and/pages/playlist_page.dart';
import 'package:musync_and/services/databasehelper.dart';
import 'package:musync_and/services/fetch_songs.dart';
import 'package:musync_and/services/playlists.dart';
import 'package:musync_and/widgets/list_content.dart';
import 'package:musync_and/widgets/list_playlists.dart';
import 'package:musync_and/widgets/player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_service/audio_service.dart';
import 'themes.dart';
import 'services/audio_player_base.dart';

MyAudioHandler _audioHandler = MyAudioHandler();

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
  final TextEditingController _searchController = TextEditingController();
  ValueNotifier<double> bottomPosition = ValueNotifier(0);
  ValueNotifier<double> topPosition = ValueNotifier(-68);
  int abaSelect = 0;

  var modeAtual = ModeOrderEnum.dataZA;

  List<MediaItem> songsNow = [];

  @override
  void initState() {
    super.initState();
    _initFetchSongs();
  }

  @override
  void dispose() {
    widget.audioHandler.stop();
    super.dispose();
  }

  void _toggleBottom() {
    bottomPosition.value = bottomPosition.value == 0 ? -100 : 0;
  }

  void _toggleTop() {
    topPosition.value = topPosition.value == 0 ? -68 : 0;
  }

  Future<void> _initFetchSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final dirStrings = prefs.getStringList('directorys') ?? [];

    final fetchedSongs = await FetchSongs.execute(paths: dirStrings);

    setState(() {
      MyAudioHandler.songsAll = fetchedSongs;
      MyAudioHandler.songsAll = MyAudioHandler.reorder(
        modeAtual,
        MyAudioHandler.songsAll,
      );
      songsNow = MyAudioHandler.songsAll;
    });

    widget.audioHandler.initSongs(songs: songsNow);
  }

  /*Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    /*prefs.setBool('random_act', toRandom.value);
    prefs.setInt('loop_act', toLoop.value);*/
    prefs.setStringList('directorys', [
      '/storage/emulated/0/snaptube/download/SnapTube Audio',
    ]);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    //log((prefs.getBool('random_act') ?? false).toString());
    //log((prefs.getBool('loop_act') ?? 0).toString());

    //Recarrega ultima playlist
  }*/

  Future<void> _loadLastPlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    final ultimaPlaylist = prefs.getString('pl_last');
    final ultimaMusica = prefs.getInt('msc_last');

    log(ultimaPlaylist ?? 'vv');

    if (ultimaPlaylist == null) return;

    List<MediaItem> newsongs = [];

    final id = int.tryParse(ultimaPlaylist);

    if (id != null) {
      final pl = await DatabaseHelper().loadPlaylist(id);
      newsongs = await pl?.findMusics() ?? [];
    } else if (ultimaPlaylist == 'Todas') {
      newsongs = MyAudioHandler.songsAll;
    } else {
      newsongs =
          MyAudioHandler.songsAll
              .where(
                (item) =>
                    (item.artist ?? '').trim().contains(ultimaPlaylist.trim()),
              )
              .toList();
    }

    widget.audioHandler.recreateQueue(songs: newsongs);
    widget.audioHandler.skipToQueueItem(ultimaMusica ?? 0);
  }

  Widget pageSelect(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return ListContent(
          audioHandler: widget.audioHandler,
          songsNow: songsNow,
          modeReorder: modeAtual,
          aposClique: (item) async {
            await widget.audioHandler.recreateQueue(
              songs: MyAudioHandler.songsAll,
            );
            widget.audioHandler.savePl('Todas');
            int indiceCerto = MyAudioHandler.songsAll.indexWhere(
              (t) => t == item,
            );
            await widget.audioHandler.skipToQueueItem(indiceCerto);
          },
        );
      case 1:
        return ListPlaylist(
          escolhaDePlaylist: (pl) async {
            final newsongs = await pl.findMusics();
            if (newsongs != null) {
              _abrirPlaylist(title: pl.title, songs: newsongs, pl: pl);
            }
          },
          escolhaDeArtista: (art) {
            final newsongs =
                MyAudioHandler.songsAll
                    .where(
                      (item) => (item.artist ?? '').trim().contains(art.trim()),
                    )
                    .toList();

            _abrirPlaylist(title: art, songs: newsongs);
          },
        );
      default:
        return SizedBox.shrink();
    }
  }

  void _abrirPlaylist({
    required String title,
    required List<MediaItem> songs,
    Playlists? pl,
  }) {
    final reordered = MyAudioHandler.reorder(modeAtual, songs);
    setState(() {
      songsNow = reordered;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PlaylistPage(
              plTitle: title,
              audioHandler: widget.audioHandler,
              songsPL: reordered,
              pl: pl,
            ),
        settings: const RouteSettings(name: 'playlistOpened'),
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
            onPressed: () {
              _loadLastPlaylist();
            },
            child: Icon(Icons.play_arrow_rounded),
          ),
          SizedBox(width: 9),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz),
            onSelected: (value) {
              switch (value) {
                case 'reord':
                  modeAtual = modeAtual.next();
                  setState(() {
                    MyAudioHandler.songsAll = MyAudioHandler.reorder(
                      modeAtual,
                      MyAudioHandler.songsAll,
                    );
                    songsNow = MyAudioHandler.songsAll;
                  });
                  break;
                case 'downl':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DownloadPage(),
                      settings: RouteSettings(name: 'donwload'),
                    ),
                  );
                  break;
                case 'config':
                  log('configurações');
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'reord',
                    child: Text(
                      'Reordenar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'downl',
                    child: Text(
                      'Downloads',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'config',
                    child: Text(
                      'Configurações',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
          ),
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
                        songsNow = MyAudioHandler.songsAll;
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
                  IconButton(
                    onPressed: _toggleTop,
                    icon: Icon(Icons.search),
                    color: Color.fromARGB(255, 243, 160, 34),
                  ),
                ],
              ),
              Expanded(child: pageSelect(abaSelect)),
            ],
          ),
          ValueListenableBuilder(
            valueListenable: bottomPosition,
            builder: (context, value, child) {
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                bottom: value,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _toggleBottom,
                  child: Player(audioHandler: widget.audioHandler),
                ),
              );
            },
          ),
          ValueListenableBuilder(
            valueListenable: topPosition,
            builder: (context, value, child) {
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                top: value,
                left: 0,
                right: 0,
                child: Container(
                  color:
                      Theme.of(
                        context,
                      ).extension<CustomColors>()!.backgroundForce,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              labelText: 'Pesquisa',
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                songsNow =
                                    MyAudioHandler.songsAll
                                        .where(
                                          (item) => item.title
                                              .toLowerCase()
                                              .contains(value.toLowerCase()),
                                        )
                                        .toList();
                              });
                            },
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _searchController.text = '';

                            setState(() {
                              songsNow = MyAudioHandler.songsAll;
                            });
                            _toggleTop();
                          },
                          child: SizedBox(
                            width: 30,
                            child: Icon(
                              Icons.close,
                              color: Color.fromARGB(255, 243, 160, 34),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
