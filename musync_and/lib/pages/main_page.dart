import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musync_and/pages/control_page.dart';
import 'package:musync_and/pages/download_page.dart';
import 'package:musync_and/pages/playlist_page.dart';
import 'package:musync_and/pages/settings_page.dart';
import 'package:musync_and/services/audio_player_base.dart';
import 'package:musync_and/services/databasehelper.dart';
import 'package:musync_and/services/download.dart';
import 'package:musync_and/services/ekosystem.dart';
import 'package:musync_and/services/fetch_songs.dart';
import 'package:musync_and/services/playlists.dart';
import 'package:musync_and/themes.dart';
import 'package:musync_and/widgets/list_content.dart';
import 'package:musync_and/widgets/list_playlists.dart';
import 'package:musync_and/widgets/player.dart';
import 'package:musync_and/widgets/player_eko.dart';
import 'package:musync_and/widgets/popup_add.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_service/audio_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:diacritic/diacritic.dart';

class MusicPage extends StatefulWidget {
  final MusyncAudioHandler audioHandler;

  const MusicPage({super.key, required this.audioHandler});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  final TextEditingController _searchController = TextEditingController();
  ValueNotifier<bool> toDown = ValueNotifier(false);
  ValueNotifier<double> topPosition = ValueNotifier(-68);
  int abaSelect = 0;
  ValueNotifier<List<Widget>> funcSuperiores = ValueNotifier([]);

  var modeAtual = ModeOrderEnum.dataZA;
  final menuController = MenuController();
  double bottomInset = 0;

  List<MediaItem> songsNow = [];

  Ekosystem? ekosystem;

  @override
  void initState() {
    super.initState();
    ListPlaylist.getMainPlaylist().then((value) {
      setState(() {
        MusyncAudioHandler.mainPlaylist.title = value.replaceAll('/', '');
        MusyncAudioHandler.mainPlaylist.tag = value;
      });
    });
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
    toDown.value = !toDown.value;
  }

  void _toggleTop() {
    topPosition.value = topPosition.value == 0 ? -68 : 0;
  }

  Future<void> _initFetchSongs() async {
    final fetchedSongs = await FetchSongs.execute();

    final reordered = await MusyncAudioHandler.reorder(modeAtual, fetchedSongs,);

    MusyncAudioHandler.songsAll = reordered;

    await loadSongsNow();

    widget.audioHandler.initSongs(songs: songsNow);
  }

