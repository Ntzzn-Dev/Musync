import 'dart:developer';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:musync_and/services/audio_player_base.dart';
import 'package:musync_and/services/databasehelper.dart';
import 'package:musync_and/services/playlists.dart';
import 'package:musync_and/themes.dart';
import 'package:musync_and/widgets/player.dart';
import 'package:musync_and/widgets/popup_option.dart';
import 'package:musync_and/widgets/popup_add.dart';
import 'package:musync_and/widgets/popup_list.dart';
import 'package:collection/collection.dart';
import 'package:share_plus/share_plus.dart';

class ListContent extends StatefulWidget {
  final MusyncAudioHandler audioHandler;
  final List<MediaItem> songsNow;
  final ModeOrderEnum modeReorder;
  final String idPlaylist;
  final bool? withReorder;
  final void Function(MediaItem)? aposClique;
  final Future<bool> Function(List<int>)? selecaoDeMusicas;

  const ListContent({
    super.key,
    required this.audioHandler,
    required this.songsNow,
    required this.modeReorder,
    required this.idPlaylist,
    this.withReorder,
    this.aposClique,
    this.selecaoDeMusicas,
  });

  @override
  State<ListContent> createState() => _ListContentState();
}

class _ListContentState extends State<ListContent> {
  late final ScrollController _scrollController;
  late bool listaEmUso;
  late List<int> idsSelecoes;
  late ValueNotifier<List<bool>> musicasSelecionadas;

