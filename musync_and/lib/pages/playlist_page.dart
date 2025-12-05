import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musync_and/services/audio_player_base.dart';
import 'package:musync_and/services/databasehelper.dart';
import 'package:musync_and/services/ekosystem.dart';
import 'package:musync_and/services/playlists.dart';
import 'package:musync_and/themes.dart';
import 'package:musync_and/widgets/list_content.dart';
import 'package:musync_and/widgets/player.dart';
import 'package:musync_and/widgets/player_eko.dart';

class PlaylistPage extends StatefulWidget {
  final String plTitle;
  final MusyncAudioHandler audioHandler;
  final List<MediaItem> songsPL;
  final Playlists? pl;
  final Ekosystem? ekosystem;
  const PlaylistPage({
    super.key,
    required this.plTitle,
    required this.audioHandler,
    required this.songsPL,
    this.pl,
    this.ekosystem,
  });

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  ValueNotifier<bool> toDown = ValueNotifier(false);
  ValueNotifier<Widget> funcSuperior = ValueNotifier(SizedBox.shrink());
  final TextEditingController _searchController = TextEditingController();
  late List<MediaItem> songsPlaylist;
  late List<MediaItem> songsNowTranslated;
  double bottomInset = 0;
  final menuController = MenuController();
  List<String> idsMsc = [];

  late ModeOrderEnum modeAtual;

  @override
  void initState() {
    super.initState();
    songsNowTranslated = [...widget.songsPL];
    songsPlaylist = [...songsNowTranslated];
    modeAtual = ModeOrderEnumExt.convert(widget.pl?.orderMode ?? 4);

    playlistUpdateNotifier.addListener(_onPlaylistChanged);
  }

  void _onPlaylistChanged() async {
    songsNowTranslated = await widget.pl?.findMusics() ?? songsNowTranslated;
    setState(() {
      songsPlaylist = [...songsNowTranslated];
    });
  }

  @override
  void dispose() {
    playlistUpdateNotifier.removeListener(_onPlaylistChanged);
    super.dispose();
  }

  void _toggleBottom() {
    toDown.value = !toDown.value;
  }

  void reorganizar() {
    setState(() {
      songsPlaylist = MusyncAudioHandler.reorder(modeAtual, songsNowTranslated);
    });
    if (widget.pl != null) {
      DatabaseHelper().updatePlaylist(
        widget.pl!.id,
        orderMode: modeAtual.disconvert(),
      );
      log(modeAtual.disconvert().toString());
    }
  }

  void deletarMusicas(List<MediaItem> itens) async {
    for (MediaItem item in itens) {
      final file = File(item.extras?['path']);
      if (await file.exists()) {
        try {
          setState(() {
            songsNowTranslated.remove(item);
            MusyncAudioHandler.songsAll.remove(item);
          });
          await widget.audioHandler.recreateQueue(songs: songsNowTranslated);
          await file.delete();
        } catch (e) {
          log('Erro ao deletar: $e');
        }
      } else {
        log('Arquivo não encontrado');
      }
    }
  }

