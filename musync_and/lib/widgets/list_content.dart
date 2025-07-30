import 'dart:convert';
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
import 'package:musync_and/widgets/popup.dart';
import 'package:musync_and/widgets/popup_add.dart';
import 'package:musync_and/widgets/popup_list.dart';
import 'package:collection/collection.dart';

class ListContent extends StatefulWidget {
  final MyAudioHandler audioHandler;
  final List<MediaItem> songsNow;
  final ModeOrderEnum modeReorder;
  final void Function(MediaItem)? aposClique;

  const ListContent({
    super.key,
    required this.audioHandler,
    required this.songsNow,
    required this.modeReorder,
    this.aposClique,
  });

  @override
  State<ListContent> createState() => _ListContentState();
}

class _ListContentState extends State<ListContent> {
  late final ScrollController _scrollController;
  late bool listaEmUso;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    listaEmUso = const ListEquality().equals(
      widget.songsNow,
      widget.audioHandler.songsAtual,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
        'funct': () async {
          showSpec(item);
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

              int indexSongAll = MyAudioHandler.songsAll.indexWhere(
                (e) => e.id == item.id,
              );

              int indexSongNow = widget.songsNow.indexWhere(
                (e) => e.id == item.id,
              );

              if (indexSongAll != -1) {
                final antigo = MyAudioHandler.songsAll[indexSongAll];

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

                MyAudioHandler.songsAll[indexSongAll] = musicEditada;
                widget.songsNow[indexSongNow] = musicEditada;

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
        'opt': 'Adicionar a Playlist',
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
                                  await DatabaseHelper().removeFromPlaylist(
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
                                    haveMusic: !(playlist.haveMusic ?? false),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
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
          widget.songsNow.remove(item);
          MyAudioHandler.songsAll.remove(item);
        });
        await widget.audioHandler.recreateQueue(songs: widget.songsNow);
        await file.delete();
      } catch (e) {
        log('Erro ao deletar: $e');
      }
    } else {
      log('Arquivo não encontrado');
    }
  }

  Uint8List? base64ToBytes(String dataUri) {
    final regex = RegExp(r'data:.*;base64,(.*)');
    final match = regex.firstMatch(dataUri);
    if (match == null) return null;
    final base64Str = match.group(1);
    if (base64Str == null) return null;
    return base64Decode(base64Str);
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
    final double position = index * 78;
    _scrollController.animateTo(
      position,
      duration: Duration(seconds: 1),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaItems = widget.songsNow;
    List<Widget> imgs =
        widget.songsNow.map((item) {
          final artUriStr = item.artUri?.toString();

          if (artUriStr != null && artUriStr.startsWith('data:')) {
            final bytes = base64ToBytes(artUriStr);
            if (bytes != null) {
              return Image.memory(
                bytes,
                width: 45,
                height: 45,
                fit: BoxFit.cover,
              );
            }
          } else if (artUriStr != null &&
              (artUriStr.startsWith('http') || artUriStr.startsWith('https'))) {
            return Image.network(
              artUriStr,
              width: 45,
              height: 45,
              fit: BoxFit.cover,
            );
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

        return ListView.builder(
          controller: _scrollController,
          itemCount: mediaItems.length,
          itemBuilder: (context, index) {
            MediaItem item = mediaItems[index];

            String currentSlice = '';
            String previousSlice = '';

            if (widget.modeReorder == ModeOrderEnum.dataZA ||
                widget.modeReorder == ModeOrderEnum.dataAZ) {
              final lastModified = DateTime.parse(item.extras?['lastModified']);
              currentSlice = getDateCategory(lastModified);
              previousSlice =
                  index > 0
                      ? getDateCategory(
                        DateTime.parse(
                          mediaItems[index - 1].extras?['lastModified'],
                        ),
                      )
                      : '';
            } else {
              currentSlice = item.title[0].toUpperCase();
              previousSlice =
                  index > 0 ? mediaItems[index - 1].title[0].toUpperCase() : '';
            }

            final showSliceHeader = index == 0 || currentSlice != previousSlice;

            List<Widget> children = [];

            if (showSliceHeader) {
              children.add(
                Container(
                  height: 30,
                  width: double.infinity,
                  color: const Color.fromARGB(255, 54, 54, 54),
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
              Container(
                color:
                    mediaItems[index] ==
                                widget.audioHandler.songsAtual[value] &&
                            listaEmUso
                        ? Color.fromARGB(96, 243, 159, 34)
                        : null,
                height: 78,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    try {
                      if (!listaEmUso) {
                        setState(() {
                          listaEmUso = true;
                        });
                      }
                      widget.aposClique?.call(mediaItems[index]);
                    } catch (e) {
                      log('Erro ao tocar música: $e');
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.title,
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
                                item.artist ?? "Artista desconhecido",
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
                        SizedBox(
                          width: 44,
                          height: 44,
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
                      ],
                    ),
                  ),
                ),
              ),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            );
          },
        );
      },
    );
  }
}
