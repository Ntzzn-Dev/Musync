import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musync_and/pages/playlist_page.dart';
import 'package:musync_and/services/actionlist.dart';
import 'package:musync_and/helpers/audio_player_helper.dart';
import 'package:musync_and/helpers/database_helper.dart';
import 'package:musync_and/services/ekosystem.dart';
import 'package:musync_and/services/fetch_songs.dart';
import 'package:musync_and/services/playlists.dart';
import 'package:musync_and/helpers/qrcode_helper.dart';
import 'package:musync_and/themes.dart';
import 'package:musync_and/widgets/list_content.dart';
import 'package:musync_and/widgets/list_playlists.dart';
import 'package:musync_and/helpers/menu_helper.dart';
import 'package:musync_and/widgets/player.dart';
import 'package:musync_and/widgets/popup_add.dart';
import 'package:musync_and/widgets/vertical_popup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_service/audio_service.dart';
import 'package:diacritic/diacritic.dart';
import 'package:musync_and/helpers/enum_helpers.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  ValueNotifier<bool> toDown = ValueNotifier(false);
  ValueNotifier<double> topPosition = ValueNotifier(-68);
  int abaSelect = 0;
  ValueNotifier<List<Widget>> funcSuperiores = ValueNotifier([]);

  var modeAtual = ModeOrderEnum.dataZA;
  final menuController = MenuController();
  double bottomInset = 0;

  List<MediaItem> songsNow = [];

  @override
  void initState() {
    super.initState();
    ListPlaylist.getMainPlaylist().then((value) {
      setState(() {
        mscAudPl.actlist.setSetList(
          SetListType.main,
          SetList(title: value.replaceAll('/', ''), tag: value),
        );
      });
    });
    _initFetchSongs();
    funcSuperiores.value = [lastOrCheck()];

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    mscAudPl.stop();
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !eko.conected.value) {
      connectToDesktop(context);
    }
  }

  void _toggleBottom() {
    toDown.value = !toDown.value;
  }

  void _toggleTop() {
    topPosition.value = topPosition.value == 0 ? -68 : 0;
  }

  Future<void> _initFetchSongs() async {
    final fetchedSongs = await FetchSongs.execute();

    final reordered = await reorderMusics(modeAtual, fetchedSongs);

    mscAudPl.actlist.songsAll = reordered;

    await loadSongsNow();

    mscAudPl.initSongs(songs: songsNow);
  }

  Future<void> loadSongsNow() async {
    await mscAudPl.searchPlaylists();
    int idpl = int.tryParse(mscAudPl.actlist.mainPlaylist.tag) ?? -1;
    if (idpl != -1) {
      final pl = await DatabaseHelper.instance.loadPlaylist(idpl);
      if (pl != null) {
        final newsongs = await pl.findMusics();
        if (newsongs.isNotEmpty) {
          songsNow = newsongs;
          mscAudPl.actlist.setSetList(
            SetListType.main,
            SetList(
              title: pl.title,
              subtitle: pl.subtitle,
              tag: pl.id.toString(),
            ),
          );
        }
      }
    } else if (mscAudPl.actlist.mainPlaylist.tag.contains('/')) {
      if (mscAudPl.actlist.mainPlaylist.tag == '/Todas') {
        songsNow = mscAudPl.actlist.songsAll;
      } else {
        final newsongs =
            mscAudPl.actlist.songsAll.where((item) {
              final songFolders = ListPlaylist.getFolderName(
                item.extras?['path'],
              );

              return songFolders == mscAudPl.actlist.mainPlaylist.tag;
            }).toList();

        songsNow = newsongs;
      }
    } else {
      final artistList =
          mscAudPl.actlist.mainPlaylist.tag
              .split(',')
              .map((a) => a.trim().toLowerCase())
              .toList();

      final newsongs =
          mscAudPl.actlist.songsAll.where((item) {
            final songArtists =
                (item.artist ?? '')
                    .split(',')
                    .map((a) => a.trim().toLowerCase())
                    .toList();

            return artistList.every((artist) => songArtists.contains(artist));
          }).toList();

      songsNow = newsongs;
    }
    setState(() {
      mscAudPl.actlist.songsAllPlaylist = songsNow;
    });

    mscAudPl.actlist.setSetList(
      SetListType.view,
      mscAudPl.actlist.mainPlaylist,
    );
  }

  void switchOrder(ModeOrderEnum mode) async {
    modeAtual = mode;
    mscAudPl.actlist.songsAllPlaylist = await reorderMusics(
      modeAtual,
      mscAudPl.actlist.songsAllPlaylist,
    );
    setState(() {
      songsNow = mscAudPl.actlist.songsAllPlaylist;
    });
  }

  Future<void> _loadCheckpoint() async {
    loadAnyPlaylist(
      ultimaMusica: mscAudPl.checkpoint.idMusic,
      ultimaPlaylist: mscAudPl.checkpoint.idSetList,
    );
  }

  Future<void> _loadLastPlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    final ultimaPlaylist = prefs.getString('pl_last');
    final ultimaMusica = prefs.getInt('msc_last') ?? 0;

    if (ultimaPlaylist == null) return;

    mscAudPl.checkpoint.setNewLast(
      idMusic: ultimaMusica,
      idSetList: ultimaPlaylist,
    );

    funcSuperiores.value = [lastOrCheck()];

    loadAnyPlaylist(ultimaMusica: ultimaMusica, ultimaPlaylist: ultimaPlaylist);
  }

  Widget lastOrCheck() {
    final empty = mscAudPl.checkpoint.isEmpty;

    return ElevatedButton(
      onPressed: empty ? _loadLastPlaylist : _loadCheckpoint,
      child: Icon(
        empty ? Icons.play_arrow_outlined : Icons.track_changes_outlined,
      ),
    );
  }

  Widget pageSelect(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return ListContent(
          songsNow: songsNow,
          modeReorder: modeAtual,
          idPlaylist: mscAudPl.actlist.mainPlaylist.tag.toString(),
          aposClique: (item) async {
            await mscAudPl.recreateQueue(
              songs: mscAudPl.actlist.songsAllPlaylist,
            );
            mscAudPl.savePl(mscAudPl.actlist.mainPlaylist);
            int indiceCerto = mscAudPl.actlist.songsAllPlaylist.indexWhere(
              (t) => t == item,
            );

            await mscAudPl.skipToQueueItem(indiceCerto);
          },
          selecaoDeMusicas: (indexMsc) async {
            return await moreOptionsSelected(indexMsc);
          },
        );
      case 1:
        funcSuperiores.value = [lastOrCheck()];
        return ListPlaylist(
          searchController: _searchController,
          escolhaDePlaylist: (pl) async {
            final newsongs = await pl.findMusics();
            if (newsongs.isNotEmpty) {
              _abrirPlaylist(title: pl.title, songs: newsongs, idPl: pl.id);
            }
          },
          escolhaDeArtista: (art) {
            final artistList =
                art.split(',').map((a) => a.trim().toLowerCase()).toList();

            final newsongs =
                mscAudPl.actlist.songsAll.where((item) {
                  final songArtists =
                      (item.artist ?? '')
                          .split(',')
                          .map((a) => a.trim().toLowerCase())
                          .toList();

                  return artistList.every(
                    (artist) => songArtists.contains(artist),
                  );
                }).toList();

            _abrirPlaylist(title: art, songs: newsongs);
          },
          escolhaDePasta: (fold) {
            if (fold == '/Todas') {
              _abrirPlaylist(title: fold, songs: mscAudPl.actlist.songsAll);
              return;
            }
            final newsongs =
                mscAudPl.actlist.songsAll.where((item) {
                  final songFolders = ListPlaylist.getFolderName(
                    item.extras?['path'],
                  );

                  return songFolders == fold;
                }).toList();

            _abrirPlaylist(title: fold, songs: newsongs);
          },
          trocaDeMain: (newMain) {
            setState(() {
              mscAudPl.actlist.mainPlaylist.tag = newMain;
              mscAudPl.actlist.mainPlaylist.title = newMain.replaceAll('/', '');
              mscAudPl.actlist.setSetList(
                SetListType.view,
                mscAudPl.actlist.mainPlaylist,
              );
              loadSongsNow();
              modeAtual = ModeOrderEnum.dataZA;
            });
          },
        );
      default:
        return SizedBox.shrink();
    }
  }

  void _abrirPlaylist({
    required String title,
    required List<MediaItem> songs,
    int? idPl,
  }) async {
    List<MediaItem> songsPl = [...songs];
    Playlists? pl;
    if (idPl != null) {
      pl = await DatabaseHelper.instance.loadPlaylist(idPl);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PlaylistPage(plTitle: title, songsPL: songsPl, pl: pl),
        settings: const RouteSettings(name: 'playlistOpened'),
      ),
    ).then((_) {
      mscAudPl.actlist.setSetList(
        SetListType.view,
        mscAudPl.actlist.mainPlaylist,
      );
    });
  }

  Future<bool> moreOptionsSelected(List<int> indexMsc) async {
    final completer = Completer<bool>();
    if (indexMsc.isNotEmpty) {
      List<String> idsMscs = indexMsc.map((i) => songsNow[i].id).toList();

      funcSuperiores.value = [
        Text('${indexMsc.length} [✓]'),
        PopupMenuButton<String>(
          icon: Icon(Icons.queue_music_rounded),
          onSelected: (value) async {
            switch (value) {
              case 'addtoplaylist':
                if (await selectPlaylistMenu(context, idsMscs)) {
                  completer.complete(true);
                }
                break;
              case 'upall':
                upAll(
                  context,
                  idsMscs,
                  action: DatabaseHelper.instance.upInPlaylist,
                );
                completer.complete(true);
                break;
              case 'desupall':
                upAll(
                  context,
                  idsMscs,
                  action: DatabaseHelper.instance.desupInPlaylist,
                );
                completer.complete(true);
                break;
              case 'delete':
                if (await showPopupAdd(
                  context,
                  'Deletar musicas selecionadas?',
                  [],
                )) {
                  await deletarMusicas(
                    indexMsc.map((i) => songsNow[i]).toList(),
                    removeLists: (item) async {
                      setState(() {
                        songsNow.removeWhere((e) => e.id == item.id);
                        mscAudPl.actlist.songsAll.removeWhere(
                          (e) => e.id == item.id,
                        );
                        mscAudPl.actlist.songsAllPlaylist.removeWhere(
                          (e) => e.id == item.id,
                        );

                        if (mscAudPl.actlist.songsAllPlaylist.contains(item)) {
                          mscAudPl.actlist.songsAllPlaylist.remove(item);
                        }
                      });

                      await mscAudPl.recreateQueue(
                        songs: songsNow,
                      ); // tentar com o reorganize
                    },
                    aoFinal: () async => await loadSongsNow(),
                  );
                  completer.complete(true);
                }
                break;
            }
          },
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  value: 'addtoplaylist',
                  child: Text(
                    'Adicionar à Playlist',
                    style: TextStyle(
                      color:
                          Theme.of(
                            context,
                          ).extension<CustomColors>()!.textForce,
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'upall',
                  child: Text(
                    'Upar todas as musicas',
                    style: TextStyle(
                      color:
                          Theme.of(
                            context,
                          ).extension<CustomColors>()!.textForce,
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'desupall',
                  child: Text(
                    'Despar todas as musicas',
                    style: TextStyle(
                      color:
                          Theme.of(
                            context,
                          ).extension<CustomColors>()!.textForce,
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Apagar',
                    style: TextStyle(
                      color:
                          Theme.of(
                            context,
                          ).extension<CustomColors>()!.textForce,
                    ),
                  ),
                ),
              ],
        ),
      ];
    } else {
      funcSuperiores.value = [lastOrCheck()];
    }
    return completer.future;
  }

  Future<void> upAll(
    BuildContext context,
    List<String> idsMscs, {
    required Future<void> Function(String tag, String id, String title) action,
  }) async {
    for (String id in idsMscs) {
      final tag = mscAudPl.actlist.viewingPlaylist.tag;

      await action(tag, id, id);

      mscAudPl.actlist.songsAllPlaylist = await reorderMusics(
        ModeOrderEnum.up,
        songsNow,
      );

      setState(() {
        songsNow = mscAudPl.actlist.songsAllPlaylist;
        mscAudPl.reorganizeQueue(songs: songsNow);
      });
    }
  }

  void showVerticalPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return const VerticalPopupMenu();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MUSYNC',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            fontFamily: 'Titles',
          ),
        ),
        actions: [
          downloadVisualizerMenu(onFinalize: () => switchOrder(modeAtual)),
          ValueListenableBuilder<bool>(
            valueListenable: eko.conected,
            builder: (context, value, child) {
              if (value) {
                return Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        showVerticalPopup(context);
                      },
                      child: Icon(Icons.connected_tv),
                    ),
                    SizedBox(width: 9),
                  ],
                );
              }
              return SizedBox.shrink();
            },
          ),
          ValueListenableBuilder<List<Widget>>(
            valueListenable: funcSuperiores,
            builder: (context, value, child) {
              return Row(mainAxisSize: MainAxisSize.min, children: value);
            },
          ),
          SizedBox(width: 9),
          MenuAnchor(
            controller: menuController,
            builder: (context, controller, child) {
              return IconButton(
                icon: Icon(Icons.more_horiz),
                onPressed:
                    () =>
                        controller.isOpen
                            ? controller.close()
                            : controller.open(),
              );
            },
            menuChildren: routesMenu(
              context: context,
              modeAtual: modeAtual,
              onSwitchMode: switchOrder,
              onConnect: (context) => scanToConnect(context),
            ),
            child: Icon(Icons.more_horiz),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            abaSelect = 0;
                            songsNow = mscAudPl.actlist.songsAllPlaylist;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: baseFundoDark,
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
                            mscAudPl.actlist.mainPlaylist.title,
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
                            color: baseFundoDark,
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
                    Container(
                      height: double.infinity,
                      color: baseFundoDark,
                      child: InkWell(
                        onTap: _toggleTop,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(
                            Icons.search,
                            color: Color.fromARGB(255, 243, 160, 34),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: pageSelect(abaSelect)),
              Padding(padding: EdgeInsets.only(bottom: 52 + bottomInset)),
            ],
          ),
          ValueListenableBuilder(
            valueListenable: toDown,
            builder: (context, shouldGoDown, child) {
              bottomInset = MediaQuery.of(context).padding.bottom;
              return ValueListenableBuilder<bool>(
                valueListenable: eko.conected,
                builder: (context, conected, child) {
                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    bottom:
                        bottomInset -
                        (shouldGoDown ? (conected ? 142 : 102) : 0),
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _toggleBottom,
                      child: Player(),
                    ),
                  );
                },
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
                child: searchMenu(
                  context,
                  _searchController,
                  onChanged: (value) {
                    setState(() {
                      songsNow =
                          mscAudPl.actlist.songsAllPlaylist
                              .where(
                                (item) => removeDiacritics(
                                  item.title,
                                ).toLowerCase().contains(value.toLowerCase()),
                              )
                              .toList();
                    });
                  },
                  onClear: () {
                    FocusScope.of(context).requestFocus(FocusNode());

                    _searchController.clear();

                    setState(() {
                      songsNow = mscAudPl.actlist.songsAllPlaylist;
                    });
                    _toggleTop();
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