  late List<MediaItem> mutableSongs;
  late ModeOrderEnum mode;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    listaEmUso = const ListEquality().equals(
      widget.songsNow,
      widget.audioHandler.songsAtual,
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

  List<Map<String, dynamic>> moreOptions(BuildContext context, MediaItem item) {
    return [
      {
        'opt': 'Up',
        'icon': Icons.favorite,
        'funct': () async {
          await DatabaseHelper().upInPlaylist(
            widget.audioHandler.atualPlaylist.value.tag,
            item.id,
            item.title,
          );

          MusyncAudioHandler
              .songsAllPlaylist = await MusyncAudioHandler.reorder(
            ModeOrderEnum.up,
            MusyncAudioHandler.songsAllPlaylist,
          );
          setState(() {
            mutableSongs = MusyncAudioHandler.songsAllPlaylist;
          });
        },
      },
      {
        'opt': 'Adicionar a Playlist',
        'icon': Icons.playlist_add,
        'funct': () async {
          List<Playlists> playlists = await DatabaseHelper().loadPlaylists(
            idMusic: item.id,
          );

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
                      padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                showPopupAdd(
                                  context,
                                  'Adicionar Playlist',
                                  [
                                    {'value': 'Título', 'type': 'title'},
                                    {'value': 'Subtitulo', 'type': 'text'},
                                  ],
                                  onConfirm: (valores) async {
                                    DatabaseHelper().insertPlaylist(
                                      valores[0],
                                      valores[1],
                                      1,
                                    );

                                    playlists =
                                        await DatabaseHelper().loadPlaylists();
                                  },
                                );
                              },
                              child: const Text("Adicionar playlist"),
                            ),
                          ),
                          Expanded(
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
                                      if (playlist.haveMusic ?? false) {
                                        await DatabaseHelper()
                                            .removeFromPlaylist(
                                              playlist.id,
                                              item.id,
                                            );
                                      } else {
                                        await DatabaseHelper().addToPlaylist(
                                          playlist.id,
                                          item.id,
                                        );
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
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      },
      {
        'opt': 'Compartilhar',
        'icon': Icons.share,
        'funct': () async {
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
      },
      {
        'opt': 'Editar Música',
        'icon': Icons.edit,
        'funct': () {
          showPopupAdd(
            context,
            item.title,
            [
              {'value': 'Título', 'type': 'title', 'id': 2},
              {'value': 'Artista', 'type': 'text'},
              {'value': 'Album', 'type': 'text'},
              {'value': 'Gênero', 'type': 'text'},
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

              int indexSongAll = MusyncAudioHandler.songsAll.indexWhere(
                (e) => e.id == item.id,
              );

              int indexSongNow = mutableSongs.indexWhere(
                (e) => e.id == item.id,
              );

              if (indexSongAll != -1) {
                final antigo = MusyncAudioHandler.songsAll[indexSongAll];

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

                MusyncAudioHandler.songsAll[indexSongAll] = musicEditada;
                mutableSongs[indexSongNow] = musicEditada;

                setState(() {});

                Navigator.of(context).pop();
              } else {
                log('Item não encontrado na lista para edição.');
              }
            },
          );
        },
      },
      {
        'opt': 'Apagar Audio',
        'icon': Icons.delete_forever,
        'funct': () async {
          if (await showPopupAdd(context, "Deletar Mídia?", [])) {
            deletarMusica(item);
            Navigator.of(context).pop();
          }
        },
      },
      {
        'opt': 'Informações',
        'icon': Icons.info_outline,
        'funct': () async {
          showSpec(item);
        },
      },
    ];
  }

  void showSpec(MediaItem item) {
    showPopupList(
      context,
      item.title,
      [
        {'valor1': 'Nome', 'valor2': item.title},
        {'valor1': 'Artista', 'valor2': item.artist},
        {'valor1': 'Album', 'valor2': item.album},
        {
          'valor1': 'Duração',
          'valor2': Player.formatDuration(item.duration!, true),
        },
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
          mutableSongs.remove(item);
          MusyncAudioHandler.songsAll.remove(item);
        });
        await widget.audioHandler.recreateQueue(songs: mutableSongs);
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
    final double position = index * 65;
    _scrollController.animateTo(
      position,
      duration: Duration(seconds: 1),
      curve: Curves.easeInOut,
    );
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

    if (await widget.selecaoDeMusicas?.call(idsSelecoes) ?? false) {
      idsSelecoes = [];
      musicasSelecionadas.value = List.filled(mutableSongs.length, false);
      widget.selecaoDeMusicas?.call(idsSelecoes);
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

      await DatabaseHelper().updatePlaylist(id, orderMode: mode.disconvert());

      await DatabaseHelper().updateOrderMusics(mutableSongs, id);

      widget.audioHandler.reorganizeQueue(songs: mutableSongs);
    }

    List<Widget> imgs =
        mutableSongs.map((item) {
          final artUri = item.artUri;

          if (artUri != null) {
            if (artUri.scheme == 'file') {
              return Image.file(
                File(artUri.toFilePath()),
                width: 45,
                height: 45,
                fit: BoxFit.cover,
              );
            } else if (artUri.scheme == 'http' || artUri.scheme == 'https') {
              return Image.network(
                artUri.toString(),
                width: 45,
                height: 45,
                fit: BoxFit.cover,
              );
            }
          }

          return SizedBox(width: 45, height: 45, child: Icon(Icons.music_note));
        }).toList();

    return ValueListenableBuilder<int>(
      valueListenable: widget.audioHandler.currentIndex,
      builder: (context, value, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients && listaEmUso) {
            scrollToIndex(value);
          }
        });

        return ValueListenableBuilder<List<bool>>(
          valueListenable: musicasSelecionadas,
          builder: (context, selecionada, child) {
            return ReorderableListView.builder(
              onReorder: onReorder,
              scrollController: _scrollController,
              itemCount: mutableSongs.length,
              itemBuilder: (context, index) {
                MediaItem item = mutableSongs[index];
                final corFundo =
                    index < selecionada.length && selecionada[index]
                        ? Color.fromARGB(95, 243, 34, 34)
                        : value != -1 &&
                            value < widget.audioHandler.songsAtual.length &&
                            mutableSongs[index] ==
                                widget.audioHandler.songsAtual[value] &&
                            listaEmUso
                        ? Color.fromARGB(96, 243, 159, 34)
                        : null;

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

                bool showSliceHeader =
                    index == 0 || currentSlice != previousSlice;

                if (mode == ModeOrderEnum.manual) {
                  showSliceHeader = false;
                }

                List<Widget> children = [];

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
                          color: Color.fromARGB(255, 243, 160, 34),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
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
                                  widget.aposClique?.call(mutableSongs[index]);
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
                                    child: imgs[index],
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
                                      onPressed: () {
                                        showPopupOptions(
                                          context,
                                          item.title,
                                          moreOptions(context, item),
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
              },
            );
          },
        );
      },
    );
  }
}
