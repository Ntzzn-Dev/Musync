import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musync_and/services/audio_player_base.dart';
import 'package:musync_and/services/databasehelper.dart';
import 'package:musync_and/services/playlists.dart';
import 'package:musync_and/themes.dart';
import 'package:musync_and/widgets/list_content.dart';
import 'package:musync_and/widgets/player.dart';

class PlaylistPage extends StatefulWidget {
  final String plTitle;
  final MusyncAudioHandler audioHandler;
  final List<MediaItem> songsPL;
  final Playlists? pl;
  const PlaylistPage({
    super.key,
    required this.plTitle,
    required this.audioHandler,
    required this.songsPL,
    this.pl,
  });

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  ValueNotifier<double> bottomPosition = ValueNotifier(0);
  final TextEditingController _searchController = TextEditingController();
  late List<MediaItem> songsPlaylist;
  late List<MediaItem> songsNowTranslated;

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
    bottomPosition.value = bottomPosition.value == 0 ? -100 : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.plTitle,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              modeAtual = modeAtual.next();
              setState(() {
                songsPlaylist = MusyncAudioHandler.reorder(
                  modeAtual,
                  songsNowTranslated,
                );
              });
              if (widget.pl != null) {
                DatabaseHelper().updatePlaylist(
                  widget.pl!.id,
                  orderMode: modeAtual.disconvert(),
                );
                log(modeAtual.disconvert().toString());
              }
            },
            child: Icon(Icons.reorder_outlined),
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
                          _searchController.text = '';
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
                  idPlaylist: widget.pl!.id,
                  withReorder: true,
                  aposClique: (item) async {
                    await widget.audioHandler.recreateQueue(
                      songs: songsNowTranslated,
                    );
                    widget.audioHandler.savePl(
                      (widget.pl?.id ?? widget.plTitle).toString(),
                    );
                    int indiceCerto = songsNowTranslated.indexWhere(
                      (t) => t == item,
                    );
                    await widget.audioHandler.skipToQueueItem(indiceCerto);
                  },
                ),
              ),
              Padding(padding: EdgeInsets.fromLTRB(0, 0, 0, 70)),
            ],
          ),

          ValueListenableBuilder(
            valueListenable: bottomPosition,
            builder: (context, value, child) {
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                bottom: value,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _toggleBottom,
                  child: Player(audioHandler: widget.audioHandler),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
