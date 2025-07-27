import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musync_and/pages/download_page.dart';
import 'package:musync_and/services/databasehelper.dart';
import 'package:musync_and/services/fetch_songs.dart';
import 'package:http/http.dart' as http;
import 'package:musync_and/widgets/list_content.dart';
import 'package:musync_and/widgets/list_playlists.dart';
import 'package:musync_and/widgets/player.dart';
import 'package:musync_and/widgets/popup_add.dart';
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
  ValueNotifier<bool> toRandom = ValueNotifier(false);
  ValueNotifier<int> toLoop = ValueNotifier(0);
  ValueNotifier<double> bottomPosition = ValueNotifier(0);
  ValueNotifier<double> topPosition = ValueNotifier(-68);
  int abaSelect = 0;
  int idplAtual = -1;

  var modeAtual = ModeOrderEnum.dataZA;

  List<MediaItem> songsNow = [];
  List<MediaItem> songsPlaylist = [];

  void _toggleBottom() {
    bottomPosition.value = bottomPosition.value == 0 ? -100 : 0;
  }

  void _toggleTop() {
    topPosition.value = topPosition.value == 0 ? -68 : 0;
  }

  @override
  void initState() {
    super.initState();
    _savePreferences();
    _initFetchSongs();
    _loadLastUse();
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

  void _loadLastUse() {
    _loadPreferences();

    //widget.audioHandler.setShuffleModeEnabled();

    //widget.audioHandler.setLoopModeEnabled();
  }

  Widget pageSelect(int pageIndex) {
    switch (pageIndex) {
      case 0:
        songsPlaylist = MyAudioHandler.songsAll;
        return ListContent(
          audioHandler: widget.audioHandler,
          songsNow: songsNow,
          modeReorder: modeAtual,
          aposClique: (item) async {
            if (_searchController.text == '') {
              await widget.audioHandler.recreateQueue(songs: songsNow);
            }
            int indiceCerto = MyAudioHandler.songsAll.indexWhere(
              (t) => t == item,
            );
            await widget.audioHandler.skipToQueueItem(indiceCerto);
          },
        );
      case 1:
        return ListPlaylist(
          escolhaDePlaylist: (pl) async {
            abaSelect = 2;
            modeAtual = modeAtual.convert(pl.orderMode);
            final newsongs = await pl.findMusics();
            if (newsongs != null) {
              setState(() {
                songsPlaylist = newsongs;
                songsPlaylist = MyAudioHandler.reorder(
                  modeAtual,
                  songsPlaylist,
                );
                songsNow = songsPlaylist;
              });
            }
          },
          escolhaDeArtista: (art) {
            log(art);
            abaSelect = 2;
            final newsongs =
                MyAudioHandler.songsAll
                    .where((item) => item.artist == art)
                    .toList();
            setState(() {
              songsPlaylist = newsongs;
              songsPlaylist = MyAudioHandler.reorder(modeAtual, songsPlaylist);
              songsNow = songsPlaylist;
            });
          },
        );

      case 2:
        return ListContent(
          audioHandler: widget.audioHandler,
          songsNow: songsNow,
          modeReorder: modeAtual,
          aposClique: (item) async {
            if (_searchController.text == '') {
              await widget.audioHandler.recreateQueue(songs: songsNow);
            }
            int indiceCerto = songsPlaylist.indexWhere((t) => t == item);
            await widget.audioHandler.skipToQueueItem(indiceCerto);
          },
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DownloadPage(),
                  settings: RouteSettings(name: 'donwload'),
                ),
              );
            },
            child: Icon(Icons.download),
          ),
          SizedBox(width: 9),
          ElevatedButton(
            onPressed: () {
              modeAtual = modeAtual.next();
              setState(() {
                MyAudioHandler.songsAll = MyAudioHandler.reorder(
                  modeAtual,
                  MyAudioHandler.songsAll,
                );
                songsNow = MyAudioHandler.songsAll;
              });
              log('$abaSelect $idplAtual');
              if (abaSelect == 2 && idplAtual != -1) {
                //saveOrder();
              }
            },
            child: Icon(Icons.reorder_outlined),
          ),
          SizedBox(width: 9),
          ElevatedButton(onPressed: () {}, child: Icon(Icons.settings)),
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
                                    songsPlaylist
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

  @override
  void dispose() {
    widget.audioHandler.stop();
    super.dispose();
  }
}
