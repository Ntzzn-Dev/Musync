import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musync_and/services/actionlist.dart';
import 'package:musync_and/services/audio_player.dart';
import 'package:musync_and/services/audio_player_organize.dart';
import 'package:musync_and/services/databasehelper.dart';
import 'package:musync_and/services/ekosystem.dart';
import 'package:musync_and/services/playlists.dart';
import 'package:musync_and/services/setlist.dart';
import 'package:musync_and/themes.dart';
import 'package:musync_and/widgets/list_content.dart';
import 'package:musync_and/widgets/menu_helper.dart';
import 'package:musync_and/widgets/player.dart';
import 'package:musync_and/widgets/popup_add.dart';

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
    modeAtual = enumFromInt(widget.pl?.orderMode ?? 4, ModeOrderEnum.values);

    playlistUpdateNotifier.addListener(_onPlaylistChanged);

    MusyncAudioHandler.actlist.setSetList(
      SetListType.view,
      Setlist(
        title: widget.pl?.title ?? widget.plTitle.replaceAll('/', ''),
        subtitle: widget.pl?.subtitle ?? '',
        tag: widget.pl?.id.toString() ?? widget.plTitle,
      ),
    );
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

  void reorderPlaylist(ModeOrderEnum mode) async {
    final novaLista = await reorderMusics(mode, songsNowTranslated);

    setState(() {
      modeAtual = mode;
      songsPlaylist = novaLista;
    });

    if (widget.pl != null) {
      DatabaseHelper().updatePlaylist(
        widget.pl!.id,
        orderMode: enumToInt(mode),
      );
    }
  }

  Future<void> deletarMusicas(List<MediaItem> itens) async {
    for (MediaItem item in itens) {
      final file = File(item.extras?['path']);
      if (await file.exists()) {
        try {
          setState(() {
            songsNowTranslated.remove(item);
            MusyncAudioHandler.actlist.songsAll.remove(item);
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
      funcSuperior.value = PopupMenuButton<String>(
        icon: Icon(Icons.queue_music_rounded),
        onSelected: (value) async {
          switch (value) {
            case 'addtoplaylist':
              if (await selectPlaylistMenu(context, idsMscs)) {
                completer.complete(true);
              }
              break;
            case 'delete': //Consertar esse delete esta apagando, mas altera a musica atual, e trava quando tento reproduzir, não altera quando tem apenas uma selecionada, provavelmente ao apagar uma pula para a seguinte
              if (await showPopupAdd(
                context,
                'Deletar musicas selecionadas?',
                [],
              )) {
                await deletarMusicas(
                  indexMsc.map((i) => songsNowTranslated[i]).toList(),
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
            menuChildren: reorderMenu(
              modeAtual: modeAtual,
              context: context,
              onChange: reorderPlaylist,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              searchMenu(
                context,
                _searchController,
                onChanged: (value) {
                  setState(() {
                    songsPlaylist =
                        songsNowTranslated
                            .where(
                              (item) => item.title.toLowerCase().contains(
                                value.toLowerCase(),
                              ),
                            )
                            .toList();
                  });
                },
                onClear: () {
                  FocusScope.of(context).requestFocus(FocusNode());

                  _searchController.clear();

                  setState(() {
                    songsPlaylist = [...songsNowTranslated];
                  });
                },
              ),
              Expanded(
                child: ListContent(
                  audioHandler: widget.audioHandler,
                  songsNow: songsPlaylist,
                  modeReorder: modeAtual,
                  idPlaylist:
                      widget.pl?.id.toString() ??
                      MusyncAudioHandler.actlist.mainPlaylist.tag,
                  withReorder: true,
                  aposClique: (item) async {
                    bool recriou = await widget.audioHandler.recreateQueue(
                      songs: songsNowTranslated,
                    );

                    widget.audioHandler.savePl(
                      Setlist(
                        title: widget.pl?.title ?? widget.plTitle,
                        subtitle: widget.pl?.subtitle ?? '',
                        tag: (widget.pl?.id ?? widget.plTitle).toString(),
                      ),
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
                      child: Player(audioHandler: widget.audioHandler),
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
