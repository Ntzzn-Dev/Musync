import 'dart:developer';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:musync_and/helpers/enum_helpers.dart';
import 'package:musync_and/helpers/audio_player_helper.dart';
import 'package:musync_and/helpers/database_helper.dart';
import 'package:musync_and/services/playlists.dart';
import 'package:musync_and/themes.dart';
import 'package:musync_and/helpers/menu_helper.dart';
import 'package:musync_and/widgets/popup_option.dart';
import 'package:musync_and/widgets/popup_add.dart';
import 'package:musync_and/widgets/popup_list.dart';
import 'package:collection/collection.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';

class ListContent extends StatefulWidget {
  final List<MediaItem> songsNow;
  final ModeOrderEnum modeReorder;
  final String idPlaylist;
  final void Function(ModeOrderEnum) onModeChanged;
  final bool? showSlices;
  final bool? withReorder;
  final void Function(MediaItem)? onClick;
  final Future<bool> Function(List<int>)? onSelectMsc;
  final void Function()? onCheckedPoint;

  const ListContent({
    super.key,
    required this.songsNow,
    required this.modeReorder,
    required this.idPlaylist,
    required this.onModeChanged,
    this.showSlices,
    this.withReorder,
    this.onClick,
    this.onSelectMsc,
    this.onCheckedPoint,
  });

  @override
  State<ListContent> createState() => _ListContentState();
}

abstract class ListContentState extends State<ListContent> {
  void scrollToCurrentSong();
}

class _ListContentState extends ListContentState {
  late final ScrollController _scrollController;
  late final ItemScrollController _itemScrollController;
  late bool listaEmUso;
  late List<int> idsSelecoes;
  late ValueNotifier<List<bool>> musicasSelecionadas;

  late List<MediaItem> mutableSongs;
  late ModeOrderEnum mode;
  int? _lastScrolledIndex;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _itemScrollController = ItemScrollController();
    listaEmUso = const ListEquality().equals(
      widget.songsNow,
      mscAudPl.actlist.getMediaItemsFromQueue(),
    );
    idsSelecoes = [];
    mutableSongs = List.from(widget.songsNow);
    mode = widget.modeReorder;

