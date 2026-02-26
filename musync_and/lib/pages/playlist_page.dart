import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musync_and/helpers/enum_helpers.dart';
import 'package:musync_and/services/actionlist.dart';
import 'package:musync_and/helpers/audio_player_helper.dart';
import 'package:musync_and/helpers/database_helper.dart';
import 'package:musync_and/services/ekosystem.dart';
import 'package:musync_and/services/playlists.dart';
import 'package:musync_and/themes.dart';
import 'package:musync_and/widgets/list_content.dart';
import 'package:musync_and/helpers/menu_helper.dart';
import 'package:musync_and/widgets/player.dart';
import 'package:musync_and/widgets/popup_add.dart';

class PlaylistPage extends StatefulWidget {
  final String plTitle;
  final List<MediaItem> songsPL;
  final Playlists? pl;
  const PlaylistPage({
    super.key,
    required this.plTitle,
    required this.songsPL,
    this.pl,
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

    mscAudPl.actlist.setSetList(
      SetListType.view,
      SetList(
        title: widget.pl?.title ?? widget.plTitle.replaceAll('/', ''),
        subtitle: widget.pl?.subtitle ?? '',
        tag: widget.pl?.id.toString() ?? widget.plTitle,
      ),
    );

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
      DatabaseHelper.instance.updatePlaylist(
        widget.pl!.id,
        orderMode: enumToInt(mode),
      );
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
                  removeLists: (item) async {
                    setState(() {
                      songsNowTranslated.removeWhere((e) => e.id == item.id);
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
                      songs: songsNowTranslated,
                    ); // tentar com o reorganize
                  },
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
                  songsNow: songsPlaylist,
                  modeReorder: modeAtual,
                  idPlaylist:
                      widget.pl?.id.toString() ??
                      mscAudPl.actlist.mainPlaylist.tag,
                  withReorder: true,
                  showSlices: false,
                  aposClique: (item) async {
                    List<MediaItem> songsNowReordered = await reorderMusics(
                      modeAtual,
                      songsNowTranslated,
                    );

                    bool recriou = await mscAudPl.recreateQueue(
                      songs: songsNowReordered,
                    );

                    mscAudPl.savePl(
                      SetList(
                        title: widget.pl?.title ?? widget.plTitle,
                        subtitle: widget.pl?.subtitle ?? '',
                        tag: (widget.pl?.id ?? widget.plTitle).toString(),
                      ),
                    );
                    int indiceCerto = songsNowReordered.indexWhere(
                      (t) => t == item,
                    );
                    if ((eko.conected.value) && recriou) {
                      Ekosystem.indexInitial = indiceCerto;
                    }
                    await mscAudPl.skipToQueueItem(indiceCerto);
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
                valueListenable: eko.conected,
                builder: (context, conected, child) {
                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    bottom: bottomInset - (value ? (conected ? 160 : 102) : 0),
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
        ],
      ),
    );
  }
}
