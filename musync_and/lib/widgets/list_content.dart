import 'dart:developer';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:musync_and/services/audio_player_base.dart';
import 'package:musync_and/services/databasehelper.dart';
import 'package:musync_and/services/playlists.dart';
import 'package:musync_and/widgets/player.dart';
import 'package:musync_and/widgets/popup.dart';
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
        },
      },
      {
        'opt': 'Adicionar a Playlist',
        'funct': () async {
          DatabaseHelper().addToPlaylist(
            1,
            await Playlists.generateHashs(item.extras?['path']),
          );

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
          'valor1': 'Duracao',
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
        //await file.delete(); ---------------------------------------------------------------------------------------------------> DEIXAR PARA RETIRAR QUANDO CONFIGURAÇÕES ESTIVER PRONTO
        log('Arquivo deletado: ${item.title}');
      } catch (e) {
        log('Erro ao deletar: $e');
      }
    } else {
      log('Arquivo não encontrado');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder<List<MediaItem>>(
        stream: Stream.value(widget.songsNow),
        builder: (context, snapshot) {
          final mediaItems = snapshot.data ?? [];

          void _scrollToCenter(int index) {
            if (index >= 0 && index < mediaItems.length) {
              _itemScrollController.scrollTo(
                index: index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: 0.25,
              );
            }
          }

          return ValueListenableBuilder<int?>(
            valueListenable: widget.audioHandler.currentIndexNotifier,
            builder: (context, currentIndex, _) {
              if (currentIndex != null &&
                  currentIndex >= 0 &&
                  currentIndex < mediaItems.length) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToCenter(currentIndex);
                });
              }
              return ScrollablePositionedList.builder(
                itemCount: mediaItems.length,
                itemScrollController: _itemScrollController,
                itemPositionsListener: _itemPositionsListener,
                itemBuilder: (context, index) {
                  final item = mediaItems[index];
                  return ListTile(
                    contentPadding: EdgeInsets.only(left: 16, right: 8),
                    title: Text(item.title),
                    subtitle: Text(item.artist ?? "Artista desconhecido"),
                    trailing: SizedBox(
                      width: 52,
                      height: 52,
                      child: IconButton(
                        icon: const Icon(Icons.more_vert_rounded),
                        iconSize: 24,
                        padding: EdgeInsets.zero,
                        onPressed:
                            () => showPopup(
                              context,
                              item.title,
                              moreOptions(context, item),
                            ),
                      ),
                    ),
                    tileColor:
                        currentIndex == index
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
              );
            },
          );
        },
      ),
    );
    ;
  }
}