  Future<void> loadSongsNow() async {
    print('metodo loadSongsNow');
    await widget.audioHandler.searchPlaylists();
    int idpl = int.tryParse(MusyncAudioHandler.mainPlaylist.tag) ?? -1;
    if (idpl != -1) {
      final pl = await DatabaseHelper().loadPlaylist(idpl);
      if (pl != null) {
        final newsongs = await pl.findMusics();
        if (newsongs.isNotEmpty) {
          songsNow = newsongs;
          MusyncAudioHandler.mainPlaylist.title = pl.title;
          MusyncAudioHandler.mainPlaylist.subtitle = pl.subtitle;
          MusyncAudioHandler.mainPlaylist.tag = pl.id.toString();
        }
      }
    } else if (MusyncAudioHandler.mainPlaylist.tag.contains('/')) {
      if (MusyncAudioHandler.mainPlaylist.tag == '/Todas') {
        songsNow = MusyncAudioHandler.songsAll;
      } else {
        final newsongs =
            MusyncAudioHandler.songsAll.where((item) {
              final songFolders = ListPlaylist.getFolderName(
                item.extras?['path'],
              );

              return songFolders == MusyncAudioHandler.mainPlaylist.tag;
            }).toList();

        songsNow = newsongs;
      }
    } else {
      final artistList =
          MusyncAudioHandler.mainPlaylist.tag
              .split(',')
              .map((a) => a.trim().toLowerCase())
              .toList();

      final newsongs =
          MusyncAudioHandler.songsAll.where((item) {
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
      MusyncAudioHandler.songsAllPlaylist = songsNow;
    });

    widget.audioHandler.setViewPlaylist(MusyncAudioHandler.mainPlaylist.title,MusyncAudioHandler.mainPlaylist.subtitle,MusyncAudioHandler.mainPlaylist.tag);
  }

  void switchOrder(ModeOrderEnum mod) async {
    modeAtual = mod;
    MusyncAudioHandler.songsAllPlaylist = await MusyncAudioHandler.reorder(
      modeAtual,
      MusyncAudioHandler.songsAllPlaylist,
    );
    setState(() {
      songsNow = MusyncAudioHandler.songsAllPlaylist;
    });
  }

  Future<void> _loadLastPlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    final ultimaPlaylist = prefs.getString('pl_last');
    final ultimaMusica = prefs.getInt('msc_last');

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

  Future<String?> openQrScanner() async {
    String? codeFinal;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    MobileScanner(
                      onDetect: (capture) {
                        log('2');
                        final barcode = capture.barcodes.first;
                        final String? code = barcode.rawValue;

                        if (code != null) {
                          log('lido');
                          Navigator.pop(context);
                          codeFinal = code;
                        }
                      },
                    ),

                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    return codeFinal;
  }

  Widget pageSelect(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return ListContent(
          audioHandler: widget.audioHandler,
          songsNow: songsNow,
          modeReorder: modeAtual,
          idPlaylist: MusyncAudioHandler.mainPlaylist.tag.toString(),
          aposClique: (item) async {
            await widget.audioHandler.recreateQueue(
              songs: MusyncAudioHandler.songsAllPlaylist,
            );
            widget.audioHandler.savePl(
              MusyncAudioHandler.mainPlaylist.tag,
              subt: MusyncAudioHandler.mainPlaylist.subtitle,
              title: MusyncAudioHandler.mainPlaylist.title,
            );
            int indiceCerto = MusyncAudioHandler.songsAllPlaylist.indexWhere(
              (t) => t == item,
            );
            if (ekosystem?.conected.value ?? false) {
              Ekosystem.indexInitial = indiceCerto;
            }
            await widget.audioHandler.skipToQueueItem(indiceCerto);
          },
          selecaoDeMusicas: (indexMsc) async {
            return await moreOptionsSelected(indexMsc);
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
          audioHandler: widget.audioHandler,
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
          escolhaDePasta: (fold) {
            if (fold == '/Todas') {
              _abrirPlaylist(title: fold, songs: MusyncAudioHandler.songsAll);
              return;
            }
            final newsongs =
                MusyncAudioHandler.songsAll.where((item) {
                  final songFolders = ListPlaylist.getFolderName(
                    item.extras?['path'],
                  );

                  return songFolders == fold;
                }).toList();

            _abrirPlaylist(title: fold, songs: newsongs);
          },
          trocaDeMain: (newMain) {
            setState(() {
              MusyncAudioHandler.mainPlaylist.tag = newMain;
              MusyncAudioHandler.mainPlaylist.title = newMain.replaceAll(
                '/',
                '',
              );
              widget.audioHandler.alterSetList(MusyncAudioHandler.mainPlaylist);
              loadSongsNow();
              modeAtual = ModeOrderEnum.dataZA;
            });
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
            if (MusyncAudioHandler.songsAllPlaylist.contains(item)) {
              MusyncAudioHandler.songsAllPlaylist.remove(item);
            }
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
              ekosystem: ekosystem,
            ),
        settings: const RouteSettings(name: 'playlistOpened'),
      ),
    ).then((_) {
      widget.audioHandler.setViewPlaylist(MusyncAudioHandler.mainPlaylist.title,MusyncAudioHandler.mainPlaylist.subtitle,MusyncAudioHandler.mainPlaylist.tag);}
    );
  }

  Future<bool> moreOptionsSelected(List<int> indexMsc) async {
    final completer = Completer<bool>();
    if (indexMsc.isNotEmpty) {
      List<String> idsMscs = indexMsc.map((i) => songsNow[i].id).toList();
      List<Playlists> playlists = await DatabaseHelper().loadPlaylists(
        idsMusic: idsMscs,
      );
      funcSuperiores.value = [
        Text('${indexMsc.length} [✓]'),
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
                                return Container(
                                  color:
                                      playlist.haveMusic ?? false
                                          ? Color.fromARGB(255, 243, 160, 34)
                                          : null,
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
                ).then((_) {
                  completer.complete(true);
                });
                break;
              case 'delete':
                deletarMusicas(indexMsc.map((i) => songsNow[i]).toList());

                completer.complete(true);
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
    return completer.future;
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
          ValueListenableBuilder<int>(
            valueListenable: DownloadSpecs().isDownloading,
            builder: (context, value, child) {
              if (value == 1) {
                return ElevatedButton(
                  onPressed: () async {
                    if (await showPopupAdd(context, 'Fazendo Downloads', [])) {}
                  },
                  style: ButtonStyle(
                    shape: WidgetStateProperty.all(const CircleBorder()),
                    padding: WidgetStateProperty.all(const EdgeInsets.all(8)),
                    backgroundColor: WidgetStateProperty.all(
                      Theme.of(context).appBarTheme.foregroundColor,
                    ),
                    foregroundColor: WidgetStateProperty.all(
                      Theme.of(context).cardTheme.color,
                    ),
                    elevation: WidgetStateProperty.all(3),
                  ),
                  child: Icon(Icons.download_rounded),
                );
              }
              if (value == 2) {
                return ElevatedButton(
                  onPressed: () async {
                    if (await showPopupAdd(context, 'Finalizados', [])) {
                      DownloadSpecs().finish();
                      switchOrder(modeAtual);
                    }
                  },
                  style: ButtonStyle(
                    shape: WidgetStateProperty.all(const CircleBorder()),
                    padding: WidgetStateProperty.all(const EdgeInsets.all(8)),
                    backgroundColor: WidgetStateProperty.all(
                      Theme.of(context).appBarTheme.foregroundColor,
                    ),
                    foregroundColor: WidgetStateProperty.all(
                      Theme.of(context).cardTheme.color,
                    ),
                    elevation: WidgetStateProperty.all(3),
                  ),
                  child: Icon(Icons.download_done_rounded),
                );
              } else {
                return SizedBox.shrink();
              }
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: ekosystem?.conected ?? ValueNotifier(false),
            builder: (context, value, child) {
              if (value) {
                return Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        if (await showPopupAdd(
                          context,
                          'Deseja deconectar do desktop?',
                          [],
                        )) {
                          ekosystem?.tryToDisconect();
                        }
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
            menuChildren: [
              SubmenuButton(
                child: Text(
                  'Reordenar',
                  style: TextStyle(
                    color:
                        Theme.of(context).extension<CustomColors>()!.textForce,
                  ),
                ),
                menuChildren: [
                  MenuItemButton(
                    style:
                        modeAtual == ModeOrderEnum.titleAZ
                            ? ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                baseAppColor,
                              ),
                            )
                            : null,
                    child: Text(
                      'Titulo A - Z',
                      style: TextStyle(
                        color:
                            Theme.of(
                              context,
                            ).extension<CustomColors>()!.textForce,
                      ),
                    ),
                    onPressed: () {
                      switchOrder(ModeOrderEnum.titleAZ);
                    },
                  ),
                  MenuItemButton(
                    style:
                        modeAtual == ModeOrderEnum.titleZA
                            ? ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                baseAppColor,
                              ),
                            )
                            : null,
                    child: Text(
                      'Titulo Z - A',
                      style: TextStyle(
                        color:
                            Theme.of(
                              context,
                            ).extension<CustomColors>()!.textForce,
                      ),
                    ),
                    onPressed: () {
                      switchOrder(ModeOrderEnum.titleZA);
                    },
                  ),
                  MenuItemButton(
                    style:
                        modeAtual == ModeOrderEnum.dataAZ
                            ? ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                baseAppColor,
                              ),
                            )
                            : null,
                    child: Text(
                      'Data A - Z',
                      style: TextStyle(
                        color:
                            Theme.of(
                              context,
                            ).extension<CustomColors>()!.textForce,
                      ),
                    ),
                    onPressed: () {
                      switchOrder(ModeOrderEnum.dataAZ);
                    },
                  ),
                  MenuItemButton(
                    style:
                        modeAtual == ModeOrderEnum.dataZA
                            ? ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                baseAppColor,
                              ),
                            )
                            : null,
                    child: Text(
                      'Data Z - A',
                      style: TextStyle(
                        color:
                            Theme.of(
                              context,
                            ).extension<CustomColors>()!.textForce,
                      ),
                    ),
                    onPressed: () {
                      switchOrder(ModeOrderEnum.dataZA);
                    },
                  ),
                  MenuItemButton(
                    style:
                        modeAtual == ModeOrderEnum.up
                            ? ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                baseAppColor,
                              ),
                            )
                            : null,
                    child: Text(
                      'Up',
                      style: TextStyle(
                        color:
                            Theme.of(
                              context,
                            ).extension<CustomColors>()!.textForce,
                      ),
                    ),
                    onPressed: () async {
                      switchOrder(ModeOrderEnum.up);
                    },
                  ),
                ],
              ),
              MenuItemButton(
                child: Text(
                  'Download',
                  style: TextStyle(
                    color:
                        Theme.of(context).extension<CustomColors>()!.textForce,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DownloadPage(),
                      settings: RouteSettings(name: 'donwload'),
                    ),
                  ).then((_) {
                    setState(() {
                      /*MusyncAudioHandler.songsAll = MusyncAudioHandler.reorder(
                        modeAtual,
                        MusyncAudioHandler.songsAll,
                      );
                      songsNow = MusyncAudioHandler.songsAllPlaylist;*/
                    });
                  });
                },
              ),
              MenuItemButton(
                child: Text(
                  'Configurações',
                  style: TextStyle(
                    color:
                        Theme.of(context).extension<CustomColors>()!.textForce,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              SettingsPage(audioHandler: widget.audioHandler),
                      settings: RouteSettings(name: 'settings'),
                    ),
                  );
                },
              ),
              MenuItemButton(
                child: Text(
                  'SuperControl',
                  style: TextStyle(
                    color:
                        Theme.of(context).extension<CustomColors>()!.textForce,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              ControlPage(audioHandler: widget.audioHandler),
                      settings: RouteSettings(name: 'control'),
                    ),
                  ).then((_) {
                    SystemChrome.setEnabledSystemUIMode(
                      SystemUiMode.edgeToEdge,
                    );
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      SystemChrome.restoreSystemUIOverlays();
                    });
                  });
                },
              ),
              MenuItemButton(
                child: Text(
                  'Connect Desktop',
                  style: TextStyle(
                    color:
                        Theme.of(context).extension<CustomColors>()!.textForce,
                  ),
                ),
                onPressed: () async {
                  final host = await openQrScanner() ?? '';
                  if (host != '') {
                    final eko = await Ekosystem.create(host: host, porta: 8080);

                    setState(() {
                      ekosystem = eko;
                    });

                    if (ekosystem != null) {
                      widget.audioHandler.setEkosystem(ekosystem!);
                    }
                  }
                },
              ),
            ],
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
                            songsNow = MusyncAudioHandler.songsAllPlaylist;
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
                            MusyncAudioHandler.mainPlaylist.title,
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
            builder: (context, value, child) {
              bottomInset = MediaQuery.of(context).padding.bottom;
              return ValueListenableBuilder<bool>(
                valueListenable: ekosystem?.conected ?? ValueNotifier(false),
                builder: (context, conected, child) {
                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    bottom: bottomInset - (value ? (conected ? 160 : 102) : 0),
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _toggleBottom,
                      child:
                          conected
                              ? EkoPlayer(audioHandler: widget.audioHandler)
                              : Player(audioHandler: widget.audioHandler),
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
                                    MusyncAudioHandler.songsAllPlaylist
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
                        GestureDetector(
                          onTap: () {
                            FocusScope.of(context).requestFocus(FocusNode());

                            _searchController.clear();

                            setState(() {
                              songsNow = MusyncAudioHandler.songsAllPlaylist;
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