    musicasSelecionadas = ValueNotifier(
      List.filled(mutableSongs.length, false),
    );
  }

  @override
  void didUpdateWidget(covariant ListContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.songsNow != widget.songsNow) {
      setState(() {
        mutableSongs = List.from(widget.songsNow);
        mode = widget.modeReorder;
        musicasSelecionadas.value = List.filled(mutableSongs.length, false);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<OptionItem> moreOptions(BuildContext context, MediaItem item) {
    return [
      OptionItem(
        actions: [
          OptionAction(
            label: 'Up',
            icon: Icons.favorite,
            funct: () async {
              await handlePlaylistAction(
                itemId: item.id,
                itemTitle: item.title,
                action: DatabaseHelper.instance.upInPlaylist,
              );
            },
          ),
          OptionAction(
            label: 'Check',
            icon: Icons.adjust,
            funct: () async {
              await handleCheckPointAction(itemId: mutableSongs.indexOf(item));
            },
          ),
          OptionAction(
            label: 'Desup',
            icon: Icons.heart_broken,
            funct: () async {
              await handlePlaylistAction(
                itemId: item.id,
                itemTitle: item.title,
                action: DatabaseHelper.instance.desupInPlaylist,
              );
            },
          ),
        ],
      ),
      OptionItem(
        actions: [
          OptionAction(
            label: 'Informações',
            icon: Icons.info_outline,
            funct: () => showSpec(item),
          ),
        ],
      ),
      OptionItem(
        actions: [
          OptionAction(
            label: 'Adicionar a Playlist',
            icon: Icons.playlist_add,
            funct: () => insertPlaylistMenu(context, [item.id]),
          ),
        ],
      ),
      OptionItem(
        actions: [
          OptionAction(
            label: 'Compartilhar',
            icon: Icons.share,
            funct: () async {
              final file = File(item.extras?['path']);

              if (await file.exists()) {
                await SharePlus.instance.share(
                  ShareParams(
                    text: item.title,
                    title: item.title,
                    files: [XFile(file.path)],
                  ),
                );
              } else {
                log('Arquivo não encontrado!');
              }
            },
          ),
        ],
      ),
      OptionItem(
        actions: [
          OptionAction(
            label: 'Editar Música',
            icon: Icons.edit,
            funct: () {
              showPopupAdd(
                context,
                item.title,
                [
                  ContentItem(value: 'Título', type: ContentTypeEnum.title),
                  ContentItem(value: 'Artista', type: ContentTypeEnum.text),
                  ContentItem(value: 'Album', type: ContentTypeEnum.text),
                  ContentItem(value: 'Gênero', type: ContentTypeEnum.text),
                ],
                fieldValues: [
                  item.title,
                  item.artist ?? '',
                  item.album ?? '',
                  item.genre ?? '',
                ],
                onConfirm: (valores) {
                  Playlists.editarTags(item.extras?['path'], {
                    'title': valores[0],
                    'trackArtist': valores[1],
                    'album': valores[2],
                    'genre': valores[3],
                  });

                  int indexSongAll = mscAudPl.actlist.songsAll.indexWhere(
                    (e) => e.id == item.id,
                  );

                  int indexSongNow = mutableSongs.indexWhere(
                    (e) => e.id == item.id,
                  );

                  if (indexSongAll != -1) {
                    final antigo = mscAudPl.actlist.songsAll[indexSongAll];

                    final musicEditada = antigo.copyWith(
                      title: valores[0],
                      artist: valores[1],
                      album: valores[2],
                      genre: valores[3],
                      extras: {
                        ...?antigo.extras,
                        'lastModified': antigo.extras?['lastModified'],
                        'path': antigo.extras?['path'],
                      },
                    );

                    mscAudPl.actlist.songsAll[indexSongAll] = musicEditada;
                    mutableSongs[indexSongNow] = musicEditada;

                    setState(() {});

                    Navigator.of(context).pop();
                  } else {
                    log('Item não encontrado na lista para edição.');
                  }
                },
              );
            },
          ),
        ],
      ),
      OptionItem(
        actions: [
          OptionAction(
            label: 'Apagar Audio',
            icon: Icons.delete_forever,
            funct: () async {
              if (await showPopupAdd(context, "Deletar Mídia?", [])) {
                deletarMusica(item);
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    ];
  }

  Future<void> handleCheckPointAction({required int itemId}) async {
    mscAudPl.checkpoint.setNewLast(
      idMusic: itemId,
      idSetList: mscAudPl.actlist.viewingPlaylist.tag,
    );

    widget.onCheckedPoint?.call();
  }

  Future<void> handlePlaylistAction({
    required String itemId,
    required String itemTitle,
    required Future<void> Function(String tag, String id, String title) action,
  }) async {
    final tag = mscAudPl.actlist.viewingPlaylist.tag;

    await action(tag, itemId, itemTitle);

    final reordered = await reorderMusics(ModeOrderEnum.up, mutableSongs);

    widget.onModeChanged(ModeOrderEnum.up);

    if (!mounted) return;

    setState(() {
      mscAudPl.reorganizeQueue(songs: reordered);
      log('${reordered.length} Reorganizou ${reordered.last.title}');
      mutableSongs = mscAudPl.actlist.getMediaItemsFromQueue();
    });
  }

  void showSpec(MediaItem item) {
    showPopupList(
      context,
      item.title,
      [
        InfoItem(info: 'Nome', value: item.title),
        InfoItem(info: 'Artista', value: item.artist ?? 'Artista desconhecido'),
        InfoItem(info: 'Album', value: item.album ?? 'Sem album'),
        InfoItem(info: 'Duração', value: formatDuration(item.duration!, true)),
        InfoItem(info: 'Caminho', value: item.extras?['path']),
        InfoItem(
          info: 'Data',
          value: DateFormat(
            'HH:mm:ss dd/MM/yyyy',
          ).format(DateTime.parse(item.extras?['lastModified'])),
        ),
      ],
      InfoLabelSpecs(
        info: InfoLabel(name: 'Dado', flex: 1, centralize: true, bold: true),
        value: InfoLabel(name: 'Valor', flex: 3, centralize: true, bold: false),
      ),
    );
  }

  Future<void> deletarMusica(MediaItem item) async {
    final file = File(item.extras?['path']);
    if (await file.exists()) {
      try {
        setState(() {
          mutableSongs.remove(item);
          mscAudPl.actlist.songsAll.remove(item);
        });
        await mscAudPl.recreateQueue(songs: mutableSongs);
        await file.delete();
      } catch (e) {
        log('Erro ao deletar: $e');
      }
    } else {
      log('Arquivo não encontrado');
    }
  }

  String getDateCategory(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inputDate = DateTime(date.year, date.month, date.day);

    if (inputDate == today) {
      return 'Hoje';
    }

    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));
    if (inputDate.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
        inputDate.isBefore(endOfWeek.add(const Duration(days: 1)))) {
      return 'Esta semana';
    }

    final lastMonth = DateTime(now.year, now.month - 1, now.day);
    if (inputDate.isAfter(lastMonth)) {
      return 'Último mês';
    }

    if (inputDate.year == now.year) {
      return 'Este ano';
    }

    return DateFormat('dd/MM/yyyy').format(date);
  }

  void scrollToIndex(int index) {
    if (index < 0 || index >= mutableSongs.length) {
      return;
    }

    if (!(widget.withReorder ?? false)) {
      if (_itemScrollController.isAttached) {
        _itemScrollController.scrollTo(
          index: index,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
          alignment: 0.2,
        );
      }
      return;
    }
    if (!_scrollController.hasClients) return;

    // Each song row has a fixed height; grouped lists add a 30px header at
    // each boundary. Account for those headers instead of assuming every
    // item occupies exactly 65px.
    final double position = _offsetForIndex(index);
    final maxExtent = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      position.clamp(0.0, maxExtent).toDouble(),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  void scrollToCurrentSong() {
    final index = mscAudPl.currentIndex.value;
    if (index < 0 ||
        index >= mscAudPl.actlist.getLengthMusicListAtual() ||
        !listaEmUso) {
      return;
    }
    final currentSong = mscAudPl.actlist.getMusicAtual(index);
    final visibleIndex = mutableSongs.indexWhere(
      (song) => song.id == currentSong.id,
    );
    if (visibleIndex != -1) scrollToIndex(visibleIndex);
  }

  double _offsetForIndex(int index) {
    double offset = index * 65.0;
    if (!(widget.showSlices ?? true) ||
        mode == ModeOrderEnum.manual ||
        mode == ModeOrderEnum.up) {
      return offset;
    }

    for (var i = 0; i <= index; i++) {
      if (i == 0 ||
          _sliceFor(mutableSongs[i]) != _sliceFor(mutableSongs[i - 1])) {
        offset += 30.0;
      }
    }
    return offset;
  }

  String _sliceFor(MediaItem item) {
    if (mode == ModeOrderEnum.dataZA || mode == ModeOrderEnum.dataAZ) {
      return getDateCategory(DateTime.parse(item.extras?['lastModified']));
    }
    if (mode == ModeOrderEnum.titleZA || mode == ModeOrderEnum.titleAZ) {
      return item.title.isEmpty ? '' : item.title[0].toUpperCase();
    }
    return '';
  }

  Widget _artworkFor(MediaItem item) {
    final artUri = item.artUri;
    if (artUri != null && artUri.scheme == 'file') {
      return Image.file(
        File(artUri.toFilePath()),
        width: 55,
        height: 45,
        fit: BoxFit.cover,
      );
    }
    if (artUri != null &&
        (artUri.scheme == 'http' || artUri.scheme == 'https')) {
      return Image.network(
        artUri.toString(),
        width: 55,
        height: 45,
        fit: BoxFit.cover,
      );
    }
    return const SizedBox(width: 55, height: 45, child: Icon(Icons.music_note));
  }

  void toggleSelecao(
    ValueNotifier<List<bool>> musicasSelecionadas,
    int index,
  ) async {
    final novaLista = List<bool>.from(musicasSelecionadas.value);
    novaLista[index] = !novaLista[index];
    musicasSelecionadas.value = novaLista;

    if (novaLista[index]) {
      idsSelecoes.add(index);
    } else {
      idsSelecoes.remove(index);
    }

    if (await widget.onSelectMsc?.call(idsSelecoes) ?? false) {
      idsSelecoes = [];
      musicasSelecionadas.value = List.filled(mutableSongs.length, false);
      widget.onSelectMsc?.call(idsSelecoes);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool selecionando = false;

    void onReorder(int oldIndex, int newIndex) async {
      setState(() {
        if (mode != ModeOrderEnum.manual) {
          mode = ModeOrderEnum.manual;
        }
        if (newIndex > oldIndex) newIndex -= 1;
        final item = mutableSongs.removeAt(oldIndex);
        mutableSongs.insert(newIndex, item);
      });

      int id = int.tryParse(widget.idPlaylist.toString()) ?? 0;

      await DatabaseHelper.instance.updatePlaylist(
        id,
        orderMode: enumToInt(mode),
      );

      await DatabaseHelper.instance.updateOrderMusics(mutableSongs, id);

      mscAudPl.reorganizeQueue(songs: mutableSongs);
    }

    return ValueListenableBuilder<int>(
      valueListenable: mscAudPl.currentIndex,
      builder: (context, value, child) {
        if (listaEmUso && value != _lastScrolledIndex) {
          _lastScrolledIndex = value;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final canScroll =
                (widget.withReorder ?? false)
                    ? _scrollController.hasClients
                    : _itemScrollController.isAttached;
            if (mounted && canScroll && listaEmUso) {
              scrollToIndex(value);
            }
          });
        }

        return ValueListenableBuilder<List<bool>>(
          valueListenable: musicasSelecionadas,
          builder: (context, selecionada, child) {
            Widget itemBuilder(BuildContext context, int index) {
              MediaItem item = mutableSongs[index];
              final currentMusic = mscAudPl.actlist.getMusicAtual(value);

                final bool isSelecionada =
                    index < selecionada.length && selecionada[index];

                final bool isTocando =
                    value != -1 &&
                    value < mscAudPl.actlist.getLengthMusicListAtual() &&
                    listaEmUso &&
                    mutableSongs[index].id == currentMusic.id;

                Color? corFundo =
                    isSelecionada
                        ? const Color.fromARGB(95, 243, 34, 34)
                        : isTocando
                        ? const Color.fromARGB(96, 243, 159, 34)
                        : null;

                bool showSliceHeader =
                    (mode != ModeOrderEnum.manual &&
                        mode != ModeOrderEnum.up) &&
                    (widget.showSlices ?? true);

                List<Widget> children = [];

                if (showSliceHeader) {
                  String currentSlice = '';
                  String previousSlice = '';

                  if (mode == ModeOrderEnum.dataZA ||
                      mode == ModeOrderEnum.dataAZ) {
                    final lastModified = DateTime.parse(
                      item.extras?['lastModified'],
                    );
                    currentSlice = getDateCategory(lastModified);
                    previousSlice =
                        index > 0
                            ? getDateCategory(
                              DateTime.parse(
                                mutableSongs[index - 1].extras?['lastModified'],
                              ),
                            )
                            : '';
                  } else if (mode == ModeOrderEnum.titleZA ||
                      mode == ModeOrderEnum.titleAZ) {
                    currentSlice = item.title[0].toUpperCase();
                    previousSlice =
                        index > 0
                            ? mutableSongs[index - 1].title[0].toUpperCase()
                            : '';
                  } else {
                    currentSlice = '';
                    previousSlice = '';
                  }

                  showSliceHeader = index == 0 || currentSlice != previousSlice;

                  if (showSliceHeader) {
                    children.add(
                      Container(
                        height: 30,
                        width: double.infinity,
                        color: baseFundoDark,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          currentSlice,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 243, 145, 34),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }
                }

                children.add(
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          color: corFundo,
                          height: 65,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () async {
                              if (selecionando) {
                                toggleSelecao(musicasSelecionadas, index);
                                if (!musicasSelecionadas.value.contains(true)) {
                                  selecionando = false;
                                }
                              } else {
                                try {
                                  if (!listaEmUso) {
                                    setState(() {
                                      listaEmUso = true;
                                    });
                                  }
                                  widget.onClick?.call(mutableSongs[index]);
                                } catch (e) {
                                  log('Erro ao tocar música: $e');
                                }
                              }
                            },
                            onLongPress: () {
                              toggleSelecao(musicasSelecionadas, index);
                              if (selecionando &&
                                  !musicasSelecionadas.value.contains(true)) {
                                selecionando = false;
                              } else {
                                selecionando = true;
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: _artworkFor(item),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.artist ?? "Artista desconhecido",
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 30,
                                    height: 65,
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.more_horiz_outlined,
                                        color:
                                            Theme.of(context)
                                                .extension<CustomColors>()!
                                                .textForce,
                                      ),
                                      onPressed: () async {
                                        final tag =
                                            mscAudPl
                                                .actlist
                                                .viewingPlaylist
                                                .tag;
                                        final isUp = await DatabaseHelper
                                            .instance
                                            .isLastUped(
                                              idMsc:
                                                  mscAudPl.actlist
                                                      .getMusicAtual(index)
                                                      .id,
                                              idPlaylist: tag,
                                            );
                                        final isCheck = mscAudPl.checkpoint
                                            .isCheckpoint(
                                              currentMusic: index,
                                              currentSetList: tag,
                                            );

                                        final isDesup = await DatabaseHelper
                                            .instance
                                            .isLastDesuped(
                                              idMsc:
                                                  mscAudPl.actlist
                                                      .getMusicAtual(index)
                                                      .id,
                                              idPlaylist: tag,
                                            );

                                        showPopupOptions(
                                          context,
                                          item.title,
                                          moreOptions(context, item),
                                          actionState: ActionState(
                                            isUp: isUp,
                                            isCheck: isCheck,
                                            isDesup: isDesup,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      widget.withReorder ?? false
                          ? ReorderableDragStartListener(
                            index: index,
                            child: Container(
                              color: corFundo,
                              width: 25,
                              height: 65,
                              child: Icon(
                                Icons.unfold_more_sharp,
                                color:
                                    Theme.of(
                                      context,
                                    ).extension<CustomColors>()!.textForce,
                              ),
                            ),
                          )
                          : SizedBox.shrink(),
                    ],
                  ),
                );

              return Column(
                key: ValueKey(item.id),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              );
            }

            if (widget.withReorder ?? false) {
              return ReorderableListView.builder(
                onReorder: onReorder,
                scrollController: _scrollController,
                cacheExtent: 650,
                itemCount: mutableSongs.length,
                itemBuilder: itemBuilder,
              );
            }

            return ScrollablePositionedList.builder(
              itemScrollController: _itemScrollController,
              itemCount: mutableSongs.length,
              itemBuilder: itemBuilder,
              minCacheExtent: 650,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
            );
          },
        );
      },
    );
  }
}