  Future<bool> moreOptionsSelected(List<int> indexMsc) async {
    final completer = Completer<bool>();
    if (indexMsc.isNotEmpty) {
      List<String> idsMscs =
          indexMsc.map((i) => songsNowTranslated[i].id).toList();
      List<Playlists> playlists = await DatabaseHelper().loadPlaylists(
        idsMusic: idsMscs,
      );
      funcSuperior.value = PopupMenuButton<String>(
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

                                    ScaffoldMessenger.of(context).showSnackBar(
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
              deletarMusicas(
                indexMsc.map((i) => songsNowTranslated[i]).toList(),
              );
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
                        Theme.of(context).extension<CustomColors>()!.textForce,
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Apagar',
                  style: TextStyle(
                    color:
                        Theme.of(context).extension<CustomColors>()!.textForce,
                  ),
                ),
              ),
            ],
      );
    } else {
      funcSuperior.value = SizedBox.shrink();
    }
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.plTitle,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            widget.pl?.subtitle != '' && widget.pl?.subtitle != null
                ? Text(
                  widget.pl?.subtitle ?? '',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                )
                : SizedBox.shrink(),
          ],
        ),
        actions: [
          ValueListenableBuilder(
            valueListenable: funcSuperior,
            builder: (context, value, child) {
              return value;
            },
          ),
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
              MenuItemButton(
                style:
                    modeAtual == ModeOrderEnum.manual
                        ? ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(baseAppColor),
                        )
                        : null,
                child: Text(
                  'Manual',
                  style: TextStyle(
                    color:
                        Theme.of(context).extension<CustomColors>()!.textForce,
                  ),
                ),
                onPressed: () {
                  modeAtual = ModeOrderEnum.titleAZ;
                  reorganizar();
                },
              ),
              MenuItemButton(
                style:
                    modeAtual == ModeOrderEnum.titleAZ
                        ? ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(baseAppColor),
                        )
                        : null,
                child: Text(
                  'Titulo A - Z',
                  style: TextStyle(
                    color:
                        Theme.of(context).extension<CustomColors>()!.textForce,
                  ),
                ),
                onPressed: () {
                  modeAtual = ModeOrderEnum.titleAZ;
                  reorganizar();
                },
              ),
              MenuItemButton(
                style:
                    modeAtual == ModeOrderEnum.titleZA
                        ? ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(baseAppColor),
                        )
                        : null,
                child: Text(
                  'Titulo Z - A',
                  style: TextStyle(
                    color:
                        Theme.of(context).extension<CustomColors>()!.textForce,
                  ),
                ),
                onPressed: () {
                  modeAtual = ModeOrderEnum.titleZA;
                  reorganizar();
                },
              ),
              MenuItemButton(
                style:
                    modeAtual == ModeOrderEnum.dataAZ
                        ? ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(baseAppColor),
                        )
                        : null,
                child: Text(
                  'Data A - Z',
                  style: TextStyle(
                    color:
                        Theme.of(context).extension<CustomColors>()!.textForce,
                  ),
                ),
                onPressed: () {
                  modeAtual = ModeOrderEnum.dataAZ;
                  reorganizar();
                },
              ),
              MenuItemButton(
                style:
                    modeAtual == ModeOrderEnum.dataZA
                        ? ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(baseAppColor),
                        )
                        : null,
                child: Text(
                  'Data Z - A',
                  style: TextStyle(
                    color:
                        Theme.of(context).extension<CustomColors>()!.textForce,
                  ),
                ),
                onPressed: () {
                  modeAtual = ModeOrderEnum.dataZA;
                  reorganizar();
                },
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
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
                              songsPlaylist =
                                  songsNowTranslated
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
                          FocusScope.of(context).requestFocus(FocusNode());
                          _searchController.clear();
                          setState(() {
                            songsPlaylist = [...songsNowTranslated];
                          });
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
              Expanded(
                child: ListContent(
                  audioHandler: widget.audioHandler,
                  songsNow: songsPlaylist,
                  modeReorder: modeAtual,
                  idPlaylist: widget.pl?.id.toString() ?? MusyncAudioHandler.mainPlaylist['id'].toString(),
                  withReorder: true,
                  aposClique: (item) async {
                    bool recriou = await widget.audioHandler.recreateQueue(
                      songs: songsNowTranslated,
                    );
                    widget.audioHandler.savePl(
                      (widget.pl?.id ?? widget.plTitle).toString(),
                      subt: widget.pl?.subtitle ?? 'Artist',
                      title: widget.pl?.title,
                      id: widget.pl?.id.toString() ?? MusyncAudioHandler.mainPlaylist['id'].toString(),
                    );
                    int indiceCerto = songsNowTranslated.indexWhere(
                      (t) => t == item,
                    );
                    if ((widget.ekosystem?.conected.value ?? false) &&
                        recriou) {
                      Ekosystem.indexInitial = indiceCerto;
                    }
                    await widget.audioHandler.skipToQueueItem(indiceCerto);
                  },
                  selecaoDeMusicas: (indexMsc) async {
                    return await moreOptionsSelected(indexMsc);
                  },
                ),
              ),
              Padding(padding: EdgeInsets.only(bottom: 52 + bottomInset)),
            ],
          ),

          ValueListenableBuilder(
            valueListenable: toDown,
            builder: (context, value, child) {
              bottomInset = MediaQuery.of(context).padding.bottom;
              return ValueListenableBuilder<bool>(
                valueListenable:
                    widget.ekosystem?.conected ?? ValueNotifier(false),
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
        ],
      ),
    );
  }
}
