import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:musync_and/pages/download_page.dart';
import 'package:musync_and/pages/playlist_page.dart';
import 'package:musync_and/pages/settings_page.dart';
import 'package:musync_and/services/audio_player_base.dart';
import 'package:musync_and/services/databasehelper.dart';
import 'package:musync_and/services/fetch_songs.dart';
import 'package:musync_and/services/playlists.dart';
import 'package:musync_and/themes.dart';
import 'package:musync_and/widgets/list_content.dart';
import 'package:musync_and/widgets/list_playlists.dart';
import 'package:musync_and/widgets/player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_service/audio_service.dart';

class MusicPage extends StatefulWidget {
  final MusyncAudioHandler audioHandler;

  const MusicPage({super.key, required this.audioHandler});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  final TextEditingController _searchController = TextEditingController();
  ValueNotifier<double> bottomPosition = ValueNotifier(0);
  ValueNotifier<double> topPosition = ValueNotifier(-68);
  int abaSelect = 0;
  ValueNotifier<List<Widget>> funcSuperiores = ValueNotifier([]);

  var modeAtual = ModeOrderEnum.dataZA;

  List<MediaItem> songsNow = [];

  @override
  void initState() {
    super.initState();
    _initFetchSongs();
    funcSuperiores.value = [
      ElevatedButton(
        onPressed: () {
          _loadLastPlaylist();
        },
        child: Icon(Icons.play_arrow_rounded),
      ),
    ];
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
      MusyncAudioHandler.songsAll = fetchedSongs;
      MusyncAudioHandler.songsAll = MusyncAudioHandler.reorder(
        modeAtual,
        MusyncAudioHandler.songsAll,
      );
      songsNow = MusyncAudioHandler.songsAll;
    });

    widget.audioHandler.initSongs(songs: songsNow);
  }

  Future<void> _loadLastPlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    final ultimaPlaylist = prefs.getString('pl_last');
    final ultimaMusica = prefs.getInt('msc_last');

    log(ultimaPlaylist ?? 'vv');
    log(ultimaMusica.toString());

    if (ultimaPlaylist == null) return;

    List<MediaItem> newsongs = [];

    final id = int.tryParse(ultimaPlaylist);

    if (id != null) {
      final pl = await DatabaseHelper().loadPlaylist(id);
      newsongs = await pl?.findMusics() ?? [];
    } else if (ultimaPlaylist == 'Todas') {
      newsongs = MusyncAudioHandler.songsAll;
    } else {
      newsongs =
          MusyncAudioHandler.songsAll
              .where(
                (item) =>
                    (item.artist ?? '').trim().contains(ultimaPlaylist.trim()),
              )
              .toList();
    }

    await widget.audioHandler.recreateQueue(songs: newsongs);
    await widget.audioHandler.skipToQueueItem(ultimaMusica ?? 0);
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
              songs: MusyncAudioHandler.songsAll,
            );
            widget.audioHandler.savePl('Todas');
            int indiceCerto = MusyncAudioHandler.songsAll.indexWhere(
              (t) => t == item,
            );
            await widget.audioHandler.skipToQueueItem(indiceCerto);
          },
          selecaoDeMusicas: (indexMsc) {
            moreOptionsSelected(indexMsc);
          },
        );
      case 1:
        funcSuperiores.value = [
          ElevatedButton(
            onPressed: () {
              _loadLastPlaylist();
            },
            child: Icon(Icons.play_arrow_rounded),
          ),
        ];
        return ListPlaylist(
          searchController: _searchController,
          escolhaDePlaylist: (pl) async {
            final newsongs = await pl.findMusics();
            if (newsongs != null) {
              _abrirPlaylist(title: pl.title, songs: newsongs, idPl: pl.id);
            }
          },
          escolhaDeArtista: (art) {
            final artistList =
                art.split(',').map((a) => a.trim().toLowerCase()).toList();

            final newsongs =
                MusyncAudioHandler.songsAll.where((item) {
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
        );
      default:
        return SizedBox.shrink();
    }
  }

  void deletarMusicas(List<MediaItem> itens) async {
    for (MediaItem item in itens) {
      final file = File(item.extras?['path']);
      if (await file.exists()) {
        try {
          setState(() {
            songsNow.remove(item);
            MusyncAudioHandler.songsAll.remove(item);
          });
          await widget.audioHandler.recreateQueue(songs: songsNow);
          await file.delete();
        } catch (e) {
          log('Erro ao deletar: $e');
        }
      } else {
        log('Arquivo não encontrado');
      }
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
      pl = await DatabaseHelper().loadPlaylist(idPl);

      songsPl = MusyncAudioHandler.reorder(
        ModeOrderEnumExt.convert(pl!.orderMode),
        songs,
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PlaylistPage(
              plTitle: title,
              audioHandler: widget.audioHandler,
              songsPL: songsPl,
              pl: pl,
            ),
        settings: const RouteSettings(name: 'playlistOpened'),
      ),
    );
  }

  void moreOptionsSelected(List<int> indexMsc) async {
    if (indexMsc.isNotEmpty) {
      List<String> idsMscs = indexMsc.map((i) => songsNow[i].id).toList();
      List<Playlists> playlists = await DatabaseHelper().loadPlaylists(
        idsMusic: idsMscs,
      );
      funcSuperiores.value = [
        PopupMenuButton<String>(
          icon: Icon(Icons.queue_music_rounded),
          onSelected: (value) {
            switch (value) {
              case 'addtoplaylist':
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) {
                    return StatefulBuilder(
                      builder: (context, setModalState) {
                        return FractionallySizedBox(
                          heightFactor: 0.45,
                          child: Container(
                            padding: const EdgeInsets.only(top: 20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            child: ListView.builder(
                              itemCount: playlists.length,
                              itemBuilder: (context, index) {
                                final playlist = playlists[index];
                                return SizedBox(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () async {
                                      for (String id in idsMscs) {
                                        if (playlist.haveMusic ?? false) {
                                          await DatabaseHelper()
                                              .removeFromPlaylist(
                                                playlist.id,
                                                id,
                                              );
                                        } else {
                                          await DatabaseHelper().addToPlaylist(
                                            playlist.id,
                                            id,
                                          );
                                        }
                                      }

                                      setModalState(() {
                                        playlists[index] = playlist.copyWith(
                                          haveMusic:
                                              !(playlist.haveMusic ?? false),
                                        );
                                      });

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${playlist.haveMusic ?? false ? 'Removido de' : 'Adicionado à'} playlist: ${playlist.title}',
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            playlist.title,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            softWrap: true,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            playlist.subtitle,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                            softWrap: true,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 3,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
                break;
              case 'delete':
                deletarMusicas(indexMsc.map((i) => songsNow[i]).toList());
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
      funcSuperiores.value = [
        ElevatedButton(
          onPressed: () {
            _loadLastPlaylist();
          },
          child: Icon(Icons.play_arrow_rounded),
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MUSYNC',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          ValueListenableBuilder<List<Widget>>(
            valueListenable: funcSuperiores,
            builder: (context, value, child) {
              return Row(mainAxisSize: MainAxisSize.min, children: value);
            },
          ),
          SizedBox(width: 9),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz),
            onSelected: (value) {
              switch (value) {
                case 'reord':
                  modeAtual = modeAtual.next();
                  setState(() {
                    MusyncAudioHandler.songsAll = MusyncAudioHandler.reorder(
                      modeAtual,
                      MusyncAudioHandler.songsAll,
                    );
                    songsNow = MusyncAudioHandler.songsAll;
                  });
                  break;
                case 'downl':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DownloadPage(),
                      settings: RouteSettings(name: 'donwload'),
                    ),
                  ).then((_) {
                    setState(() {
                      MusyncAudioHandler.songsAll = MusyncAudioHandler.reorder(
                        modeAtual,
                        MusyncAudioHandler.songsAll,
                      );
                      songsNow = MusyncAudioHandler.songsAll;
                    });
                  });
                  break;
                case 'config':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsPage(),
                      settings: RouteSettings(name: 'settings'),
                    ),
                  );
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'reord',
                    child: Text(
                      'Reordenar',
                      style: TextStyle(
                        color:
                            Theme.of(
                              context,
                            ).extension<CustomColors>()!.textForce,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'downl',
                    child: Text(
                      'Downloads',
                      style: TextStyle(
                        color:
                            Theme.of(
                              context,
                            ).extension<CustomColors>()!.textForce,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'config',
                    child: Text(
                      'Configurações',
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
                        songsNow = MusyncAudioHandler.songsAll;
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
                                songsNow =
                                    MusyncAudioHandler.songsAll
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
                              songsNow = MusyncAudioHandler.songsAll;
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
