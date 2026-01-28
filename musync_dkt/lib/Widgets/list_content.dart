import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'package:musync_dkt/Services/audio_player.dart';
import 'package:musync_dkt/Services/media_music.dart';
import 'package:musync_dkt/themes.dart';

class ListContent extends StatefulWidget {
  final MusyncAudioHandler audioHandler;
  final List<MediaMusic> songsNow;
  final ModeOrderEnum modeReorder;
  final int? idPlaylist;
  final bool? withReorder;
  final void Function(MediaMusic)? aposClique;
  final void Function(List<int>)? selecaoDeMusicas;

  const ListContent({
    super.key,
    required this.audioHandler,
    required this.songsNow,
    required this.modeReorder,
    this.idPlaylist,
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

  late List<MediaMusic> mutableSongs;
  late ModeOrderEnum mode;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    listaEmUso = const ListEquality().equals(
      widget.songsNow,
      widget.audioHandler.songsAtual.value,
    );
    idsSelecoes = [];
    mutableSongs = List.from(widget.songsNow);
    mode = widget.modeReorder;

    widget.audioHandler.currentIndex.addListener(_onCurrentIndexChanged);
  }

  @override
  void didUpdateWidget(covariant ListContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.songsNow != widget.songsNow) {
      mutableSongs = List.from(widget.songsNow);
      mode = widget.modeReorder;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void scrollToIndex(int index) {
    final double position = index * 78;
    _scrollController.animateTo(
      position,
      duration: Duration(seconds: 1),
      curve: Curves.easeInOut,
    );
  }

  void toggleSelecao(ValueNotifier<List<bool>> musicasSelecionadas, int index) {
    final novaLista = List<bool>.from(musicasSelecionadas.value);
    novaLista[index] = !novaLista[index];
    musicasSelecionadas.value = novaLista;

    if (novaLista[index]) {
      idsSelecoes.add(index);
    } else {
      idsSelecoes.remove(index);
    }

    widget.selecaoDeMusicas?.call(idsSelecoes);
  }

  void _onCurrentIndexChanged() {
    if (listaEmUso && _scrollController.hasClients) {
      log(widget.audioHandler.currentIndex.value.toString());
      scrollToIndex(widget.audioHandler.currentIndex.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    mutableSongs = widget.songsNow;
    final musicasSelecionadas = ValueNotifier(
      List.filled(mutableSongs.length, false),
    );
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

      widget.audioHandler.reorganizeQueue(songs: mutableSongs);
    }

    List<Widget> imgs =
        mutableSongs.map((item) {
          final artBase64 = item.artUri;

          if (artBase64.isNotEmpty) {
            try {
              final artBytes = artBase64;
              return Image.memory(
                artBytes,
                width: 45,
                height: 45,
                fit: BoxFit.cover,
              );
            } catch (e) {
              print('Erro ao decodificar base64: $e');
            }
          }

          return SizedBox(width: 45, height: 45, child: Icon(Icons.music_note));
        }).toList();

    return ValueListenableBuilder<int>(
      valueListenable: widget.audioHandler.currentIndex,
      builder: (context, value, child) {
        return ValueListenableBuilder<List<bool>>(
          valueListenable: musicasSelecionadas,
          builder: (context, selecionada, child) {
            return ReorderableListView.builder(
              onReorder: onReorder,
              scrollController: _scrollController,
              itemCount: mutableSongs.length,
              itemBuilder: (context, index) {
                MediaMusic item = mutableSongs[index];
                final corFundo =
                    selecionada[index]
                        ? Color.fromARGB(95, 243, 34, 34)
                        : value != -1 &&
                            mutableSongs[index] ==
                                widget.audioHandler.songsAtual.value[value] &&
                            listaEmUso
                        ? Color.fromARGB(96, 243, 159, 34)
                        : null;

                String currentSlice = '';
                String previousSlice = '';

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
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          color: corFundo,
                          height: 78,
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.max,
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
                                          maxLines: 2,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.artist,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 3,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 15),
                                  if (widget.withReorder ?? false)
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: Container(
                                        color: corFundo,
                                        width: 44,
                                        height: 78,
                                        child: Icon(
                                          Icons.drag_handle,
                                          color:
                                              Theme.of(context)
                                                  .extension<CustomColors>()!
                                                  .textForce,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
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
