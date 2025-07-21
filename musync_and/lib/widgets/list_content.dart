import 'dart:developer';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:crypto/crypto.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:musync_and/pages/download_page.dart';
import 'package:musync_and/services/audio_player_base.dart';
import 'package:musync_and/services/databasehelper.dart';
import 'package:musync_and/services/playlists.dart';
import 'package:musync_and/themes.dart';
import 'package:musync_and/widgets/player.dart';
import 'package:musync_and/widgets/popup.dart';
import 'package:musync_and/widgets/popup_add.dart';
import 'package:musync_and/widgets/popup_list.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ListContent extends StatefulWidget {
  final MyAudioHandler audioHandler;
  final List<MediaItem> songsNow;

  const ListContent({
    super.key,
    required this.audioHandler,
    required this.songsNow,
  });

  @override
  State<ListContent> createState() => _ListContentState();
}

class _ListContentState extends State<ListContent> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  bool isScrollable = true;

  List<Map<String, dynamic>> moreOptions(BuildContext context, MediaItem item) {
    return [
      {
        'opt': 'Apagar Audio',
        'funct': () {
          deletarMusica(item);
          Navigator.of(context).pop();
        },
      },
      {
        'opt': 'Informações',
        'funct': () {
          showSpec(item);
          //log(item.extras?['hash']);
        },
      },
      {
        'opt': 'Editar Música',
        'funct': () {
          showPopupAdd(
            context,
            item.title,
            [
              {'value': 'Título', 'type': 'text'},
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

              int index = MyAudioHandler.songsAll.indexWhere(
                (e) => e.id == item.id,
              );

              if (index != -1) {
                final antigo = MyAudioHandler.songsAll[index];

                final musicEditada = antigo.copyWith(
                  title: valores[0],
                  artist: valores[1],
                  album: valores[2],
                  genre: valores[3],
                  extras: {
                    ...?antigo.extras,
                    'lastModified': antigo.extras?['lastModified'],
                    'path': antigo.extras?['path'],
                    'hash': antigo.extras?['hash'],
                  },
                );

                MyAudioHandler.songsAll[index] = musicEditada;

                setState(() {});
              } else {
                log('Item não encontrado na lista para edição.');
              }
            },
          );
        },
      },
      {
        'opt': 'Adicionar a Playlist',
        'funct': () async {
          DatabaseHelper().addToPlaylist(1, item.extras?['hash']);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adicionado a playlist: ')),
          );
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
        {'valor1': 'Album', 'valor2': item.album},
        {'valor1': 'Artista', 'valor2': item.artist},
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
          widget.songsNow.remove(item);
        });
        await widget.audioHandler.recreateQueue(songs: widget.songsNow);
        await file.delete();
        //---------------------------------------------------------------------------------------------------> DEIXAR PARA RETIRAR QUANDO CONFIGURAÇÕES ESTIVER PRONTO
      } catch (e) {
        log('Erro ao deletar: $e');
      }
    } else {
      log('Arquivo não encontrado');
    }
  }

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions.addListener(() {
      final positions = _itemPositionsListener.itemPositions.value;
      if (positions.isNotEmpty) {
        final lastVisible = positions
            .where((pos) => pos.itemTrailingEdge <= 1.0)
            .map((pos) => pos.index)
            .reduce((a, b) => a > b ? a : b);

        if (lastVisible == widget.songsNow.length - 1) {
          isScrollable = true;
        } else {
          isScrollable = false;
        }
      }
    });
  }

  int? _lastScrolledIndex;

  void _scrollToCenter(int index) {
    if (_lastScrolledIndex == index || isScrollable) return;
    _lastScrolledIndex = index;

    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.25,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaItems = widget.songsNow;

    return Expanded(
      child: ValueListenableBuilder<int?>(
        valueListenable: widget.audioHandler.currentIndexNotifier,
        builder: (context, currentIndex, _) {
          if (currentIndex != null &&
              currentIndex >= 0 &&
              currentIndex < mediaItems.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToCenter(currentIndex);
            });
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox.expand(
                  child: ScrollablePositionedList.builder(
                    itemCount: mediaItems.length,
                    itemScrollController: _itemScrollController,
                    itemPositionsListener: _itemPositionsListener,
                    itemBuilder: (context, index) {
                      final item = mediaItems[index];
                      final isSelected = currentIndex == index;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            color:
                                Theme.of(
                                  context,
                                ).extension<CustomColors>()!.textForce,
                          ),
                        ),
                        subtitle: Text(
                          item.artist ?? "Artista desconhecido",
                          style: TextStyle(
                            color:
                                Theme.of(
                                  context,
                                ).extension<CustomColors>()!.subtextForce,
                          ),
                        ),
                        trailing: SizedBox(
                          width: 52,
                          height: 52,
                          child: IconButton(
                            icon: Icon(
                              Icons.more_vert_rounded,
                              color:
                                  Theme.of(
                                    context,
                                  ).extension<CustomColors>()!.textForce,
                            ),
                            iconSize: 24,
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              showPopup(
                                context,
                                item.title,
                                moreOptions(context, item),
                              );
                            },
                          ),
                        ),
                        tileColor:
                            isSelected
                                ? const Color.fromARGB(51, 243, 160, 34)
                                : null,
                        onTap: () async {
                          try {
                            await widget.audioHandler.recreateQueue(
                              songs: widget.songsNow,
                            );
                            await widget.audioHandler.skipToQueueItem(index);
                          } catch (e) {
                            log('Erro ao tocar música: $e');
                          }
                        },
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
